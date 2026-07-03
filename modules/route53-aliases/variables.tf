variable "zone_id" {
  description = "ID of the Route 53 hosted zone (from route53_zone module)"
  type        = string
}

variable "domain_name" {
  description = "The domain name (e.g. nevard.dev)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (e.g. dualstack....elb.amazonaws.com)"
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID for the ALB"
  type        = string
}

variable "cloudfront_domain" {
  description = "Cloudfront domain for static serving"
  type        = string
}