variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
}

variable "map_public_ip_on_launch" {
  description = "Whether to auto-assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = false  # Default to false for security, override in root
}