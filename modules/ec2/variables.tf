variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "ami_id" {
  description = "AMI ID for launch template"
  type        = string
}

variable "instance_type" {
  type = string
}

variable "app_security_group_id" {
  description = "Security group ID for app instances"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for ASG"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo for OIDC (e.g. username/repo)"
  type        = string
  default     = "donovannevard/donovannevard-django"
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "django_secret_key" {
  type = string
}

variable "aws_storage_bucket_name" {
  type = string
}

variable "aws_s3_custom_domain" {
  type = string
}