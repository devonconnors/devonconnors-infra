# A record: apex -> CloudFront
resource "aws_route53_record" "apex" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [alias]
  }
}

# AAAA record: apex -> CloudFront
resource "aws_route53_record" "apex_ipv6" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [alias]
  }
}

# A record: www -> CloudFront
resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [alias]
  }
}

# AAAA record: www -> CloudFront
resource "aws_route53_record" "www_ipv6" {
  zone_id = var.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [alias]
  }
}