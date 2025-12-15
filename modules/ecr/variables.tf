variable "repository_name" {
  description = "Name of the ECR repository (e.g., project_name or custom)"
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE (recommended for production)"
  type        = string
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning on push"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}