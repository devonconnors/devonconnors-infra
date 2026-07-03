output "dns_name" {
  description = "DNS name of the ALB (for Route 53 alias)"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 zone ID of the ALB (for alias records)"
  value       = aws_lb.this.zone_id
}

output "arn" {
  description = "ARN of the ALB"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}