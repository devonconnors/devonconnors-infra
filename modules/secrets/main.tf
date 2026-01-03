# Consolidated "prod" secret with nested DB_CREDENTIALS and SES_CREDENTIALS as JSON objects
resource "aws_secretsmanager_secret" "prod" {
  name                    = "prod"
  description             = "Consolidated credentials (DB and SES) for ${var.project_name}"
  recovery_window_in_days = 30  # Prevent accidental deletion

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
}