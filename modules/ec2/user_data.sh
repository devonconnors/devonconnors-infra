#!/bin/bash
set -euo pipefail

# Redirect all output to log for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "User data started: $(date)"

# Cleanup any old broken state
docker compose down --remove-orphans || true
docker image prune -f || true

# Install Docker if missing
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  sudo yum update -y
  sudo yum install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker ec2-user
fi

# Install Docker Compose v2 (as plugin)
if ! docker compose version >/dev/null 2>&1; then
  echo "Installing Docker Compose v2..."
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -SL "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose v2 installation failed!"
    exit 1
  fi
  echo "Docker Compose v2 installed: $(docker compose version)"
fi

# Create app directory
sudo mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Create .env file (quoted heredoc — variables stay literal)
echo "Creating .env..."
cat <<'EOF' > .env
DEBUG=0
STAGING=0
ALLOWED_HOSTS=${ALLOWED_HOSTS}
ALLOWED_CIDR_NETS=${ALLOWED_CIDR_NETS}
CSRF_TRUSTED_ORIGINS=${CSRF_TRUSTED_ORIGINS}
APP_NAME=${APP_NAME}
CACHE_LOCATION=${CACHE_LOCATION}
CELERY_BROKER=${CELERY_BROKER}
CELERY_BACKEND=${CELERY_BACKEND}
AWS_REGION=eu-west-2
AWS_PUBLIC_STORAGE_BUCKET_NAME=${AWS_PUBLIC_STORAGE_BUCKET_NAME}
AWS_PRIVATE_STORAGE_BUCKET_NAME=${AWS_PRIVATE_STORAGE_BUCKET_NAME}
AWS_CLOUDFRONT_DOMAIN=${AWS_CLOUDFRONT_DOMAIN}
ECR_REPO_URL=${ECR_REPO_URL}
EOF

# Create docker-compose.yml (quoted heredoc)
echo "Creating docker-compose.yml..."
cat <<'EOF' > docker-compose.yml
version: '3.8'

x-django-common:
  &django-common
  image: ${ECR_REPO_URL}:latest
  env_file:
    - .env
  depends_on:
    redis:
      condition: service_healthy
  restart: always

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

  celery:
    <<: *django-common
    command: celery -A ${APP_NAME} worker -B -l INFO -P solo
    healthcheck:
      test: ["CMD", "celery", "-A", "${APP_NAME}", "inspect", "ping"]
      interval: 10s
      timeout: 10s
      retries: 5
      start_period: 30s

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

# Verify files
if [ ! -f .env ] || [ ! -f docker-compose.yml ]; then
  echo "ERROR: Config files not created!"
  exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REPO_URL}"

# Pull and start containers
echo "Pulling images and starting containers..."
docker compose pull
docker compose up -d

echo "Bootstrap complete: $(date)"