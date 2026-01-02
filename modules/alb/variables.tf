variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
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

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to attach to the target group"
  type        = string
}