output "vpn_endpoint_id" {
  description = "ID of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "vpn_endpoint_dns" {
  description = "DNS name of the VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "vpn_client_connection_command" {
  description = "Command to connect via AWS VPN Client"
  value       = "aws ec2-client-vpn connect --endpoint-id ${aws_ec2_client_vpn_endpoint.this.id} --region eu-west-2"
}