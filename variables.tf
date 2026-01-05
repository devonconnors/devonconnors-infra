variable "project_name" {
  description = "Name of the project/shop (used for tagging and resource naming)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "domain_name" {
  description = "Primary custom domain for the site (e.g., mydjangoapp.co.uk)"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Your public IP allowed for SSH access (e.g., 86.132.45.67/32). Change this!"
  type        = string
}

variable "app_instance_type" {
  description = "EC2 instance type for Django app (t4g.medium recommended)"
  type        = string
}

variable "nat_instance_type" {
  description = "Instance type for fck-nat (t4g.nano is cheapest and sufficient)"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository (defaults to project_name if empty)"
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability: 'MUTABLE' or 'IMMUTABLE' (immutable recommended)"
  type        = string
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be 'MUTABLE' or 'IMMUTABLE'."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable vulnerability scanning on ECR push"
  type        = bool
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpn_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
}

variable "backup_retention_period" {
  description = "Number of days to retain automated RDS backups"
  type        = number
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ for RDS (recommended for production)"
  type        = bool
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "rds_publicly_accessible" {
  description = "Allow public access to connect to RDS (for staging)"
  type        = bool
  default     = false
}

# Terraform Cloud variables
variable "AWS_DEFAULT_REGION" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
  sensitive = true
}