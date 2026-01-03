terraform {
  cloud {
    organization = "devonconnors"
    workspaces {
      name = "devonconnors-infra"
    }
  }
}

# Data sources for availability zones and AMI lookups
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amzn2_arm_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

data "aws_ecr_repository" "django" {
  name = var.ecr_repository_name
}

# === MODULE CALLS ===

# 1. VPC with public/private subnets
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr = var.vpc_cidr
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

  name          = "${var.project_name}-nat"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnets[0]
  instance_type = var.nat_instance_type

  # Automatically update private route tables
  update_route_tables = true
  route_tables_ids    = { for i, rt_id in module.vpc.private_route_table_ids : "private-rt-${i}" => rt_id }

  tags = var.tags

  depends_on = [module.vpc]
}

# 4. Django App EC2 instance (now using ASG/launch template)
module "ec2" {
  source = "./modules/ec2"

  domain_name            = var.domain_name
  allowed_cidr_nets      = [module.vpc.vpc_cidr_block]
  project_name           = var.project_name
  tags                   = var.tags
  ami_id                 = data.aws_ssm_parameter.amzn2_arm_ami.value
  instance_type          = var.app_instance_type
  app_security_group_id  = module.security_groups.app_sg_id
  subnet_id              = module.vpc.private_subnets[0]
  django_app_github_repo = var.django_app_github_repo

  db_user                         = module.secrets.db_username
  db_password                     = module.secrets.db_password
  db_host                         = module.rds.endpoint
  db_name                         = var.db_name
  aws_private_storage_bucket_name = module.s3_cloudfront.private_bucket_name
  aws_public_storage_bucket_name  = module.s3_cloudfront.public_bucket_name
  aws_cloudfront_domain           = var.domain_name
  aws_region                      = var.aws_region

  ecr_repo_url = data.aws_ecr_repository.django.repository_url
  depends_on   = [module.nat, module.security_groups]
}

# 5. Application Load Balancer + HTTPS
module "alb" {
  source = "./modules/alb"

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.public_subnets
  project_name           = var.project_name
  domain_name            = var.domain_name
  tags                   = var.tags
  autoscaling_group_name = module.ec2.asg_name

  certificate_arn = module.acm.alb_certificate_arn

  depends_on = [module.ec2, module.acm, module.vpc]
}

# 6. ACM Certificate (EMAIL validation – manual confirmation required)
module "acm" {
  source = "./modules/acm"

  domain_name       = var.domain_name
  alternative_names = ["www.${var.domain_name}", "static.${var.domain_name}"]

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

# 7. RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  subnet_ids              = module.vpc.private_subnets
  db_security_group_id    = module.security_groups.db_sg_id
  db_name                 = var.db_name
  db_username             = var.db_username
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  multi_az                = var.enable_multi_az
  project_name            = var.project_name
  tags                    = var.tags
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window

  depends_on = [module.vpc, module.security_groups]
}

# 8. S3 + CloudFront for static/media
module "s3_cloudfront" {
  source = "./modules/s3-cloudfront"

  bucket_name     = "${replace(var.domain_name, ".", "-")}-static-${random_id.bucket_suffix.hex}"
  domain_name     = var.domain_name
  certificate_arn = module.acm.cloudfront_certificate_arn
  project_name    = var.project_name
  app_role_arn    = module.ec2.app_role_arn
  tags            = var.tags

  depends_on = [module.acm]
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 9. SES for transactional emails
module "ses" {
  source = "./modules/ses"

  domain_name    = var.domain_name
  hosted_zone_id = module.route53_zone.zone_id

  tags = var.tags

  depends_on = [module.route53_zone]
}

# IAM user for SES SMTP credentials
resource "aws_iam_user" "ses_smtp_user" {
  name = "${var.project_name}-ses-smtp"
  tags = var.tags
}

resource "aws_iam_access_key" "ses_smtp" {
  user = aws_iam_user.ses_smtp_user.name
}

resource "aws_iam_user_policy" "ses_send" {
  name = "${var.project_name}-ses-send-email"
  user = aws_iam_user.ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

# 10. Route 53
module "route53_zone" {
  source = "./modules/route53-zone"

  domain_name = var.domain_name
  tags        = var.tags
}

module "route53_aliases" {
  source = "./modules/route53-aliases"

  zone_id           = module.route53_zone.zone_id
  domain_name       = var.domain_name
  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name

  tags = var.tags

  depends_on = [module.s3_cloudfront]
}

# 11. Secrets Manager
module "secrets" {
  source = "./modules/secrets"

  db_endpoint  = module.rds.endpoint
  db_username  = var.db_username
  db_password  = module.rds.password
  db_name      = var.db_name
  ses_username = aws_iam_access_key.ses_smtp.id
  ses_password = aws_iam_access_key.ses_smtp.secret
  project_name = var.project_name
  tags         = var.tags

  depends_on = [module.rds]
}

resource "aws_ssm_document" "django_update" {
  name          = "devonconnors-django-update"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Update Django repo/image and restart containers"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "updateDjango"
        inputs = {
          runCommand = [] # Commands come from SSM send-command parameters
        }
      }
    ]
  })
}