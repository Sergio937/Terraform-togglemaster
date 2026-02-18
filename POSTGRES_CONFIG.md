# PostgreSQL Databases - Configuração ToggleMaster

## Auth Service Database
- **Identifier**: `togglemaster-dev-auth-postgres`
- **Database**: `togglemaster_auth`
- **Username**: `tm_user`
- **Password**: `togglemasterpwsd`
- **Engine**: PostgreSQL 12
- **Instance Type**: db.t3.medium
- **Port**: 5432 (padrão)
- **Endpoint**: (será exibido nos outputs do Terraform)

## Flag Service Database
- **Identifier**: `togglemaster-dev-flag-postgres`
- **Database**: `togglemaster_flag`
- **Username**: `tm_user`
- **Password**: `togglemasterpwsd`
- **Engine**: PostgreSQL 12
- **Instance Type**: db.t3.medium
- **Port**: 5432 (padrão)
- **Endpoint**: (será exibido nos outputs do Terraform)

## Targeting Service Database
- **Identifier**: `togglemaster-dev-targeting-postgres`
- **Database**: `togglemaster_targeting`
- **Username**: `tm_user`
- **Password**: `togglemasterpwsd`
- **Engine**: PostgreSQL 12
- **Instance Type**: db.t3.medium
- **Port**: 5432 (padrão)
- **Endpoint**: (será exibido nos outputs do Terraform)

## Security Group
- **Name**: `togglemaster-dev-rds`
- **VPC**: Dentro da VPC criada (10.0.0.0/16)
- **Port Aberto**: 5432 para CIDR 10.0.0.0/16

## Subnet Group
- **Name**: `togglemaster-dev-rds-subnets`
- **Subnets**: Ambas as subnets privadas (us-east-1a e us-east-1b)

## Configurações Adicionais
- **Backup**: skip_final_snapshot = true
- **Multi-AZ**: (será definido automaticamente)
- **Publicly Accessible**: false
