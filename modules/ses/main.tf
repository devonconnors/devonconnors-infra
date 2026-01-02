# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

# SES DKIM (generates 3 CNAME records)
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Route 53 TXT record for domain verification
resource "aws_route53_record" "ses_verification" {
  zone_id = var.hosted_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 300

  records = [aws_ses_domain_identity.main.verification_token]
}

# Route 53 CNAME records for DKIM (3 records)
resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}