# Temporary scaffolding for imports - delete this file after refactor

# VPC (import by ID)
resource "aws_vpc" "main" {}

# Security Groups (import by ID)
resource "aws_security_group" "rds_sg" {}
resource "aws_security_group" "default_sg" {}

# RDS (import by identifier)
resource "aws_db_instance" "django_db" {}

# S3 Buckets (import by name)
resource "aws_s3_bucket" "private_storage" {}
resource "aws_s3_bucket" "public_storage" {}

# Secrets Manager (import by ARN)
resource "aws_secretsmanager_secret" "prod" {}
# Optional version (skip if not updating content; add if needed)
resource "aws_secretsmanager_secret_version" "prod" {}