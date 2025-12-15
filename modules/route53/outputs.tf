output "hosted_zone_id" {
  description = "Route 53 hosted zone ID used/created"
  value       = local.zone_id
}

output "name_servers" {
  description = "Name servers for the zone (if newly created - update your registrar!)"
  value       = try(aws_route53_zone.this[0].name_servers, ["Zone exists externally"])
}

output "zone_name" {
  description = "Domain name of the zone"
  value       = var.domain_name
}