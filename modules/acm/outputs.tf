output "alb_certificate_arn" {
  value = aws_acm_certificate.alb.arn
}

output "cloudfront_certificate_arn" {
  value = aws_acm_certificate.cloudfront.arn
}

output "certificate_status" {
  value = {
    alb        = aws_acm_certificate.alb.status
    cloudfront = aws_acm_certificate.cloudfront.status
  }
}

output "alb_validation_options" {
  description = "DNS validation records for ALB certificate - add as CNAME to registrar DNS if not using Route 53"
  value = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }
}

output "cloudfront_validation_options" {
  description = "DNS validation records for CloudFront certificate - add as CNAME to registrar DNS if not using Route 53"
  value = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }
}