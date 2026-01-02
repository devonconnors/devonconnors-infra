variable "domain_name" {
  description = "The domain name to verify with SES (e.g. example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for adding verification/DKIM records"
  type        = string
}

variable "tags" {
  description = "Tags to apply to SES resources"
  type        = map(string)
  default     = {}
}