variable "bucket_name" {
  description = "Unique name for the S3 bucket (will add random suffix)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for CloudFront (e.g., mydjangoapp.co.uk)"
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
  default     = {}
}