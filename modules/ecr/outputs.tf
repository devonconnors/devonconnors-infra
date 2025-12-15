output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "Full URL of the repository (for Docker push/pull)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "AWS account ID of the registry"
  value       = aws_ecr_repository.this.registry_id
}

output "arn" {
  description = "ARN of the repository"
  value       = aws_ecr_repository.this.arn
}