#!/bin/bash
set -euo pipefail

# Redirect output to log for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "User data started: $$(date)"

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
aws ecr get-login-password --region "$${AWS_REGION}" | docker login --username AWS --password-stdin "$${ecr_repo_url}"

# Calculate Redis repo URL (assuming same registry prefix as Django repo, adjust pattern if needed)
redis_repo_url="$${ecr_repo_url/django/latest/redis/7-alpine}"  # Replace 'django/latest' with 'redis/7-alpine' based on repo structure

# Pull images
echo "Pulling images..."
docker pull "$${ecr_repo_url}:latest"
docker pull "$${redis_repo_url}"

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
cat <<EOF > /home/ec2-user/docker-compose.yml
version: '3.8'
services:
  redis:
    image: $${redis_ecr_url}:7-alpine  # From your ECR (rebuild if needed)
    ports:
      - 6379:6379
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 50

  django:
    image: $${ecr_repo_url}:latest
    ports:
      - 80:8000
    environment:
      - DEBUG=0
      - APP_NAME=$${var.project_name}
      - ALLOWED_HOSTS=$${var.domain_name}
      - CACHE_LOCATION=redis://redis:6379/1
      - CELERY_BROKER=redis://redis:6379/0
      - CELERY_BACKEND=redis://redis:6379/0
      - AWS_REGION=eu-west-2
      - AWS_PUBLIC_STORAGE_BUCKET_NAME=devonconnors-public-storage  # Existing
      - AWS_PRIVATE_STORAGE_BUCKET_NAME=devonconnors-private-storage  # Existing
      - AWS_CLOUDFRONT_DOMAIN=$${cloudfront_domain}  # From Terraform
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "server_healthcheck.sh"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: always

  celery:
    image: $${ecr_repo_url}:latest
    command: celery -A $${var.project_name} worker -B -l INFO -P solo
    environment:
      - CACHE_LOCATION=redis://redis:6379/1
      - CELERY_BROKER=redis://redis:6379/0
      - CELERY_BACKEND=redis://redis:6379/0
      - APP_NAME=$${var.project_name}
      - AWS_REGION=eu-west-2
    depends_on:
      - redis
      - django
    healthcheck:
      test: ["CMD", "celery", "-A", "$${var.project_name}", "inspect", "ping"]
      interval: 10s
      timeout: 10s
      retries: 5
    restart: always
EOF

# Start agent
echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "User data finished: $(date)"