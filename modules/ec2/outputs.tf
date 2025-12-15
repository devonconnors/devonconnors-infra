output "instance_id" {
  description = "EC2 Instance ID (used for CI/CD SSM deploy and target group)"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP for SSH and initial access"
  value       = aws_instance.app.public_ip
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.app.private_ip
}

output "iam_role_name" {
  description = "IAM role attached to the instance"
  value       = aws_iam_role.app.name
}