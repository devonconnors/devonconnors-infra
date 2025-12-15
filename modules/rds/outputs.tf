output "endpoint" {
  description = "RDS endpoint (host:port) for Django DATABASE_URL"
  value       = aws_db_instance.this.endpoint
}

output "arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "password" {
  description = "Generated master password (use Secrets Manager in production!)"
  value       = random_password.master.result
  sensitive   = true
}