# Random strong password (generated each apply - stored in Secrets Manager later)
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# DB Subnet Group (private subnets)
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier                  = "${var.project_name}-db"

  engine                      = "postgres"
  engine_version              = "16"  # Latest stable - adjust if needed
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = 100  # Enable storage autoscaling up to 100GB

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = random_password.master.result
  port                        = 5432

  vpc_security_group_ids      = [var.db_security_group_id]
  db_subnet_group_name        = aws_db_subnet_group.this.name

  multi_az                    = var.multi_az
  storage_encrypted           = true
  storage_type                = "gp2"  # Or gp3 for better performance

  backup_retention_period     = var.backup_retention_period
  backup_window     = var.backup_window
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.project_name}-db-final-snapshot"
  deletion_protection         = true

  auto_minor_version_upgrade  = true
  apply_immediately           = true

  parameter_group_name        = aws_db_parameter_group.django.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-postgres"
  })
}

# Custom Parameter Group (Django-friendly defaults)
resource "aws_db_parameter_group" "django" {
  name   = "${var.project_name}-django-pg"
  family = "postgres16"

  parameter {
    name  = "client_encoding"
    value = "UTF8"
  }

  parameter {
    name  = "timezone"
    value = "UTC"
  }

  # Add more Django tweaks later if needed (e.g., max_connections)

  tags = var.tags
}