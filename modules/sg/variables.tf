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
  default     = "0.0.0.0/0"  # Strongly recommend overriding in tfvars with your IP
}

variable "app_port" {
  description = "Port your Django container listens on (Gunicorn)"
  type        = number
  default     = 8000
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}