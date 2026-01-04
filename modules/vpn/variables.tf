variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "server_certificate_arn" {
  description = "ARN of the ACM certificate for VPN server"
  type        = string
}

variable "client_cidr_block" {
  description = "CIDR block for VPN clients (must not overlap with VPC CIDR)"
  type        = string
  default     = "172.16.0.0/22"
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to associate VPN with"
  type        = list(string)
}