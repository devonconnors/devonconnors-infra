output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.app.latest_version
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions deploy role"
  value       = aws_iam_role.github_actions.arn
}