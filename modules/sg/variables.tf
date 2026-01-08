variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access to app and nat instances (e.g., your IP/32). Use 0.0.0.0/0 only temporarily!"
  type        = string
}

variable "app_port" {
  description = "Port your EC2 container listens on"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}

variable "rds_publicly_accessible" {
  description = "Allow public access to connect to RDS (for staging)"
  type        = bool
  default     = false
}