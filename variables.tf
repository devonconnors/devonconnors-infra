variable "project_name" {
  description = "Name of the project/shop (used for tagging and resource naming)"
  type        = string
  default     = "django-shop"
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"  # London - perfect for UK
}

variable "domain_name" {
  description = "Primary custom domain for the site (e.g., mydjangoapp.co.uk)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Existing Route 53 Hosted Zone ID for the domain. Leave empty to create a new zone."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair for SSH access to app and fck-nat instances (optional but recommended for debugging)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "Your public IP allowed for SSH access (e.g., 86.132.45.67/32). Change this!"
  type        = string
  default     = "0.0.0.0/0"  # WARNING: Restrict this in your .tfvars file!
}

variable "app_instance_type" {
  description = "EC2 instance type for Django app (t4g.medium recommended)"
  type        = string
  default     = "t4g.medium"
}

variable "nat_instance_type" {
  description = "Instance type for fck-nat (t4g.nano is cheapest and sufficient)"
  type        = string
  default     = "t4g.nano"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository (defaults to project_name if empty)"
  type        = string
  default     = ""
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
  default     = true
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "djangodb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "djangoadmin"
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ for RDS (recommended for production)"
  type        = bool
  default     = true
}

variable "cloudfront_enabled" {
  description = "Enable CloudFront + S3 for static/media files"
  type        = bool
  default     = true
}

variable "acm_alternative_names" {
  description = "Additional names for the SSL certificate. We set this to include www automatically."
  type        = list(string)
  default     = []  # We will override this in the module call below
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "Django E-Commerce"
  }
}