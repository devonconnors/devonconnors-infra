#!/bin/bash
set -euo pipefail

# Redirect output to log for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "User data started: $(date)"

# Update packages
yum update -y

# Install Docker (unchanged)
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  amazon-linux-extras install docker -y || yum install -y docker
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user
fi

# Install Docker Compose (unchanged)
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "Installing Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Log in to ECR (unchanged)
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REPO_URL}"

# Pull images (unchanged)
echo "Pulling images..."
docker pull "${ECR_REPO_URL}:latest"
docker pull "redis:7-alpine"

# Fetch SSH private key from Secrets Manager (JSON secret with django_private_key key)
echo "Fetching SSH private key from Secrets Manager..."
mkdir -p /home/ec2-user/.ssh

# Get the full secret JSON, then extract just the private key value
PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id "django-deploy-key" --query SecretString --output text | jq -r '.django_private_key')

echo "$PRIVATE_KEY" > /home/ec2-user/.ssh/id_ed25519
chmod 600 /home/ec2-user/.ssh/id_ed25519
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519

# Configure git to use SSH (no passphrase prompt)
echo "Configuring git SSH..."
cat <<EOF > /home/ec2-user/.ssh/config
Host *
  IdentityFile /home/ec2-user/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
chmod 600 /home/ec2-user/.ssh/config
chown ec2-user:ec2-user /home/ec2-user/.ssh/config

# Clone private repo via SSH
echo "Cloning private Django repo..."
su - ec2-user -c "git clone git@github.com:yourusername/your-django-repo.git /app"  # <-- CHANGE TO YOUR ACTUAL REPO URL

# If clone fails, log error
if [ $? -ne 0 ]; then
  echo "Git clone failed! Check SSH key, repo permissions, and Secrets Manager value."
  exit 1
fi

# Configure git to use SSH (no passphrase prompt)
echo "Configuring git SSH..."
cat <<EOF > /home/ec2-user/.ssh/config
Host *
  IdentityFile /home/ec2-user/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
chmod 600 /home/ec2-user/.ssh/config
chown ec2-user:ec2-user /home/ec2-user/.ssh/config

# Clone private repo via SSH (change URL to match your host)
echo "Cloning private Django repo..."
su - ec2-user -c "git clone git@github.com:yourusername/your-django-repo.git /app"  # <-- CHANGE THIS LINE
# For Bitbucket: git@bitbucket.org:youruser/your-repo.git
# For GitLab: git@gitlab.com:yourgroup/your-repo.git

# If repo clone fails, log error
if [ $? -ne 0 ]; then
  echo "Git clone failed! Check SSH key and repo permissions."
  exit 1
fi

# Create docker-compose.yml (unchanged)
echo "Creating docker-compose.yml..."
cat <<EOF > /home/ec2-user/docker-compose.yml
# ... (your existing compose content here, unchanged)
EOF

# Stop/remove old containers (unchanged)
echo "Stopping old containers..."
docker compose -f /home/ec2-user/docker-compose.yml down || true

# Run with Docker Compose (unchanged)
echo "Starting containers with Docker Compose..."
docker compose -f /home/ec2-user/docker-compose.yml up -d

# Health check (unchanged)
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

echo "User data finished: $$(date)"