resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = {
    Name = "${replace(var.domain_name, ".", "-")}-zone"
  }
}