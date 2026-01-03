output "db_username" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  sensitive = true
}

output "db_password" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  sensitive = true
}

output "db_host" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["host"]
}

output "db_name" {
  value = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["dbname"]
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "ses_username" {
  value = jsondecode(aws_secretsmanager_secret_version.ses_credentials.secret_string)["username"]
  sensitive = true
}

output "ses_password" {
  value = jsondecode(aws_secretsmanager_secret_version.ses_credentials.secret_string)["password"]
  sensitive = true
}

output "ses_secret_arn" {
  value = aws_secretsmanager_secret.ses_credentials.arn
}