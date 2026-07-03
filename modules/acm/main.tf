# Certificate for ALB (eu-west-2 default region)
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = concat(var.alternative_names, ["static.${var.domain_name}"])
  validation_method         = "DNS"

  tags = {
    Name = "alb-cert-${var.domain_name}"
    Use  = "ALB HTTPS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = []

  timeouts {
    create = "2h"  # Longer timeout to allow manual validation
  }
}

# Certificate for CloudFront (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = concat(var.alternative_names, ["static.${var.domain_name}"])
  validation_method         = "DNS"

  tags = {
    Name = "cloudfront-cert-${var.domain_name}"
    Use  = "CloudFront"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = []

  timeouts {
    create = "2h"  # Longer timeout to allow manual validation
  }
}