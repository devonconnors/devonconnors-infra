# Random strong password (generated each apply - stored in Secrets Manager later)
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1

  keepers = {
    force_reset = "2026-01-05-v2" # Force new password
  }
}

# DB Subnet Group (private subnets)
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier                  = "proddb"

  engine                      = "postgres"
  engine_version              = "16"  # Latest stable - adjust if needed
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = 100  # Enable storage autoscaling up to 100GB
  publicly_accessible         = var.publicly_accessible

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = random_password.master.result
  port                        = 5432

  vpc_security_group_ids      = [var.db_security_group_id]
  db_subnet_group_name        = aws_db_subnet_group.this.name

  multi_az                    = var.multi_az
  storage_encrypted           = true
  storage_type                = "gp3"

  backup_retention_period     = var.backup_retention_period
  backup_window     = var.backup_window
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.project_name}-db-final-snapshot"
  snapshot_identifier         = var.restore_from_snapshot ? "${var.project_name}-db-final-snapshot" : null
  deletion_protection         = var.pause_infra ? false : true

  auto_minor_version_upgrade  = true
  apply_immediately           = true

  parameter_group_name        = aws_db_parameter_group.django.id

  tags = {
    Name = "${var.project_name}-postgres"
  }
}

# Custom Parameter Group (Django-friendly defaults)
resource "aws_db_parameter_group" "django" {
  name   = "${var.project_name}-django-pg"
  family = "postgres16"

  # IMPORTANT: Disable forced SSL so internal VPC connections don't require encryption
  # This prevents "no pg_hba.conf entry ... no encryption" errors
  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "immediate"
  }

  lifecycle {
    ignore_changes = [parameter]
  }
}