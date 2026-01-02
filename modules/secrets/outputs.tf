output "db_username" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  sensitive = true
}

output "db_password" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  sensitive = true
}

output "db_host" {
  value = var.db_endpoint
}

output "db_name" {
  value = var.db_name
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
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