# Terraform - ToggleMaster

Este diretório provisiona a infraestrutura AWS do projeto ToggleMaster.

## O que é criado

- **Rede:** VPC, subnets públicas/privadas e NAT Gateway
- **Kubernetes:** EKS cluster + node group
- **Banco de dados:** 3 instâncias RDS PostgreSQL (Auth, Flag, Targeting)
- **Cache:** ElastiCache Redis
- **Mensageria:** SQS
- **NoSQL:** DynamoDB (analytics)
- **Registry:** 5 repositórios ECR (um por microserviço)
- **Estado remoto Terraform:** S3 (state) + DynamoDB (lock), via bootstrap

---

## Estrutura

```text
terraform/
├── bootstrap/               # Cria backend remoto (S3 + DynamoDB)
│   ├── main.tf
│   ├── variables.tf
│   └── bootstrap.tfvars
├── backend.tf               # Configuração do backend remoto
├── networking.tf            # VPC e subnets
├── eks.tf                   # EKS cluster e node group
├── database.tf              # RDS + Redis
├── messaging.tf             # SQS
├── nosql.tf                 # DynamoDB
├── registry.tf              # ECR
├── variables.tf             # Variáveis do projeto
├── terraform.tfvars         # Valores do ambiente
└── outputs.tf               # Saídas úteis
```

---

## Pré-requisitos

- Terraform `>= 1.10.0`
- AWS CLI configurada
- Permissões AWS para criar recursos de rede, EKS, RDS, ECR, S3, DynamoDB etc.
- No ambiente AWS Academy, a role **LabRole** deve existir (o EKS usa essa role)

---

## Ordem de execução (obrigatória)

### 1) Bootstrap do backend remoto

```bash
cd terraform/bootstrap
terraform init
terraform apply -var-file=bootstrap.tfvars
```

Esse passo cria:
- Bucket S3: `${project_name}-terraform-state-<account_id>`
- Tabela DynamoDB: `${project_name}-terraform-locks`

### 2) Deploy da stack principal

```bash
cd ../
terraform init -reconfigure
terraform plan
terraform apply
```

> O `backend.tf` já está apontando para:
> - bucket: `togglemaster-terraform-state-913430344673`
> - key: `togglemaster/terraform.tfstate`
> - region: `us-east-1`
> - lock table: `togglemaster-terraform-locks`

---

## Variáveis importantes

Arquivo: `terraform.tfvars`

- `aws_region`: região AWS (default `us-east-1`)
- `project_name`: prefixo nominal dos recursos
- `eks_version`: versão do Kubernetes (`1.29`)
- `rds_engine_version`: versão PostgreSQL (**`17.4`**)
- `rds_username` / `rds_password`: credenciais dos bancos
- `dynamodb_table_name`: tabela de analytics

### Segurança

Atualmente há senha no `terraform.tfvars`. Para produção, prefira:
- variável de ambiente (`TF_VAR_rds_password`), ou
- secret manager / pipeline secret

---

## Outputs úteis

Após `terraform apply`, consulte:

```bash
terraform output
```

Saídas principais:
- `eks_cluster_name`
- `eks_cluster_endpoint`
- `rds_auth_endpoint`
- `rds_flag_endpoint`
- `rds_targeting_endpoint`
- `redis_primary_endpoint`
- `sqs_queue_url`
- `dynamodb_table_name`
- `ecr_repository_urls`

---

## Comandos úteis de operação

### Atualizar kubeconfig do cluster

```bash
aws eks update-kubeconfig --name togglemaster --region us-east-1
```

### Ver recursos criados

```bash
terraform state list
```

### Planejar sem aplicar

```bash
terraform plan
```

### Destruir infraestrutura

```bash
terraform destroy
```

> **Atenção:** `destroy` remove recursos críticos (EKS, RDS, ECR, etc.).

---

## Troubleshooting rápido

- **Erro no backend (`Bucket/Table not found`)**
  - Execute primeiro o bootstrap em `terraform/bootstrap`

- **Erro de role no EKS (`LabRole`)**
  - Verifique se a role `LabRole` existe na conta/região

- **Provider ou lock error**
  - Rode `terraform init -reconfigure`

- **Falha de permissão AWS**
  - Confirme credenciais com `aws sts get-caller-identity`
