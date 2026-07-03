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
  description = "Domain name (for naming)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to attach to the target group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB instance"
  type        = string
}