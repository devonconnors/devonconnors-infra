variable "zone_id" {
  description = "ID of the Route 53 hosted zone (from route53_zone module)"
  type        = string
}

variable "domain_name" {
  description = "The domain name (e.g. nevard.dev)"
  type        = string
}

variable "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}