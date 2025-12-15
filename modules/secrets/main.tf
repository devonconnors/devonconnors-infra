# Generate strong Django SECRET_KEY if not provided
resource "random_password" "django_secret_key" {
  length           = 64
  special          = true
  override_special = "!@#$%^&*()-_=+"
  min_lower        = 10
  min_upper        = 10
  min_numeric      = 10
  min_special      = 5

  keepers = {
    # Regenerate only if explicitly changed
    version = "1"
  }
}

# Database credentials secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-db-credentials"
  description             = "PostgreSQL credentials for ${var.project_name}"
  recovery_window_in_days = 30  # Prevent accidental deletion

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = var.db_endpoint
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    port     = 5432
  })
}

# Django SECRET_KEY secret
resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "${var.project_name}-django-secret-key"
  description             = "Django SECRET_KEY for ${var.project_name}"
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-django-secret-key"
  })
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key != "" ? var.django_secret_key : random_password.django_secret_key.result
}