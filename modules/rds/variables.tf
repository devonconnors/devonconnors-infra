variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID allowing access from the app EC2"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class (db.t4g.medium recommended)"
  type        = string
}

variable "allocated_storage" {
  description = "Storage in GB (start small, auto-scaling later)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Project name for naming/tagging"
  type        = string
}

variable "pause_infra" {
  description = "If true, minimizes infrastructure costs by preparing relevant modules for being indefinitely paused"
  type        = bool
}

variable "restore_from_snapshot" {
  description = "If true, RDS instance is restored from the specified snapshot"
  type        = bool
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "publicly_accessible" {
  description = "Allow public access to connect to RDS (for staging)"
  type        = bool
  default     = false
}