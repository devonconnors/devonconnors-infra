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
  value       = var.cloudfront_enabled ? module.s3_cloudfront[0].cloudfront_domain_name : "CloudFront disabled"
}

output "cloudfront_static_url" {
  description = "Base URL for serving static/media files via CloudFront"
  value       = var.cloudfront_enabled ? "https://${module.s3_cloudfront[0].cloudfront_domain_name}" : "N/A - Use Django's local static serving"
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

output "ec2_public_ip" {
  description = "Public IP of the Django app EC2 instance (for SSH/debug)"
  value       = module.ec2.public_ip
}

output "nat_instance_id" {
  description = "Instance ID of the fck-nat instance"
  value       = module.nat.instance_id
}

output "nat_public_ip" {
  description = "Public IP of the fck-nat instance"
  value       = module.nat.public_ip
}

output "ecr_repository_url" {
  description = "Full URL of the ECR repository (for Docker push/pull)"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "EC2_INSTANCE_ID" {
  description = "EC2 Instance ID of the Django app (for GitHub Actions SSM deploy)"
  value       = module.ec2.instance_id
}

output "ci_cd_instructions" {
  description = "How to set up automated deployment from your Django repo"
  value = <<EOT
CI/CD Setup Instructions:

1. In GitHub (your Django repo) → Settings → Secrets and variables → Actions:
   - Add Variables (not secrets):
     ECR_REPO_NAME = ${module.ecr.repository_name}
     ECR_REGISTRY   = ${module.ecr.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com
     EC2_INSTANCE_ID = ${module.ec2.instance_id}
     AWS_REGION = ${var.aws_region}

   - Add Secrets:
     AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY (from IAM user with ECR + SSM permissions)

2. Add .github/workflows/deploy.yml to your Django repo (use the workflow I provided earlier).

3. Push to main → automatic deploy!

Use SSM Session Manager (no SSH needed) for secure remote commands.
EOT
}

output "next_steps" {
  description = "What to do after deployment"
  value = <<EOT
Deployment complete! Next steps:

1. DNS: Point your domain (${var.domain_name}) to the ALB via Route 53 (records created automatically if new zone).

2. SSH into app instance:
   ssh -i your-key.pem ec2-user@${module.ec2.public_ip}

3. Deploy your Docker image:
   - Build & push to ECR (or build on-instance)
   - Pull and run your container with supervisor (Gunicorn + Celery)

4. Django setup:
   - Retrieve DB credentials from Secrets Manager
   - Set ENVIRONMENT variables (SECRET_KEY, DATABASE_URL, etc.)
   - Run migrations: python manage.py migrate
   - Collect static: python manage.py collectstatic (to S3 if CloudFront enabled)

5. Test: Visit https://${var.domain_name}

Monitor via CloudWatch dashboards/alarms (create manually or extend later).
EOT
}