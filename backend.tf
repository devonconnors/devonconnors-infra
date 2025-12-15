terraform {
  backend "s3" {
    bucket         = "your-unique-global-bucket-name"  # CHANGE THIS ONCE per account
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}