output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "django_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Django SECRET_KEY"
  value       = aws_secretsmanager_secret.django_secret_key.arn
}

output "django_secret_key" {
  description = "The actual Django SECRET_KEY (only if generated)"
  value       = var.django_secret_key != "" ? "Provided externally" : random_password.django_secret_key.result
  sensitive   = true
}