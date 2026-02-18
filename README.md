# 🚀 ToggleMaster - Feature Flag Management Platform

Sistema completo de gerenciamento de feature flags com arquitetura de microsserviços, infraestrutura como código (Terraform), Kubernetes (EKS), e pipelines DevSecOps.

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Microsserviços](#microsserviços)
- [Infraestrutura](#infraestrutura)
- [CI/CD & DevSecOps](#cicd--devsecops)
- [GitOps](#gitops)
- [Documentação](#documentação)
- [Quick Start](#quick-start)

---

## 🎯 Visão Geral

ToggleMaster é uma plataforma empresarial de feature flags que permite:
- ✅ Gerenciamento centralizado de feature flags
- ✅ Avaliação de flags em tempo real
- ✅ Targeting avançado de usuários
- ✅ Analytics e monitoramento
- ✅ Autenticação e autorização JWT
- ✅ Deploy seguro com GitOps

---

## 🏗️ Arquitetura

### **Microsserviços (5 serviços):**

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud (EKS)                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Auth Service │  │ Flag Service │  │ Eval Service │     │
│  │   (Go)       │  │   (Python)   │  │   (Go)       │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                  │              │
│  ┌──────▼──────┐  ┌──────▼───────┐  ┌──────▼────────┐    │
│  │ PostgreSQL  │  │  PostgreSQL  │  │  Redis Cache  │    │
│  │  (RDS)      │  │   (RDS)      │  │ (ElastiCache) │    │
│  └─────────────┘  └──────────────┘  └───────────────┘    │
│                                                             │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │ Targeting Service│◄────────┤Analytics Service │        │
│  │   (Python)       │  Queue  │    (Python)      │        │
│  └──────┬───────────┘         └──────┬───────────┘        │
│         │                             │                     │
│  ┌──────▼────────┐            ┌──────▼──────────┐         │
│  │  PostgreSQL   │            │    DynamoDB     │         │
│  │    (RDS)      │            │   (NoSQL)       │         │
│  └───────────────┘            └─────────────────┘         │
│                                                             │
│  ┌──────────────────────────────────────────────┐         │
│  │           Amazon SQS (Message Queue)         │         │
│  └──────────────────────────────────────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘

         ┌────────────────────────────────────┐
         │      Ingress (Load Balancer)       │
         │  analytics-service.togglemaster.io │
         └────────────────────────────────────┘
```

### **Stack Tecnológico:**

- **Container Orchestration:** Kubernetes (Amazon EKS)
- **Infrastructure as Code:** Terraform
- **Container Registry:** Amazon ECR
- **Databases:** 
  - PostgreSQL (Amazon RDS) para Auth, Flag, Targeting
  - Redis (Amazon ElastiCache) para cache
  - DynamoDB para analytics
- **Message Queue:** Amazon SQS
- **CI/CD:** GitHub Actions
- **GitOps:** ArgoCD
- **Security:** Trivy, Bandit, gosec, golangci-lint

---

## 🔧 Microsserviços

### **1. Auth Service** (Go)
- **Porta:** 8081
- **Função:** Autenticação e geração de tokens JWT
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `POST /auth/login` - Login de usuários
  - `POST /auth/register` - Registro de novos usuários
  - `GET /auth/validate` - Validação de token

### **2. Flag Service** (Python)
- **Porta:** 8082
- **Função:** CRUD de feature flags
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `GET /flags` - Listar flags
  - `POST /flags` - Criar flag
  - `PUT /flags/:id` - Atualizar flag
  - `DELETE /flags/:id` - Deletar flag

### **3. Evaluation Service** (Go)
- **Porta:** 8083
- **Função:** Avaliação de flags para usuários
- **Cache:** Redis (ElastiCache)
- **Queue:** Amazon SQS (eventos de avaliação)
- **Endpoints:**
  - `POST /evaluate` - Avaliar flag para usuário
  - `GET /evaluate/bulk` - Avaliação em lote

### **4. Targeting Service** (Python)
- **Porta:** 8084
- **Função:** Regras de targeting de usuários
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `GET /targeting/rules` - Listar regras
  - `POST /targeting/rules` - Criar regra
  - `POST /targeting/match` - Verificar match de usuário

### **5. Analytics Service** (Python)
- **Porta:** 8085
- **Função:** Coleta e análise de eventos
- **Database:** DynamoDB
- **Queue Consumer:** Amazon SQS
- **Endpoints:**
  - `GET /analytics/stats` - Estatísticas de uso
  - `GET /analytics/events` - Eventos registrados
  - `POST /analytics/query` - Query customizada

---

## ☁️ Infraestrutura

### **Recursos AWS Provisionados:**

#### **Compute:**
- ✅ Amazon EKS Cluster (Kubernetes 1.29)
- ✅ Node Group: 2x t3.medium (min: 1, max: 4)

#### **Databases:**
- ✅ 3x PostgreSQL RDS instances (db.t3.medium)
  - auth-service DB
  - flag-service DB
  - targeting-service DB
- ✅ Redis ElastiCache (cache.t3.micro)
- ✅ DynamoDB table (ToggleMasterAnalytics)

#### **Container Registry:**
- ✅ 5x ECR repositories (um por serviço)

#### **Networking:**
- ✅ VPC customizada (10.0.0.0/16)
- ✅ 2x Public Subnets
- ✅ 2x Private Subnets
- ✅ NAT Gateway
- ✅ Internet Gateway
- ✅ Security Groups

#### **Message Queue:**
- ✅ Amazon SQS Queue

### **Terraform Modules:**

```
terraform/
├── main.tf           # Main configuration
├── providers.tf      # AWS provider
├── networking.tf     # VPC, subnets, NAT
├── eks.tf           # EKS cluster
├── database.tf      # RDS instances
├── nosql.tf         # DynamoDB
├── messaging.tf     # SQS
├── registry.tf      # ECR repositories
├── variables.tf     # Input variables
└── outputs.tf       # Output values
```

---

## 🔄 CI/CD & DevSecOps

### **Pipeline Stages:**

Cada microsserviço possui um pipeline completo com 4 jobs:

```
┌─────────────────┐
│ 1. Build & Test │
│  - Compile      │
│  - Unit Tests   │
│  - Docker Build │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ 2. Linter       │
│  - flake8/Go    │
│  - Code Quality │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ 3. Security     │
│  - SAST         │
│  - SCA          │
│  ⚠️ Block CRIT  │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ 4. Docker Push  │
│  - Build Image  │
│  - Scan Image   │
│  - Push to ECR  │
│  - Update GitOps│
└─────────────────┘
```

### **Security Layers:**

1. **Linting:** flake8 (Python), golangci-lint (Go)
2. **SAST:** bandit (Python), gosec (Go)
3. **SCA:** Trivy filesystem scan
4. **Container Security:** Trivy image scan
5. **Blocking:** Pipeline fails on CRITICAL vulnerabilities

### **Workflows:**

- [analytics-service.yml](.github/workflows/analytics-service.yml)
- [auth-service.yml](.github/workflows/auth-service.yml)
- [evaluation-service.yml](.github/workflows/evaluation-service.yml)
- [flag-service.yml](.github/workflows/flag-service.yml)
- [targeting-service.yml](.github/workflows/targeting-service.yml)

---

## 🔄 GitOps

### **ArgoCD Configuration:**

```
gitops/
├── argocd/
│   ├── install.sh         # ArgoCD installation script
│   └── README.md
├── apps/                  # ArgoCD Application definitions
│   ├── analytics-service.yaml
│   ├── auth-service.yaml
│   ├── evaluation-service.yaml
│   ├── flag-service.yaml
│   └── targeting-service.yaml
└── manifests/             # Kubernetes manifests
    ├── namespace/
    ├── ingress/
    ├── analytics-service/
    ├── auth-service/
    ├── evaluation-service/
    ├── flag-service/
    └── targeting-service/
```

### **Deployment Flow:**

1. Developer pushes code to `main`
2. GitHub Actions builds and tests
3. Security scans validate code
4. Docker image built and scanned
5. Image pushed to ECR with commit SHA tag
6. GitOps manifest updated automatically
7. ArgoCD detects change
8. ArgoCD syncs to Kubernetes cluster
9. Service deployed with zero-downtime

---

## 📚 Documentação

### **Core Documentation:**

| Document | Description |
|----------|-------------|
| [.github/workflows/README.md](.github/workflows/README.md) | CI/CD Pipeline Documentation |
| [LOCAL_DEV_GUIDE.md](LOCAL_DEV_GUIDE.md) | Local Development & Testing Guide |
| [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) | GitHub Secrets Configuration |
| [DEVSECOPS_SECURITY.md](DEVSECOPS_SECURITY.md) | Security Features & Tools |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common Issues & Solutions |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System Architecture Details |

### **Configuration Files:**

- [.flake8](.flake8) - Python linting configuration
- [.golangci.yml](.golangci.yml) - Go linting configuration
- [terraform.tfvars](terraform/terraform.tfvars) - Terraform variables

---

## 🚀 Quick Start

### **Prerequisites:**

- AWS Account with credentials configured
- Docker installed
- kubectl installed
- Terraform >= 1.10.0
- GitHub account with repository
- Git installed

### **1. Clone Repository:**

```bash
git clone https://github.com/yourusername/Terraform-Fase03.git
cd Terraform-Fase03
```

### **2. Configure Terraform Variables:**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### **3. Deploy Infrastructure:**

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply (creates all AWS resources)
terraform apply tfplan
```

This will create:
- EKS Cluster
- RDS databases
- ElastiCache
- DynamoDB
- SQS Queue
- ECR repositories
- VPC and networking

**Time:** ~15-20 minutes

### **4. Configure kubectl:**

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-dev
kubectl get nodes  # Verify cluster access
```

### **5. Setup GitHub Secrets:**

Configure required secrets (see [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)):

```bash
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set AWS_REGION -b "us-east-1"
gh secret set AWS_ACCOUNT_ID -b "913430344673"
gh secret set PROJECT_NAME -b "togglemaster"
```

### **6. Build and Push Images:**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  913430344673.dkr.ecr.us-east-1.amazonaws.com

# Build and push all services
cd Kubernetes/analytics-service/analytics-service
docker build -t analytics-service:latest .
docker tag analytics-service:latest 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:latest
docker push 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:latest

# Repeat for other services...
```

Or trigger GitHub Actions workflows.

### **7. Deploy to Kubernetes:**

```bash
# Apply manifests
kubectl apply -f gitops/manifests/namespace/
kubectl apply -f gitops/manifests/analytics-service/
kubectl apply -f gitops/manifests/auth-service/
kubectl apply -f gitops/manifests/evaluation-service/
kubectl apply -f gitops/manifests/flag-service/
kubectl apply -f gitops/manifests/targeting-service/
kubectl apply -f gitops/manifests/ingress/

# Verify deployments
kubectl get pods -n togglemaster
kubectl get svc -n togglemaster
```

### **8. Install ArgoCD (Optional):**

```bash
cd gitops/argocd
./install.sh

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Username: admin
# Password: (get with below command)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### **9. Access Services:**

```bash
# Get ingress address
kubectl get ingress -n togglemaster

# Or use port-forward for quick testing
kubectl port-forward svc/analytics-service -n togglemaster 8085:8085
curl http://localhost:8085/health
```

---

## 🛠️ Development Workflow

### **Local Development:**

See [LOCAL_DEV_GUIDE.md](LOCAL_DEV_GUIDE.md) for detailed instructions.

```bash
# Python services
cd Kubernetes/<service>/<service>
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest -v
flake8 .
bandit -lll -r .

# Go services
cd Kubernetes/<service>/<service>
go mod download
go test ./... -v
golangci-lint run
gosec -severity high ./...
```

### **Making Changes:**

1. Create feature branch
```bash
git checkout -b feature/my-feature
```

2. Make changes and test locally

3. Run security checks
```bash
trivy fs --severity CRITICAL .
docker build -t service:test .
trivy image service:test
```

4. Commit and push
```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

5. Create Pull Request
- CI/CD runs automatically
- Review security scan results
- Merge after approval

6. Deploy to production
- Merge to `main` triggers deployment
- GitHub Actions builds and pushes to ECR
- ArgoCD syncs to cluster

---

## 📊 Monitoring & Observability

### **Kubernetes Dashboard:**

```bash
# Deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View metrics
kubectl top nodes
kubectl top pods -n togglemaster
```

### **Application Logs:**

```bash
# View logs
kubectl logs -f deployment/analytics-service -n togglemaster

# Stream all service logs
kubectl logs -f -l app=analytics-service -n togglemaster --all-containers
```

### **Health Checks:**

All services expose `/health` endpoint:

```bash
kubectl exec -it <pod-name> -n togglemaster -- curl localhost:8080/health
```

---

## 🔐 Security

### **Secrets Management:**

- ❌ Never commit secrets to repository
- ✅ Use Kubernetes secrets
- ✅ Use AWS Secrets Manager (recommended)
- ✅ Rotate credentials regularly

### **Network Security:**

- ✅ Services run in private subnets
- ✅ Security groups restrict access
- ✅ TLS/SSL for all external communication
- ✅ Network policies in Kubernetes

### **Container Security:**

- ✅ Non-root user in containers
- ✅ Read-only root filesystem
- ✅ No privileged containers
- ✅ Security scanning in CI/CD

---

## 📈 Scaling

### **Horizontal Pod Autoscaling:**

```bash
# HPA already configured for analytics and evaluation services
kubectl get hpa -n togglemaster

# Manual scaling
kubectl scale deployment/<service> --replicas=3 -n togglemaster
```

### **Node Autoscaling:**

EKS Node Group configured with:
- Min: 1 node
- Desired: 2 nodes
- Max: 4 nodes

---

## 🧹 Cleanup

### **Destroy Infrastructure:**

```bash
cd terraform

# Destroy all AWS resources
terraform destroy

# Or destroy specific resources
terraform destroy -target=aws_eks_cluster.main
```

**⚠️ Warning:** This will delete:
- EKS cluster
- All databases (data loss!)
- ECR images
- DynamoDB tables
- All networking resources

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests and security scans locally
5. Submit Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 🙋 Support

- **Documentation:** Check files in root directory
- **Issues:** Open GitHub issue
- **Security:** Report to security@togglemaster.io

---

## ✅ Project Status

- [x] Infrastructure provisioning (Terraform)
- [x] EKS Cluster setup
- [x] 5 Microsserviços implementados
- [x] CI/CD pipelines (GitHub Actions)
- [x] DevSecOps security scanning
- [x] GitOps configuration (ArgoCD)
- [x] Kubernetes manifests
- [x] Monitoring & logging
- [ ] Production deployment
- [ ] Performance testing
- [ ] Load testing

---

**Built with ❤️ using Terraform, Kubernetes, and DevSecOps best practices**

