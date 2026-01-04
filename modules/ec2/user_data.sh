#!/bin/bash
set -euo pipefail

# Redirect output to log for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "User data started: $(date)"

# Install dependencies early (git for clone, jq if ever needed again)
echo "Installing dependencies..."
sudo yum update -y
sudo yum install -y git

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  sudo amazon-linux-extras install docker -y || sudo yum install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker ec2-user
fi

# Install Docker Compose v2 (ARM64)
if ! docker compose version >/dev/null 2>&1; then
  echo "Installing Docker Compose v2 (ARM64)..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Log in to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REPO_URL}"

# Pull images
echo "Pulling images..."
docker pull "${ECR_REPO_URL}:latest"
docker pull "redis:7-alpine"

# Fetch SSH private key from Secrets Manager (plaintext)
echo "Fetching SSH private key from Secrets Manager..."
mkdir -p /home/ec2-user/.ssh
aws secretsmanager get-secret-value --secret-id "django-deploy-key" --region "${AWS_REGION}" --query SecretString --output text > /home/ec2-user/.ssh/id_ed25519
chmod 600 /home/ec2-user/.ssh/id_ed25519
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519

# Configure git SSH
echo "Configuring git SSH..."
cat <<EOF > /home/ec2-user/.ssh/config
Host *
  IdentityFile /home/ec2-user/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
chmod 600 /home/ec2-user/.ssh/config
chown ec2-user:ec2-user /home/ec2-user/.ssh/config

# Clone private repo
echo "Cloning private Django repo..."
su - ec2-user -c "git clone git@github.com:devonconnors/devonconnors-app.git /app"

if [ $? -ne 0 ]; then
  echo "Git clone failed!"
  exit 1
fi

# Create .env file
echo "Creating .env file..."
cat <<EOF > /home/ec2-user/.env
DEBUG=0
STAGING=0
ALLOWED_CIDR_NETS=${ALLOWED_CIDR_NETS}
CSRF_TRUSTED_ORIGINS=${CSRF_TRUSTED_ORIGINS}
APP_NAME=${APP_NAME}
CACHE_LOCATION=${CACHE_LOCATION}
CELERY_BROKER=${CELERY_BROKER}
CELERY_BACKEND=${CELERY_BACKEND}
AWS_REGION=${AWS_REGION}
AWS_PUBLIC_STORAGE_BUCKET_NAME=${AWS_PUBLIC_STORAGE_BUCKET_NAME}
AWS_PRIVATE_STORAGE_BUCKET_NAME=${AWS_PRIVATE_STORAGE_BUCKET_NAME}
AWS_CLOUDFRONT_DOMAIN=${AWS_CLOUDFRONT_DOMAIN}
EOF

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat <<EOF > /home/ec2-user/docker-compose.yml
x-django-common:
  &django-common
  image: ${ECR_REPO_URL}:latest
  env_file:
    - .env
  depends_on:
    redis:
      condition: service_healthy
services:
  django:
    <<: *django-common
    ports:
      - 80:8000
    healthcheck:
      test: ["CMD", "server_healthcheck.sh"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 30s
    restart: always
  celery:
    <<: *django-common
    command: celery -A $${APP_NAME} worker -B -l INFO -P solo
    healthcheck:
      test: ["CMD", "celery", "-A", "$${APP_NAME}", "inspect", "ping"]
      interval: 10s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always
  redis:
    image: redis:7-alpine
    ports:
      - 6379:6379
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 50
      start_period: 10s
    restart: always
EOF

# Stop/remove old containers
echo "Stopping old containers..."
docker compose -f /home/ec2-user/docker-compose.yml down || true

# Run with Docker Compose
echo "Starting containers with Docker Compose..."
docker compose -f /home/ec2-user/docker-compose.yml up -d

# Health check
sleep 10
if docker compose -f /home/ec2-user/docker-compose.yml ps | grep -q Up; then
  echo "Containers running OK"
else
  echo "Containers failed!"
  docker compose -f /home/ec2-user/docker-compose.yml logs
  exit 1
fi

# CloudWatch Agent
if ! command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl >/dev/null 2>&1; then
  echo "Installing CloudWatch Agent..."
  yum install -y amazon-cloudwatch-agent
fi

cat <<EOC > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
    },
    "metrics_collected": {
      "cpu": {"measurement": ["cpu_usage_active"], "metrics_collection_interval": 60},
      "mem": {"measurement": ["mem_used_percent"], "metrics_collection_interval": 60},
      "disk": {"measurement": ["disk_used_percent"], "resources": ["/"], "metrics_collection_interval": 60}
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {"file_path": "/var/log/messages", "log_group_name": "ec2-messages", "log_stream_name": "{instance_id}"},
          {"file_path": "/var/log/user-data.log", "log_group_name": "ec2-user-data", "log_stream_name": "{instance_id}"}
        ]
      }
    }
  }
}
EOC

echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "User data finished: $(date)"