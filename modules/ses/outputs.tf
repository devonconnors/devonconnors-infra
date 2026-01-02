output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.main.arn
}

output "verification_token" {
  description = "SES domain verification token (TXT value)"
  value       = aws_ses_domain_identity.main.verification_token
}

output "dkim_tokens" {
  description = "DKIM CNAME record names and values"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "verification_record_name" {
  description = "Name of the TXT verification record"
  value       = "_amazonses.${var.domain_name}"
}

output "verification_record_value" {
  description = "Value of the TXT verification record"
  value       = aws_ses_domain_identity.main.verification_token
}