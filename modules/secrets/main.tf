resource "aws_secretsmanager_secret" "prod" {
  name                    = "django-prod-terraform"
  description             = "Consolidated secrets for ${var.project_name}"
  recovery_window_in_days = 30
  tags = merge(var.tags, {
    Name = "${var.project_name}-prod-secret" 
  })
}

resource "aws_secretsmanager_secret_version" "prod" {
  secret_id = aws_secretsmanager_secret.prod.id
  secret_string = jsonencode({
    DB_CREDENTIALS = jsonencode({
      host     = var.db_endpoint
      dbname   = var.db_name
      username = var.db_username
      password = var.db_password
      port     = 5432
    })
    SES_CREDENTIALS = jsonencode({
      username = var.ses_username
      password = var.ses_password
    })
  })

  keepers = {
    force_update = "2026-01-06-v1"  # Change this value (e.g., increment date/v) to force new secret version
  }

  lifecycle {
    ignore_changes = [secret_string]
  }
}