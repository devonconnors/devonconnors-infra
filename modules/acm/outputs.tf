output "alb_certificate_arn" {
  description = "ARN of the ACM certificate for the ALB (eu-west-2)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the ACM certificate for CloudFront (us-east-1)"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "certificate_status" {
  description = "Status of the certificates (should be ISSUED after validation)"
  value = {
    alb         = aws_acm_certificate.alb.status
    cloudfront  = aws_acm_certificate.cloudfront.status
  }
}