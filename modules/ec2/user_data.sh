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

# Log in to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "${ecr_repo_url}"

# Pull image
echo "Pulling image ${ecr_repo_url}:latest"
docker pull "${ecr_repo_url}:latest"

# Stop/remove old container
docker stop django-app || true
docker rm django-app || true

# Run Django container with RDS DATABASE_URL
echo "Starting Django container..."
docker run -d \
  --name django-app \
  -p 8000:8000 \
  --restart unless-stopped \
  -e DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}" \
  -e SECRET_KEY="${SECRET_KEY}" \
  -e AWS_STORAGE_BUCKET_NAME="${AWS_STORAGE_BUCKET_NAME}" \
  -e AWS_S3_CUSTOM_DOMAIN="${AWS_S3_CUSTOM_DOMAIN}" \
  "${ecr_repo_url}:latest"

# Health check
sleep 10
if docker ps --filter name=django-app | grep -q running; then
  echo "Container running OK"
else
  echo "Container failed!"
  docker logs django-app
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