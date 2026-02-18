locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnets = [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index)
  ]
  private_subnets = [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index + 10)
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.common_tags
}
