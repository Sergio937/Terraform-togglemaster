# ToggleMaster - Fase 03 FIAP

Sistema completo de gerenciamento de feature flags com arquitetura de microsserviços, infraestrutura como código (Terraform), Kubernetes (EKS), GitOps com ArgoCD e pipelines DevSecOps.

---

## 📋 Índice

- [Quick Start](#-quick-start-5-minutos)
- [Visão Geral](#-visão-geral)
- [Arquitetura](#️-arquitetura)
- [Microsserviços](#-microsserviços)
- [GitOps com ArgoCD](#-gitops-com-argocd)
- [Infraestrutura Terraform](#️-infraestrutura-terraform)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Comandos Úteis](#-comandos-úteis)
- [Troubleshooting](#-troubleshooting)

---

## ⚡ Quick Start (5 minutos)

### 1️⃣ Deploy da Infraestrutura

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 2️⃣ Build e Push das Imagens

```bash
# Configurar AWS CLI
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>
export AWS_DEFAULT_REGION=us-east-1

# Build e push para ECR
./scripts/build-all-services.sh
```

### 3️⃣ Instalar ArgoCD

```bash
# Configurar kubectl
aws eks update-kubeconfig --name togglemaster --region us-east-1

# Instalar ArgoCD
./gitops/argocd/install.sh

# Ou manualmente:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### 4️⃣ Obter Credenciais do ArgoCD

```bash
# Usando script auxiliar
./scripts/gitops-manager.sh credentials

# Ou manualmente
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl get svc argocd-server -n argocd
```

### 5️⃣ Deploy dos Serviços

```bash
# Deploy todos os serviços
./scripts/gitops-manager.sh deploy

# Verificar status
./scripts/gitops-manager.sh status
kubectl get pods -n togglemaster
```

** Pronto! Acesse o ArgoCD UI para monitorar seus serviços.**

---

##  Visão Geral

ToggleMaster é uma plataforma empresarial de feature flags que permite:
- ✅ Gerenciamento centralizado de feature flags
- ✅ Avaliação de flags em tempo real com cache Redis
- ✅ Targeting avançado de usuários e segmentação
- ✅ Analytics e monitoramento em tempo real
- ✅ Autenticação e autorização JWT
- ✅ Deploy automático com GitOps (ArgoCD)
- ✅ CI/CD completo com GitHub Actions
- ✅ Segurança integrada (Trivy, gosec, bandit)

---

##  Arquitetura

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

##  Microsserviços

### **1. Auth Service** (Go)
- **Porta:** 8001
- **Função:** Autenticação e geração de tokens JWT
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `POST /auth/login` - Login de usuários
  - `POST /auth/register` - Registro de novos usuários
  - `GET /auth/validate` - Validação de token

### **2. Flag Service** (Python)
- **Porta:** 8002
- **Função:** CRUD de feature flags
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `GET /flags` - Listar flags
  - `POST /flags` - Criar flag
  - `PUT /flags/:id` - Atualizar flag
  - `DELETE /flags/:id` - Deletar flag

### **3. Evaluation Service** (Go)
- **Porta:** 8004
- **Função:** Avaliação de flags para usuários
- **Cache:** Redis (ElastiCache)
- **Queue:** Amazon SQS (eventos de avaliação)
- **Endpoints:**
  - `POST /evaluate` - Avaliar flag para usuário
  - `GET /evaluate/bulk` - Avaliação em lote

### **4. Targeting Service** (Python)
- **Porta:** 8003
- **Função:** Regras de targeting de usuários
- **Database:** PostgreSQL (RDS)
- **Endpoints:**
  - `GET /targeting/rules` - Listar regras
  - `POST /targeting/rules` - Criar regra
  - `POST /targeting/match` - Verificar match de usuário

### **5. Analytics Service** (Python)
- **Porta:** 8005
- **Função:** Coleta e análise de eventos
- **Database:** DynamoDB
- **Queue Consumer:** Amazon SQS
- **Endpoints:**
  - `GET /analytics/stats` - Estatísticas de uso
  - `GET /analytics/events` - Eventos registrados
  - `POST /analytics/query` - Query customizada

---

##  Infraestrutura

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

##  CI/CD & DevSecOps

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

##  GitOps com ArgoCD

### **Arquitetura GitOps:**

```
Developer → GitHub → CI Pipeline → ECR
                ↓
          Update GitOps
                ↓
            ArgoCD ← monitors Git
                ↓
          Deploy to EKS
                ↓
     5 Microservices Running
```

### **Estrutura GitOps:**

```
gitops/
├── apps/                      # ArgoCD Applications
│   ├── analytics-service.yaml
│   ├── auth-service.yaml
│   ├── evaluation-service.yaml
│   ├── flag-service.yaml
│   └── targeting-service.yaml
│
├── manifests/                 # Kubernetes manifests (Single Source of Truth)
│   ├── namespace/
│   ├── ingress/
│   ├── analytics-service/
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── auth-service/
│   ├── evaluation-service/
│   ├── flag-service/
│   └── targeting-service/
│
└── argocd/
    ├── install.sh         # Instalação automatizada
    └── README.md
```

### **Fluxo de Deploy Automático:**

1. **Code Change**: Developer faz push de código para `main`
2. **CI Pipeline**: GitHub Actions executa build, test, security scans
3. **Image Build**: Docker image criada e enviada para ECR com tag SHA
4. **GitOps Update**: Workflow atualiza tag da imagem em `gitops/manifests/`
5. **ArgoCD Sync**: ArgoCD detecta mudança e sincroniza automaticamente
6. **Kubernetes Deploy**: ArgoCD aplica manifestos no cluster EKS
7. **Verification**: Health checks validam deploy bem-sucedido

### **Instalação do ArgoCD:**

```bash
# Via script (recomendado)
./gitops/argocd/install.sh

# Ou manualmente
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expor via LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obter senha
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Obter URL
kubectl get svc argocd-server -n argocd
```

### **Configurando ArgoCD Applications:**

Quando fizer push do repositório para GitHub, atualize as ArgoCD Applications:

```yaml
# gitops/apps/auth-service.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auth-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<seu-usuario>/<seu-repo>.git
    targetRevision: main
    path: gitops/manifests/auth-service
  destination:
    server: https://kubernetes.default.svc
    namespace: togglemaster
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Aplicar:
```bash
kubectl apply -f gitops/apps/
```

---

##  CI/CD Pipeline

### **Pipeline Stages:**

Cada microsserviço possui um pipeline completo:

```yaml
jobs:
  build_test:    # Build, compile, test
  lint:          # Code quality (flake8/golangci-lint)
  security:      # Security scans (gosec/bandit + Trivy)
  push_ecr:      # Build image → Push to ECR
  update_gitops: # Update image tag in GitOps → Triggers ArgoCD
```

### **Exemplo de Commit Automático:**

Após push de código, o pipeline:
1. Faz build da imagem com tag SHA (ex: `abc1234`)
2. Push para ECR
3. Atualiza automaticamente `gitops/manifests/auth-service/deployment.yaml`:
   ```yaml
   image: 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:abc1234
   ```
4. Faz commit: ` Update auth-service image to abc1234`
5. ArgoCD detecta e faz deploy automático

### **Security Layers:**

1. **Linting:** flake8 (Python), golangci-lint (Go)
2. **SAST:** bandit (Python), gosec (Go)
3. **SCA:** Trivy filesystem scan
4. **Container Security:** Trivy image scan
5. **Blocking:** Pipeline fails on CRITICAL vulnerabilities

---

##  Comandos Úteis

### **Script GitOps Manager:**

```bash
# Configurar kubeconfig
./scripts/gitops-manager.sh configure

# Ver credenciais do ArgoCD
./scripts/gitops-manager.sh credentials

# Ver status do cluster e serviços
./scripts/gitops-manager.sh status

# Deploy todos os serviços
./scripts/gitops-manager.sh deploy

# Ver logs de um serviço
./scripts/gitops-manager.sh logs auth-service

# Reiniciar um serviço
./scripts/gitops-manager.sh restart auth-service

# Recriar ECR secret
./scripts/gitops-manager.sh ecr-secret

# Port-forward ArgoCD para localhost
./scripts/gitops-manager.sh port-forward
```

### **Kubectl Direto:**

```bash
# Ver pods
kubectl get pods -n togglemaster

# Ver todos os recursos
kubectl get all -n togglemaster

# Ver logs
kubectl logs -n togglemaster -l app=auth-service --tail=50

# Logs em tempo real
kubectl logs -f -n togglemaster deployment/auth-service

# Descrever pod
kubectl describe pod <pod-name> -n togglemaster

# Executar comando em pod
kubectl exec -it <pod-name> -n togglemaster -- sh

# Port-forward para um serviço
kubectl port-forward -n togglemaster svc/auth-service 8001:8001

# Ver eventos
kubectl get events -n togglemaster --sort-by='.lastTimestamp'

# Ver configurações
kubectl get configmap -n togglemaster
kubectl get secret -n togglemaster

# Escalar deployment
kubectl scale deployment/auth-service --replicas=3 -n togglemaster

# Ver HPA
kubectl get hpa -n togglemaster
```

### **Build e Deploy:**

```bash
# Build todas as imagens e push para ECR
./scripts/build-all-services.sh

# Build um serviço específico
cd Kubernetes/auth-service/auth-service
docker build -t auth-service:latest .

# Login no ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  913430344673.dkr.ecr.us-east-1.amazonaws.com

# Tag e push
docker tag auth-service:latest \
  913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:latest
docker push 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service:latest
```

### **Terraform:**

```bash
# Ver outputs
cd terraform
terraform output

# Ver outputs em JSON
terraform output -json

# Ver estado
terraform state list

# Refresh state
terraform refresh

# Plan com target específico
terraform plan -target=aws_eks_cluster.main

# Apply com auto-approve
terraform apply -auto-approve
```

### **Monitoramento:**

```bash
# Ver recursos consumidos
kubectl top nodes
kubectl top pods -n togglemaster

# Métricas de um pod específico
kubectl describe pod <pod-name> -n togglemaster | grep -A 5 "Limits\|Requests"

# Ver status de health
kubectl get pods -n togglemaster -o wide

# Restart deployment (recreate pods)
kubectl rollout restart deployment/auth-service -n togglemaster

# Ver histórico de rollouts
kubectl rollout history deployment/auth-service -n togglemaster

# Rollback
kubectl rollout undo deployment/auth-service -n togglemaster
```

---

## 🔍 Troubleshooting

### **Pods em CrashLoopBackOff:**

**Causa Comum**: Problemas de conectividade com RDS/Redis/SQS

```bash
# Ver logs do pod
kubectl logs -n togglemaster <pod-name>

# Verificar eventos
kubectl describe pod <pod-name> -n togglemaster

# Exemplo de erro: "no pg_hba.conf entry"
# Solução: Ajustar security group do RDS para permitir tráfego do EKS
```

**Solução para RDS:**
1. Obter security group dos nodes do EKS:
   ```bash
   aws eks describe-cluster --name togglemaster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId"
   ```
2. Adicionar ingress rule no security group do RDS permitindo tráfego da porta 5432 do security group do EKS

### **ImagePullBackOff:**

**Causa**: Problema ao puxar imagem do ECR

```bash
# Verificar secret
kubectl get secret ecr-secret -n togglemaster -o yaml

# Recriar secret
kubectl delete secret ecr-secret -n togglemaster
kubectl create secret docker-registry ecr-secret \
  --docker-server=913430344673.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=togglemaster

# Ou usar o script
./scripts/gitops-manager.sh ecr-secret
```

### **Serviço não responde:**

```bash
# Verificar se o pod está rodando
kubectl get pods -n togglemaster -l app=<service-name>

# Verificar service
kubectl get svc -n togglemaster <service-name>

# Testar conectividade interna
kubectl run -it --rm debug --image=busybox --restart=Never -n togglemaster -- sh
wget -O- http://auth-service:8001/health

# Reiniciar deployment
./scripts/gitops-manager.sh restart <service-name>
```

### **ArgoCD não sincroniza:**

```bash
# Verificar status da aplicação
kubectl get applications -n argocd

# Ver detalhes
kubectl describe application auth-service -n argocd

# Forçar sincronização (se usando ArgoCD CLI)
argocd app sync auth-service

# Ou via UI: Clicar em "Sync" → "Synchronize"
```

### **Erro de permissão AWS:**

```bash
# Verificar credenciais AWS
aws sts get-caller-identity

# Verificar se tem acesso ao ECR
aws ecr describe-repositories --region us-east-1

# Verificar se tem acesso ao EKS
aws eks describe-cluster --name togglemaster --region us-east-1
```

### **Pod fica em Pending:**

```bash
# Ver por que está pending
kubectl describe pod <pod-name> -n togglemaster

# Causas comuns:
# - Recursos insuficientes: Aumentar nodes ou reduzir requests
# - ImagePullBackOff: Ver seção acima
# - PVC não bound: Verificar PersistentVolumeClaims
```

### **Logs úteis para debug:**

```bash
# Logs do kubelet (nos workers)
kubectl logs -n kube-system -l component=kubelet

# Logs do scheduler
kubectl logs -n kube-system -l component=kube-scheduler

# Logs do controller manager
kubectl logs -n kube-system -l component=kube-controller-manager

# Eventos do cluster
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```
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

