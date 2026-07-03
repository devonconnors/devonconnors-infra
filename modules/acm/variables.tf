variable "domain_name" {
  description = "Primary domain name (e.g., mydjangoapp.co.uk or www.mydjangoapp.co.uk)"
  type        = string
}

variable "alternative_names" {
  description = "Additional SANs (e.g., ['www.mydjangoapp.co.uk'] if primary is apex; 'static.mydjangoapp.co.uk' is added automatically for CloudFront)"
  type        = list(string)
  default     = []
}