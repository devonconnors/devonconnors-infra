variable "db_endpoint" {
  description = "RDS endpoint (host)"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password (from RDS module)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "ses_username" {
  description = "SES SMTP username"
  type        = string
  sensitive   = true
}

variable "ses_password" {
  description = "SES SMTP password"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}