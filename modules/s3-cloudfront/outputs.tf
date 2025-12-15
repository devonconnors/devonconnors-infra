output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.static.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.static.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.static.id
}