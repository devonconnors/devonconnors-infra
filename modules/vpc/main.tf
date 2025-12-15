module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"  # Latest stable as of Dec 2025 - check registry for newer if desired

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]   # 10.0.1.0/24 etc.
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102), cidrsubnet(var.vpc_cidr, 8, 103)] # 10.0.101.0/24 etc.

  public_subnet_tags = {
    "SubnetType" = "Public"
  }

  private_subnet_tags = {
    "SubnetType" = "Private"
  }

  enable_nat_gateway     = false  # We're using fck-nat instead
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}