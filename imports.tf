resource "aws_db_instance" "django_db" {
  instance_class = "db.t4g.small"
}

resource "aws_secretsmanager_secret" "prod" {}

resource "aws_secretsmanager_secret_version" "prod" {
  secret_id = aws_secretsmanager_secret.prod.id
}

resource "aws_s3_bucket" "private_storage" {}

resource "aws_s3_bucket" "public_storage" {}

resource "aws_vpc" "main" {}

resource "aws_security_group" "rds_sg" {}

resource "aws_security_group" "default_sg" {}