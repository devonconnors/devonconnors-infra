locals {
  use_route53 = var.hosted_zone_id != null
}

# Certificate for ALB (eu-west-2 default region)
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = concat(var.alternative_names, ["static.${var.domain_name}"])
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = "alb-cert-${var.domain_name}"
    Use  = "ALB HTTPS"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ALB cert (only if using Route 53)
resource "aws_route53_record" "alb_validation" {
  count   = local.use_route53 ? length(aws_acm_certificate.alb.domain_validation_options) : 0
  zone_id = var.hosted_zone_id

  name    = tolist(aws_acm_certificate.alb.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.alb.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.alb.domain_validation_options)[count.index].resource_record_value]
  ttl     = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = local.use_route53 ? [for record in aws_route53_record.alb_validation : record.fqdn] : []

  timeouts {
    create = "2h"  # Longer timeout to avoid hang error
  }
}

# Certificate for CloudFront (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = concat(var.alternative_names, ["static.${var.domain_name}"])
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = "cloudfront-cert-${var.domain_name}"
    Use  = "CloudFront"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for CloudFront cert (only if using Route 53)
resource "aws_route53_record" "cloudfront_validation" {
  count   = local.use_route53 ? length(aws_acm_certificate.cloudfront.domain_validation_options) : 0
  zone_id = var.hosted_zone_id

  name    = tolist(aws_acm_certificate.cloudfront.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.cloudfront.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.cloudfront.domain_validation_options)[count.index].resource_record_value]
  ttl     = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = local.use_route53 ? [for record in aws_route53_record.cloudfront_validation : record.fqdn] : []

  timeouts {
    create = "2h"  # Longer timeout to avoid hang error
  }
}