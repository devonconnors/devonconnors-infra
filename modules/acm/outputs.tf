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