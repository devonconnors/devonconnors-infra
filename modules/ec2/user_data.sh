#!/bin/bash
set -euo pipefail

# Redirect output to log for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "User data started: $(date)"

# Update packages
yum update -y

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  amazon-linux-extras install docker -y || yum install -y docker
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user
fi

# Install Docker Compose
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Installing Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Log in to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ecr_repo_url}"

# Calculate Redis repo URL (assuming same registry prefix as Django repo, adjust pattern if needed)
redis_repo_url="${ecr_repo_url/django\/latest/redis\/7-alpine}"  # Replace 'django/latest' with 'redis/7-alpine' based on repo structure

# Pull images
echo "Pulling images..."
docker pull "${ecr_repo_url}:latest"
docker pull "${redis_repo_url}"

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat <<EOF > /home/ec2-user/docker-compose.yml
# Basic Django cluster configuration with Celery & Redis.
#
# WARNING: This configuration is for production deployment. It is severely recommended to NOT use the PostgreSQL service in production!
---
x-django-common:
  &django-common
  image: $${ecr_repo_url}:latest
  environment:
    DEBUG: 0
    APP_NAME: "$${PROJECT_NAME}"
    ALLOWED_HOSTS: "$${ALLOWED_HOSTS}"
    ALLOWED_CIDR_NETS: "$${ALLOWED_CIDR_NETS}"
    CACHE_LOCATION: redis://redis:6379/1
    CELERY_BROKER: redis://redis:6379/0
    CELERY_BACKEND: redis://redis:6379/0
    AWS_REGION: "$${AWS_REGION}"
    AWS_PUBLIC_STORAGE_BUCKET_NAME: "$${AWS_PUBLIC_STORAGE_BUCKET_NAME}"
    AWS_PRIVATE_STORAGE_BUCKET_NAME: "$${AWS_PRIVATE_STORAGE_BUCKET_NAME}"
    AWS_CLOUDFRONT_DOMAIN: "$${AWS_CLOUDFRONT_DOMAIN}"
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
    command: celery -A "$${PROJECT_NAME}" worker -B -l INFO -P solo
    healthcheck:
      test: ["CMD", "celery", "-A", "$${PROJECT_NAME}", "inspect", "ping"]
      interval: 10s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always
  redis:
    image: $${redis_repo_url}
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

# Inline CloudWatch config
cat <<'EOC' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
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

# Start agent
echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "User data finished: $(date)"