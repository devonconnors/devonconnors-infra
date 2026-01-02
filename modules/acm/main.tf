# Certificate for ALB (eu-west-2 default region)
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = var.alternative_names
  validation_method         = "DNS"  # Changed to DNS

  tags = merge(var.tags, {
    Name = "alb-cert-${var.domain_name}"
    Use  = "ALB HTTPS"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ALB cert
resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.value]
  ttl             = 60
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_validation : record.fqdn]

  timeouts {
    create = "2h"  # Longer timeout to avoid hang error
  }
}

# Certificate for CloudFront (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = var.alternative_names
  validation_method         = "DNS"  # Changed to DNS

  tags = merge(var.tags, {
    Name = "cloudfront-cert-${var.domain_name}"
    Use  = "CloudFront"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for CloudFront cert
resource "aws_route53_record" "cloudfront_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.value]
  ttl             = 60
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]

  timeouts {
    create = "2h"  # Longer timeout to avoid hang error
  }
}