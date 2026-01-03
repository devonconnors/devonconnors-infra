resource "aws_secretsmanager_secret" "prod" {}

resource "aws_secretsmanager_secret_version" "prod" {
  secret_id = aws_secretsmanager_secret.prod.id
}

resource "aws_s3_bucket" "private_storage" {}

resource "aws_s3_bucket" "public_storage" {}

resource "aws_vpc" "main" {}