# Create new hosted zone if no existing ID provided
resource "aws_route53_zone" "this" {
  count = var.hosted_zone_id == "" ? 1 : 0

  name = var.domain_name

  tags = merge(var.tags, {
    Name = "${replace(var.domain_name, ".", "-")}-zone"
  })
}

# Use existing or newly created zone ID
locals {
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : aws_route53_zone.this[0].zone_id
}

# A record: apex domain -> ALB
resource "aws_route53_record" "apex_alb" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# AAAA record for IPv6 (ALB supports it)
resource "aws_route53_record" "apex_alb_ipv6" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Optional: www -> ALB (if no CloudFront) or www -> CloudFront
resource "aws_route53_record" "www" {
  count   = var.cloudfront_domain != "" ? 1 : 1  # Always create www record
  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain != "" ? var.cloudfront_domain : var.alb_dns_name
    zone_id                = var.cloudfront_domain != "" ? var.cloudfront_zone_id : var.alb_zone_id
    evaluate_target_health = true
  }
}

# Optional: IPv6 for www
resource "aws_route53_record" "www_ipv6" {
  count   = var.cloudfront_domain != "" ? 1 : 1
  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain != "" ? var.cloudfront_domain : var.alb_dns_name
    zone_id                = var.cloudfront_domain != "" ? var.cloudfront_zone_id : var.alb_zone_id
    evaluate_target_health = true
  }
}