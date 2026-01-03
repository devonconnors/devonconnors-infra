variable "domain_name" {
  description = "Primary domain name (e.g., mydjangoapp.co.uk or www.mydjangoapp.co.uk)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Optional Route 53 hosted zone ID for automatic DNS validation records (leave null for manual addition at registrar like GoDaddy)"
  type        = string
  default     = null
}

variable "alternative_names" {
  description = "Additional SANs (e.g., ['www.mydjangoapp.co.uk'] if primary is apex; 'static.mydjangoapp.co.uk' is added automatically for CloudFront)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to certificates"
  type        = map(string)
  default     = {}
}