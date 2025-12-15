output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security group ID for the Django app EC2"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.db.id
}

output "nat_sg_id" {
  description = "Security group ID for fck-nat instance"
  value       = aws_security_group.nat.id
}