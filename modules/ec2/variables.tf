variable "project_name" {
  type = string
}

variable "pause_infra" {
  description = "If true, minimizes infrastructure costs by preparing relevant modules for being indefinitely paused"
  type        = bool
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
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

variable "aws_private_storage_bucket_name" {
  description = "Name of the private S3 bucket for media originals"
  type        = string
}

variable "aws_public_storage_bucket_name" {
  description = "Name of the public S3 bucket for static/processed media"
  type        = string
}

variable "aws_cloudfront_domain" {
  description = "CloudFront domain (e.g., static.{domain})"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "allowed_cidr_nets" {
  description = "Comma-separated CIDR nets for IP restrictions in Django (e.g., '0.0.0.0/0' for all; leave empty for no restrictions)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Optional default if not set
}