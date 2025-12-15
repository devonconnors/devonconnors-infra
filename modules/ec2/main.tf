# Latest Amazon Linux 2 ARM64 AMI
data "aws_ssm_parameter" "amzn2_ami_arm" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

# IAM Instance Profile (ECR pull + Secrets Manager + SSM + CloudWatch)
resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app.name
}

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

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  tags = var.tags
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.amzn2_ami_arm.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.app_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.app.name
  associate_public_ip_address = true

  key_name = var.key_name != "" ? var.key_name : null

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  }))

  tags = merge(var.tags, {
    Name = "${var.project_name}-app"
  })

  volume_tags = merge(var.tags, {
    Name = "${var.project_name}-app-root"
  })

  lifecycle {
    create_before_destroy = true
  }
}