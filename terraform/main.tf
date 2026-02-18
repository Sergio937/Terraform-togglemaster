locals {
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}