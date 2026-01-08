# IAM Role for EC2 instances (ECR pull, SSM, Secrets Manager, CloudWatch Agent)
resource "aws_iam_role" "app" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach policies separately (replaces deprecated managed_policy_arns)
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Scoped Secrets Manager policy (replaces broad SecretsManagerReadWrite for better security)
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "${var.project_name}-ec2-secrets-access"
  description = "Allow EC2 instance to read project-specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:django-*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_access" {
  role       = aws_iam_role.app.name  # Fixed to match your role name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Get current AWS account ID for ARN (if not already present)
data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app.name
}

# Launch Template for ASG instances
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ECR_REPO_URL                  = var.ecr_repo_url
    AWS_REGION                    = var.aws_region
    ALLOWED_HOSTS             = join(",", [var.domain_name, "www.${var.domain_name}"])
    ALLOWED_CIDR_NETS             = join(",", var.allowed_cidr_nets)
    CSRF_TRUSTED_ORIGINS          = join(",", [for host in [var.domain_name, "www.${var.domain_name}", "static.${var.domain_name}"] : "https://${host}"])
    APP_NAME                      = var.project_name
    CACHE_LOCATION                = "redis://redis:6379/1"
    CELERY_BROKER                 = "redis://redis:6379/0"
    CELERY_BACKEND                = "redis://redis:6379/0"
    AWS_PUBLIC_STORAGE_BUCKET_NAME  = var.aws_public_storage_bucket_name
    AWS_PRIVATE_STORAGE_BUCKET_NAME = var.aws_private_storage_bucket_name
    AWS_CLOUDFRONT_DOMAIN         = var.aws_cloudfront_domain
    DUMMY_FORCE_REFRESH = "2026-01-05-5" # Force an update
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.project_name}-app-instance", DummyTag = "v5" })  # Force an update
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  health_check_type   = "ELB"

  vpc_zone_identifier = [var.subnet_id]  # Private subnet preferred

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Tags for the ASG itself (not propagated to instances)
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }

  # Tags propagated to launched instances
  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Scale out policy (high CPU)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# Scale in policy (low CPU)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# S3 access policy for static & media buckets
resource "aws_iam_policy" "s3_static_media_access" {
  name        = "${var.project_name}-ec2-s3-static-media"
  description = "Allow EC2 to read/write static and media files in S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBucketOperations"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.aws_public_storage_bucket_name}",
          "arn:aws:s3:::${var.aws_private_storage_bucket_name}"
        ]
      },
      {
        Sid    = "AllowObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.aws_public_storage_bucket_name}/*",
          "arn:aws:s3:::${var.aws_private_storage_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach the S3 policy to the EC2 role
resource "aws_iam_role_policy_attachment" "attach_s3_access" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.s3_static_media_access.arn
}