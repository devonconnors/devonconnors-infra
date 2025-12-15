# Certificate for ALB - in the same region as everything else (eu-west-2 by default)
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = var.alternative_names
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = "alb-cert"
    Use  = "ALB HTTPS"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for ALB cert (only if hosted_zone_id provided)
resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Wait for ALB cert validation
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_validation : record.fqdn]
}

# Certificate for CloudFront - MUST be in us-east-1
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1  # Uses the alias provider from root

  domain_name               = var.domain_name
  subject_alternative_names = var.alternative_names
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name = "cloudfront-cert"
    Use  = "CloudFront"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for CloudFront cert (same zone, reusable)
resource "aws_route53_record" "cloudfront_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Wait for CloudFront cert validation
resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}