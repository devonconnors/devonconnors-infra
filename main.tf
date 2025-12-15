# Data sources for availability zones and AMI lookups
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amzn2_arm_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

# DynamoDB table for Terraform state locking (create if not exists)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name = "Terraform Lock Table"
  })
}

# === MODULE CALLS ===

# 1. VPC with public/private subnets
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  tags         = var.tags
}

# 2. Security groups
module "security_groups" {
  source = "./modules/sg"

  vpc_id           = module.vpc.vpc_id
  project_name     = var.project_name
  ssh_allowed_cidr = var.ssh_allowed_cidr
  tags             = var.tags

  depends_on = [module.vpc]
}

# 3. fck-nat Instance (official module)
module "nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "1.4.0"

  name             = "${var.project_name}-nat"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnets[0]
  instance_type    = var.nat_instance_type

  # Enable SSH access only if key_name provided (optional debug)
  use_ssh          = var.key_name != "" ? true : false
  ssh_key_name     = var.key_name != "" ? var.key_name : null
  ssh_cidr_blocks  = { ipv4 = [var.ssh_allowed_cidr] }

  # Automatically update private route tables
  update_route_tables = true
  route_tables_ids    = { for i, rt_id in module.vpc.private_route_table_ids : "private-rt-${i}" => rt_id }

  tags             = var.tags

  depends_on       = [module.vpc]
}

# 4. Django App EC2 instance
module "ec2" {
  source = "./modules/ec2"

  subnet_id              = module.vpc.public_subnets[0]
  app_security_group_id  = module.security_groups.app_sg_id
  ami_id                 = data.aws_ssm_parameter.amzn2_arm_ami.value  # ARM for t4g instances
  instance_type          = var.app_instance_type
  key_name               = var.key_name
  project_name           = var.project_name
  domain_name            = var.domain_name
  tags                   = var.tags

  depends_on = [module.nat, module.security_groups]
}

# 5. Application Load Balancer + HTTPS
module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnets
  app_instance_id   = module.ec2.instance_id
  certificate_arn   = module.acm.alb_certificate_arn
  project_name      = var.project_name
  domain_name       = var.domain_name
  tags              = var.tags

  depends_on = [module.ec2, module.acm, module.vpc]
}

# 6. ACM Certificate
module "acm" {
  source = "./modules/acm"

  domain_name       = var.domain_name
  alternative_names = ["www.${var.domain_name}"]
  hosted_zone_id    = var.hosted_zone_id != "" ? var.hosted_zone_id : module.route53.hosted_zone_id
}

# 7. RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  subnet_ids             = module.vpc.private_subnets
  db_security_group_id   = module.security_groups.db_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  multi_az               = var.enable_multi_az
  project_name           = var.project_name
  tags                   = var.tags

  depends_on = [module.vpc, module.security_groups]
}

# 8. S3 + CloudFront for static/media
module "s3_cloudfront" {
  source = "./modules/s3-cloudfront"

  count           = var.cloudfront_enabled ? 1 : 0
  bucket_name     = "${replace(var.domain_name, ".", "-")}-static-${random_id.bucket_suffix.hex}"
  domain_name     = var.domain_name
  certificate_arn = module.acm.cloudfront_certificate_arn
  project_name    = var.project_name
  tags            = var.tags

  depends_on = [module.acm]
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 9. Route 53
module "route53" {
  source = "./modules/route53"

  domain_name       = var.domain_name
  hosted_zone_id    = var.hosted_zone_id
  alb_dns_name      = module.alb.dns_name
  alb_zone_id       = module.alb.zone_id
  cloudfront_domain = var.cloudfront_enabled ? module.s3_cloudfront[0].cloudfront_domain_name : ""
  tags              = var.tags

  depends_on = [module.alb, module.s3_cloudfront]
}

# 10. Secrets Manager
module "secrets" {
  source = "./modules/secrets"

  db_endpoint     = module.rds.endpoint
  db_username     = var.db_username
  db_password     = module.rds.password  # Pass the generated password directly
  db_name         = var.db_name
  project_name    = var.project_name
  tags            = var.tags

  depends_on = [module.rds]
}

# 11. ECR Repository
module "ecr" {
  source = "./modules/ecr"

  repository_name         = var.ecr_repository_name != "" ? var.ecr_repository_name : var.project_name
  image_tag_mutability    = var.ecr_image_tag_mutability
  scan_on_push            = var.ecr_scan_on_push
  project_name            = var.project_name
  tags                    = var.tags
}