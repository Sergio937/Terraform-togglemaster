# Cluster EKS customizado usando LabRole para AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_eks_cluster" "main" {
  name            = "${var.project_name}-${var.environment}"
  version         = var.eks_version
  role_arn        = data.aws_iam_role.lab_role.arn
  vpc_config {
    subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  }
  tags = local.common_tags
}

# Node group usando LabRole
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-ng"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  instance_types = var.eks_node_instance_types

  tags = local.common_tags
}
