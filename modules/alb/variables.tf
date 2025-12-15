variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "app_instance_id" {
  description = "EC2 instance ID of the Django app to forward traffic to"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "project_name" {
  description = "Name of the project/shop for naming resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name (for naming and tags)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (optional - leave empty to disable)"
  type        = string
  default     = ""
}