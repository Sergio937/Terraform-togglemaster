terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote Backend Configuration - S3 and DynamoDB
  backend "s3" {
    bucket         = "togglemaster-terraform-state-913430344673"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "togglemaster-terraform-locks"
  }
}
