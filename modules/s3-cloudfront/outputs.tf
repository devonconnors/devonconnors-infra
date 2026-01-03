output "private_bucket_name" {
  description = "Name of the private S3 bucket for user-uploaded originals"
  value       = aws_s3_bucket.private.bucket
}

output "public_bucket_name" {
  description = "Name of the public S3 bucket for static/processed media"
  value       = aws_s3_bucket.public.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (for public bucket)"
  value       = aws_cloudfront_distribution.public.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for public bucket)"
  value       = aws_cloudfront_distribution.public.id
}