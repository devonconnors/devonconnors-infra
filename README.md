# terraform-aws-django

This repository deploys a complete, production-ready, cost-optimized stack for a **single** Dockerized Django e-commerce website on AWS.

## Features

- VPC with public/private subnets across 3 AZs
- Cheap NAT using [fck-nat](https://registry.terraform.io/modules/RaJiska/fck-nat/aws/latest) (t4g.nano — ~£3–5/month)
- Auto Scaling Group (ASG) with launch template for a single EC2 instance (t4g.medium by default) running your Docker containers via Docker Compose (Django, Celery, Redis)
- Application Load Balancer (ALB) with HTTP → HTTPS redirect
- Free ACM certificates for ALB and CloudFront (DNS validation with outputs for manual addition at registrar)
- Multi-AZ PostgreSQL RDS (encrypted)
- S3 + CloudFront CDN for static/media files
- Route 53 DNS (creates new hosted zone; update registrar NS records manually)
- Secrets Manager for consolidated "prod" secret (DB credentials, SES SMTP credentials; additional keys added manually)
- Private ECR repository (immutable tags, scan on push)
- CloudWatch Agent for metrics/logs
- Full tagging and least-privilege security groups

**Estimated baseline cost** (low-traffic UK site): **~£80–140/month**

## Prerequisites

- AWS account with programmatic access (IAM user or role with AdministratorAccess for simplicity)
- A registered domain name (e.g., with Cloudlare, GoDaddy Route 53; NS delegation to Route 53 recommended but optional)
- Your private Django repo with a `Dockerfile` (Gunicorn + Celery recommended) and production-ready `docker-compose.yml`

## One-Time Setup for a Fresh Install (New Client)

Use a dedicated AWS account per shop to isolate resources and costs.

1. **Create S3 Bucket for Terraform State**
   - Console > S3 > Create bucket.
   - Name: Globally unique & relevant.
   - Region: eu-west-2.
   - Enable versioning and encryption (SSE-S3).

2. **Create DynamoDB Table for State Locking**
   - Console > DynamoDB > Tables > Create table.
   - Name: `terraform-locks`.
   - Partition key: `LockID` (String).
   - Default settings.

3. **Update Backend Configuration**
   - Edit `backend.tf` for S3:
     ```hcl
     terraform {
       backend "s3" {
         bucket         = "clientname-django-tf-state-2026"  # YOUR BUCKET
         key            = "terraform.tfstate"
         region         = "eu-west-2"
         dynamodb_table = "terraform-locks"  # YOUR TABLE
         encrypt        = true
       }
     }

For Terraform Cloud (remote state/execution):
app.terraform.io > New workspace (e.g., clientname-django-prod).
Update to remote backend:hclterraform {
  backend "remote" {
    organization = "your-org"
    workspaces {
      name = "clientname-django-prod"
    }
  }
}
Run terraform login.



(Optional) EC2 Key Pair for Debug
Console > EC2 > Key Pairs > Create.
Name: clientname-django-key.
Download .pem.


Configuration for New Client

Copy and Fill tfvars
cp terraform.tfvars.example terraform.tfvars.
Edit with client details:hclproject_name      = "clientname-django-app"
domain_name       = "clientdomain.co.uk"

# Optional overrides
app_instance_type = "t4g.medium"
nat_instance_type = "t4g.nano"
db_instance_class = "db.t4g.nano"
ecr_repository_name = "clientname-ecr-repo"  # ECR name
# Existing resources for import/reuse
existing_vpc_id     = "vpc-xxxxxxxx"  # If reusing
# ... other existing_* if importing

Customize for Django Repo
In modules/ec2/user_data.sh, update the embedded docker-compose.yml to match client's repo (services, env vars, commands).
For secrets: Terraform writes DB/SES to "prod" secret; add client-specific (Stripe, Google) manually in Console.


Deploy
textgit clone https://github.com/devonconnors/devonconnors-infra.git
cd devonconnors-infra

terraform init
terraform plan
terraform apply
Answer "yes" to apply.

If importing existing resources (e.g., VPC, RDS, S3, secrets, SGs): Add scaffolding to imports.tf (empty blocks), run imports, then plan/apply to adopt.

Post-Deployment

DNS Setup
Terraform creates a Route 53 hosted zone—output "route53_name_servers" shows NS records.
Update registrar (GoDaddy) with these NS to delegate DNS to Route 53 (optional but recommended for auto-validation).

ACM Validation (HTTPS)
Outputs "alb_validation_options" and "cloudfront_validation_options" show CNAME records (4-6 total).
Add as CNAME in registrar DNS (GoDaddy: DNS Management > Add > Type: CNAME, Host: _abc123, Value: _def456.acm-validations.aws, TTL: 60).
Wait 5-30 minutes for validation (re-plan to check certificate_status "ISSUED").

Important Outputs
website_url: Live site (HTTPS after validation).
ecr_repository_url: For Docker pushes.
asg_name: Auto Scaling Group for EC2.
rds_endpoint: RDS connection (sensitive).
alb_dns_name: Temp URL before DNS.
cloudfront_domain: CDN domain.

Initial Access
SSM: aws ssm start-session --target i-xxxxxxxx (instance ID from ASG instances in Console).

Django Secrets
Terraform creates/updates "prod" secret with DB/SES creds.
Add client-specific keys (Stripe, Google, email) manually in Console > Secrets Manager > "prod" > New version > Edit JSON.
App fetches from "prod" at runtime (implement in Django with boto3).


Connect to Your Django Repo (Automated CI/CD)
In the client's private Django repo:

Settings > Secrets and Variables > Actions
Add Variables:
AWS_REGION = eu-west-2
ECR_REGISTRY = <account-id>.dkr.ecr.eu-west-2.amazonaws.com
ECR_REPO_NAME = output "ecr_repository_name"
ASG_NAME = output "asg_name"  # For remote restart

Add Secrets:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY (IAM user with ECR push + EC2 describe/restart perms)

Add .github/workflows/deploy.yml (use provided template; builds/pushes to ECR, restarts ASG).

Pushes to main auto-deploy.
Cleanup
textterraform destroy
Answer "yes".
Notes

One shop per AWS account.
Driven by tfvars—no manual module config.
Tagged/cost-optimized for small-medium traffic.
For multi-client: Fork per client or use workspaces.
ECR: Push Django image with commands in README.
CloudWatch: Logs/metrics configured on EC2.

Enjoy your fast, secure, low-cost Django store!
text</DOCUMENT>



# Updating Web Application Codebase
- This can all be done via AWS CLI, just identify an EC2 instance ID and secure shell into it (replacing `instance_id` and `account_id` with your specific values)
  ```bash
  aws configure
  aws ssm start-session --target {instance_id} --region eu-west-2
  sudo su - ec2-user
  aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin {account_id}.dkr.ecr.eu-west-2.amazonaws.com
  cd app
  ```
  ```bash
  aws configure
  aws ssm start-session --target i-0cfb0568d03ed8770 --region eu-west-2
  sudo su - ec2-user
  aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 588738597496.dkr.ecr.eu-west-2.amazonaws.com
  cd app
  ```
- Then pull the latest docker image and restart the containers:
  ```bash
  docker compose pull && docker compose down && docker compose up -d && docker compose logs -f
  ```
- To shell into the webserver container within the web application:
  ```bash
  docker exec -it app-django-1 sh
  ```

# Pausing & Unpausing Infrastructure
Only a handful of pieces of infrastructure contribute to the vast majority of cost, that is:
- EC2 instances that enable the web application (approx 35% of overall cost)
- RDS instance that supports the web application (approx 35% of overall cost)
- ALB instance that auto-scales the web application when needed (approx 25% of overall cost)

## Temporarily Pausing Infrastructure/Project
- Set `pause_infra = true`
- Run `terraform apply`, it will:
  - Destroy the Nat Gateway (EC2)
  - Destroy ALB instances and security groups
  - Alter the webserver's ASG to use 0 instances
  - Enable deletion on the RDS instance
- Then finally run `terraform destroy -target=module.rds` to delete the RDS instance
- Runnings costs will then be < £5 per month

## Unpausing Infrastructure/Project
- Set `pause_infra = false` and `restore_from_snapshot = true`
- Run `terraform apply`, it will:
  - Recreate the Nat Gateway (EC2)
  - Recreate the ALB instance and security group and configure them with the webserver
  - Alter the webserver's ASG to use 1-3 instances (so it will launch an instance and serve the application)
  - Create an RDS instance and will restore it to the snapshot that was taken on deletion when the infrastructure was paused
- Now the web application is back up and running with normal running costs
- Lastly, change back to `restore_from_snapshot = false` to ensure the RDS instance is not restored again on the next use of `terraform apply`