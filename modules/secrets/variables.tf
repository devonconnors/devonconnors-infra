variable "db_endpoint" {
  description = "RDS endpoint (host:port)"
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

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}

variable "django_secret_key" {
  description = "Django SECRET_KEY (if empty, one will be generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}