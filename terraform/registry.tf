resource "aws_ecr_repository" "analytics_service" {
  name                 = "${var.project_name}/analytics-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.common_tags
}

resource "aws_ecr_repository" "auth_service" {
  name                 = "${var.project_name}/auth-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.common_tags
}

resource "aws_ecr_repository" "evaluation_service" {
  name                 = "${var.project_name}/evaluation-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.common_tags
}

resource "aws_ecr_repository" "flag_service" {
  name                 = "${var.project_name}/flag-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.common_tags
}

resource "aws_ecr_repository" "targeting_service" {
  name                 = "${var.project_name}/targeting-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.common_tags
}
