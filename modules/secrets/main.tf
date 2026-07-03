resource "aws_secretsmanager_secret" "prod" {
  name                    = "django-prod-terraform"
  description             = "Consolidated secrets for ${var.project_name}"
  recovery_window_in_days = 30
  tags = {
    Name = "${var.project_name}-prod-secret" 
  }
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
      smtp_username = var.ses_username
      smtp_password = null
    })
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}