output "aws_account_id" {
  description = "ID da conta AWS"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Regiao AWS"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Subnets publicas"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Subnets privadas"
  value       = module.vpc.private_subnets
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "rds_auth_endpoint" {
  description = "Endpoint do PostgreSQL Auth Service no RDS"
  value       = aws_db_instance.postgres_auth.address
}

output "rds_flag_endpoint" {
  description = "Endpoint do PostgreSQL Flag Service no RDS"
  value       = aws_db_instance.postgres_flag.address
}

output "rds_targeting_endpoint" {
  description = "Endpoint do PostgreSQL Targeting Service no RDS"
  value       = aws_db_instance.postgres_targeting.address
}

output "redis_primary_endpoint" {
  description = "Endpoint primario do Redis"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "sqs_queue_url" {
  description = "URL da fila SQS"
  value       = aws_sqs_queue.main.id
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.name
}

output "ecr_repository_urls" {
  description = "URLs dos repositorios ECR"
  value = {
    analytics_service  = aws_ecr_repository.analytics_service.repository_url
    auth_service       = aws_ecr_repository.auth_service.repository_url
    evaluation_service = aws_ecr_repository.evaluation_service.repository_url
    flag_service       = aws_ecr_repository.flag_service.repository_url
    targeting_service  = aws_ecr_repository.targeting_service.repository_url
  }
}
