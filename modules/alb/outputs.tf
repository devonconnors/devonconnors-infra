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

output "security_group_id" {
  description = "Security group ID of the ALB (if needed elsewhere)"
  value       = aws_security_group.alb.id
}