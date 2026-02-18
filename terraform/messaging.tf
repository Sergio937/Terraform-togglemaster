resource "aws_sqs_queue" "main" {
  name                      = "${var.project_name}-queue"
  message_retention_seconds = var.sqs_message_retention_seconds

  tags = merge(local.common_tags, { Service = "messaging" })
}
