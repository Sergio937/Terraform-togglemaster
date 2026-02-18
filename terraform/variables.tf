variable "aws_region" {
  description = "Regiao AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  description = "Identificador opcional de ambiente"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Quantidade de AZs"
  type        = number
  default     = 2
}

variable "eks_version" {
  description = "Versao do Kubernetes no EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Tipos de instancia para o node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_node_desired_size" {
  description = "Quantidade desejada de nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimo de nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximo de nodes"
  type        = number
  default     = 3
}

variable "enable_irsa" {
  description = "Habilita IRSA no EKS"
  type        = bool
  default     = false
}

variable "rds_engine_version" {
  description = "Versao do PostgreSQL no RDS"
  type        = string
  default     = "17.4"
}

variable "rds_instance_class" {
  description = "Classe da instancia RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Storage do RDS (GB)"
  type        = number
  default     = 20
}

variable "rds_db_name" {
  description = "Nome do banco principal"
  type        = string
  default     = "togglemaster"
}

variable "rds_username" {
  description = "Usuario admin do PostgreSQL"
  type        = string
  default     = "tm_user"
}

variable "rds_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "Tipo de node do ElastiCache"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Versao do Redis"
  type        = string
  default     = "7.1"
}

variable "redis_num_cache_clusters" {
  description = "Quantidade de nos Redis"
  type        = number
  default     = 1
}

variable "sqs_message_retention_seconds" {
  description = "Retencao de mensagens SQS"
  type        = number
  default     = 345600
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
  default     = "ToggleMasterAnalytics"
}
