output "db_username" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["DB_CREDENTIALS"]["username"]
}

output "db_password" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["DB_CREDENTIALS"]["password"]
}

output "db_host" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["DB_CREDENTIALS"]["host"]
}

output "db_name" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["DB_CREDENTIALS"]["dbname"]
}

output "ses_username" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["SES_CREDENTIALS"]["username"]
}

output "ses_password" {
  value = jsondecode(aws_secretsmanager_secret_version.prod.secret_string)["SES_CREDENTIALS"]["password"]
}