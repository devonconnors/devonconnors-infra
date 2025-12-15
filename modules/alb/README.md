# ALB Module

Provisions an internet-facing Application Load Balancer with HTTP → HTTPS redirect and forwarding to a single EC2 instance.

Inputs: VPC ID, public subnets, app instance ID, ACM cert ARN, etc.

Outputs: ALB DNS name, zone ID (for Route 53), ARN.