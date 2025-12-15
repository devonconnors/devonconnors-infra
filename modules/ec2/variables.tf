variable "subnet_id" {
  description = "Public subnet ID to launch the app instance in"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID for the app instance (created in security_groups module)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (override if needed; default uses SSM lookup in main.tf)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for the Django app"
  type        = string
  default     = "t4g.medium"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair for SSH access (optional - leave empty to disable key access)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
}

variable "domain_name" {
  description = "Domain name (used in tags and user data if needed)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH (e.g., your home IP/32). Set to 0.0.0.0/0 only temporarily!"
  type        = string
  default     = "0.0.0.0/0"  # Change this in tfvars to your IP!
}