provider "aws" {
  region = var.aws_region

  # Optional: Add your preferred profile if using multiple AWS accounts
  # profile = "your-aws-profile-name"

  # Good defaults for production
  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
      Project     = var.project_name
    })
  }
}

# Required for ACM certificate validation via DNS (Route 53)
provider "aws" {
  alias  = "us_east_1"  # ACM certs for CloudFront must be in us-east-1
  region = "us-east-1"

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
      Project     = var.project_name
    })
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}