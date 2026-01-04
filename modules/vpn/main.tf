# Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "${var.project_name} Client VPN for local VPC access"
  server_certificate_arn = var.server_certificate_arn  # Your ACM cert ARN (from module.acm)
  client_cidr_block      = var.client_cidr_block       # e.g., "172.16.0.0/22" - must not overlap with VPC CIDR
  split_tunnel           = true                        # Only VPC traffic goes through VPN

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.server_certificate_arn  # Same cert for mutual auth
  }

  connection_log_options {
    enabled = false  # Optional CloudWatch logging
  }

  tags = var.tags
}

# Associate VPN endpoint to private subnets (for access to RDS/EC2)
resource "aws_ec2_client_vpn_network_association" "this" {
  count                  = length(var.private_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.private_subnet_ids[count.index]
}

# Authorize access to your VPC CIDR (full VPC access)
resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.vpc_cidr_block
  authorize_all_groups   = true
  description            = "Allow access to entire VPC"
}