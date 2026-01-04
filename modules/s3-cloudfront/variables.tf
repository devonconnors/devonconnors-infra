variable "domain_name" {
  description = "Custom domain for CloudFront (e.g., devonconnors.co.uk)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (us-east-1) for CloudFront"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name for naming/tagging"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}

variable "app_role_arn" {
  description = "ARN of the IAM role for the app (EC2 instance running Django/Celery) to grant S3 access"
  type        = string
}