output "website_url" {
  description = "The full URL to access your Django e-commerce site"
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name (use for testing before DNS propagation)"
  value       = module.alb.dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain for static/media files (if enabled)"
  value       = module.s3_cloudfront.cloudfront_domain_name
}

output "cloudfront_static_url" {
  description = "Base URL for serving static/media files via CloudFront"
  value       = "https://${module.s3_cloudfront.cloudfront_domain_name}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (for Django DATABASE_URL)"
  value       = module.rds.endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "Secrets Manager ARN containing DB credentials"
  value       = module.secrets.db_secret_arn
  sensitive   = true
}

output "django_secret_key_arn" {
  description = "Secrets Manager ARN for Django SECRET_KEY (create/retrieve manually if needed)"
  value       = module.secrets.django_secret_arn
  sensitive   = true
}

output "nat_instance_arn" {
  description = "ARN of the NAT instance"
  value = module.nat.instance_arn
}

output "nat_public_ip" {
  description = "Public IP of the NAT instance"
  value = module.nat.instance_public_ip
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2.asg_name
}

output "route53_hosted_zone_id" {
  description = "ID of the created Route 53 hosted zone"
  value       = module.route53_zone.zone_id
}

output "route53_name_servers" {
  description = "Name servers to copy to GoDaddy for delegation"
  value       = module.route53_zone.name_servers
}

output "launch_template_id" {
  value = module.ec2.launch_template_id
}

output "ci_cd_instructions" {
  description = "How to set up automated deployment from your Django repo"
  value = <<EOT
CI/CD Setup Instructions:

1. In GitHub (your Django repo) → Settings → Secrets and variables → Actions:
   - Add Variables (not secrets):
     AWS_REGION = ${var.aws_region}

   - Add Secrets:
     AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY (from IAM user with ECR + SSM permissions)

2. Add .github/workflows/deploy.yml to your Django repo (use the workflow I provided earlier).

3. Push to main → automatic deploy!

Use SSM Session Manager (no SSH needed) for secure remote commands.
EOT
}

output "next_steps" {
  value = <<EOT
To access the instance via SSM (no SSH key needed):
aws ssm start-session --target <instance-id>  # get instance-id from AWS console or ASG instances

# Or if you have public IP enabled (not recommended):
ssh -i your-key.pem ec2-user@<public-ip>
EOT
}