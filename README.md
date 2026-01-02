# terraform-aws-django

This repository deploys a complete, production-ready, cost-optimized stack for a **single** Dockerized Django e-commerce website on AWS.

## Features

- VPC with public/private subnets across 3 AZs
- Cheap NAT using [fck-nat](https://registry.terraform.io/modules/RaJiska/fck-nat/aws/latest) (t4g.nano — ~£3–5/month)
- Single EC2 instance (t4g.medium by default) running your Docker container
- Application Load Balancer with HTTP → HTTPS redirect
- Free ACM certificates for ALB and CloudFront
- Multi-AZ PostgreSQL RDS (encrypted)
- S3 + CloudFront CDN for static/media files
- Route 53 DNS (creates new hosted zone or uses existing)
- Secrets Manager for DB credentials and Django `SECRET_KEY`
- Private ECR repository (immutable tags, scan on push)
- Full tagging and least-privilege security groups

**Estimated baseline cost** (low-traffic UK site): **~£80–140/month**

## Prerequisites

- AWS account with programmatic access (IAM user or role)
- A registered domain name
- Your private Django repo with a `Dockerfile` (Gunicorn + Celery recommended)

## One-Time Setup

1. **Create S3 bucket for Terraform state**
   - Name must be globally unique (e.g., `mycompany-django-tf-state-2025`)
   - Region: eu-west-2 (London)
   - Enable versioning and server-side encryption

2. **Update `backend.tf`**
   Replace the placeholder with your real bucket name:

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "mycompany-django-tf-state-2025"  # ← YOUR BUCKET NAME HERE
       key            = "terraform.tfstate"
       region         = "eu-west-2"
       dynamodb_table = "terraform-locks"
       encrypt        = true
     }
   }
   ```

3. **(Optional) Create EC2 Key Pair**
   - AWS Console → EC2 → Key Pairs → Create key pair
   - Name it as appropriate (e.g., `django-app-key`)
   - Download the `.pem` file and store securely (useful for initial debugging)

## Configuration

Copy the example variables file and rename it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your details (example content):

```hcl
project_name      = "my-django-app"                    # Used for resource naming/tagging
domain_name       = "mydjangoapp.co.uk"               # Your domain

# Optional overrides (defaults are cost-optimized and suited for development)
# app_instance_type = "t4g.medium"
# nat_instance_type = "t4g.nano"
# db_instance_class = "db.t4g.small"
```

## Deploy
```Bash
git clone https://github.com/donovannevard/terraform-aws-django.git
cd terraform-aws-django

terraform init
terraform plan
terraform apply
```
Answer yes when prompted.

# Post-Deployment

1. DNS
    - If a new Route 53 hosted zone was created, Terraform will output the name servers.
    - Update your domain registrar (GoDaddy, Namecheap, etc.) with these NS records.

2. Important Outputs (shown after apply)
    - website_url — your live site
    - ecr_repository_url — for Docker pushes
    - ec2_app_instance_id — for CI/CD
    - alb_dns_name — temporary URL for testing before DNS propagates

3. Initial Access (if key_name provided)
    ```Bash
    ssh -i django-app-key.pem ec2-user@<ec2-public-ip-from-outputs>
    ```

4. Django Secrets
    - Terraform automatically creates two secrets in Secrets Manager:
        - DB credentials ({project_name}-db-credentials)
        - Django SECRET_KEY ({project_name}-django-secret-key)

    - Manually add any additional shop-specific secrets (Stripe keys, Google OAuth, email passwords, etc.) in the AWS Secrets Manager console.
        - Recommended naming: {project_name}-stripe, {project_name}-google, {project_name}-email, etc.
        - Store as JSON key/value pairs for easy retrieval.

    - Your Django app will fetch all required secrets at runtime from Secrets Manager (no secrets in code or Docker image).


## Connect to Your Django Repo (Automated CI/CD)

In your **private Django repository**:

1. Go to Settings → Secrets and Variables → Actions

2. Add **Variables**:
   - `AWS_REGION` = `eu-west-2`
   - `ECR_REGISTRY` = `<your-account-id>.dkr.ecr.eu-west-2.amazonaws.com`
   - `ECR_REPO_NAME` = value from Terraform output `ecr_repository_name`
   - `EC2_APP_INSTANCE_ID` = value from Terraform output `ec2_app_instance_id`

3. Add **Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`  
     (Create an IAM user with permissions: ECR push + SSM SendCommand)

4. Add `.github/workflows/deploy.yml` to your Django repo (example workflow can be provided separately).

Every push to `main` will automatically:
- Build the Docker image
- Push to ECR
- Run a remote command on the EC2 instance to pull and restart the container

## Cleanup

```bash
terraform destroy
```
Answer yes to confirm.

## Notes
- This configuration is designed for one shop per AWS account.
- No manual configuration is needed for individual modules — everything is driven from terraform.tfvars.
- All resources are tagged and cost-optimized for small-to-medium e-commerce traffic.

## Enjoy your fast, secure, low-cost Django store!