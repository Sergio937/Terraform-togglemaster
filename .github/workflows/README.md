# CI/CD Pipelines - GitHub Actions

Este diretório contém os workflows de CI/CD para os 5 microsserviços do projeto ToggleMaster.

## 📋 Workflows Implementados

### 1. **analytics-service.yml** (Python)
### 2. **auth-service.yml** (Go)
### 3. **evaluation-service.yml** (Go)
### 4. **flag-service.yml** (Go/Python)
### 5. **targeting-service.yml** (Python)

---

## 🔄 Pipeline Stages

Cada pipeline contém os seguintes estágios (jobs):

### **Job 1: Build & Unit Test**
- Checkout do código
- Setup do ambiente (Python 3.11 ou Go 1.22.x)
- Instalação de dependências
- Compilação do código
- Execução de testes unitários (se existirem)
- Build da imagem Docker para validação

**Triggers:** Pull Request e Push na branch `main`

---

### **Job 2: Linter / Static Analysis**
- **Python:** `flake8` - Análise de código Python (PEP 8 compliance)
- **Go:** `golangci-lint` - Suite completa de linters para Go

**Depends on:** `build_test`

---

### **Job 3: Security Scan (SAST & SCA)**

#### **SAST (Static Application Security Testing)**
- **Python:** `bandit` - Detecta vulnerabilidades no código Python (apenas HIGH/CRITICAL)
- **Go:** `gosec` - Análise de segurança para código Go (apenas HIGH severity)

#### **SCA (Software Composition Analysis)**
- **Trivy FS Scan** - Analisa vulnerabilidades em dependências
  - Scan Type: `fs` (filesystem)
  - Severity: `CRITICAL`
  - **Exit Code: 1** ⚠️ Pipeline falha se encontrar vulnerabilidades críticas

**Depends on:** `lint`

---

### **Job 4: Docker Build & Push**

#### **Condições de Execução:**
- ✅ Only runs on: `push` to `main` branch
- ✅ Não executa em Pull Requests

#### **Steps:**
1. **Build da Imagem Docker**
   - Tag com commit SHA (7 caracteres)
   - Tag `latest`

2. **Container Security Scan**
   - **Trivy Image Scan** - Scan da imagem Docker construída
   - Severity: `CRITICAL`
   - **Exit Code: 1** ⚠️ Pipeline falha se encontrar vulnerabilidades críticas na imagem

3. **Login no AWS ECR**
   - Usa credenciais AWS dos Secrets

4. **Push para ECR**
   - Push da imagem com tag do commit: `<service>:<commit-sha>`
   - Push da imagem com tag latest: `<service>:latest`

5. **Update GitOps Manifest**
   - Atualiza automaticamente o arquivo `deployment.yaml` no diretório `gitops/manifests/`
   - Commit e push das mudanças
   - Permite GitOps automation com ArgoCD

**Depends on:** `security`

---

## 🔐 Required GitHub Secrets

Configure os seguintes secrets no repositório GitHub:

```
AWS_ACCESS_KEY_ID       # AWS Access Key ID
AWS_SECRET_ACCESS_KEY   # AWS Secret Access Key
AWS_REGION              # AWS Region (ex: us-east-1)
AWS_ACCOUNT_ID          # AWS Account ID (ex: 913430344673)
PROJECT_NAME            # Nome do projeto (ex: togglemaster)
```

### Como adicionar secrets:
1. Vá para **Settings** → **Secrets and variables** → **Actions**
2. Clique em **New repository secret**
3. Adicione cada secret listado acima

---

## 🛡️ Security Features

### **Bloqueio de Vulnerabilidades Críticas**
Os pipelines implementam **security gates** que bloqueiam o deploy se:
- ❌ Vulnerabilidades **CRITICAL** forem encontradas nas dependências (SCA)
- ❌ Vulnerabilidades **CRITICAL** forem encontradas na imagem Docker

### **Ferramentas de Segurança:**
- **Trivy** - Vulnerability scanner (SCA + Container Scan)
- **Bandit** - Python security linter (SAST)
- **Gosec** - Go security checker (SAST)
- **golangci-lint** - Inclui múltiplos security linters para Go
- **flake8** - Python code quality

---

## 📦 ECR Image Tagging Strategy

As imagens são publicadas com duas tags:

1. **Commit-based tag:** `<commit-sha>` (7 caracteres)
   - Exemplo: `a1b2c3d`
   - Permite rastreabilidade e rollback preciso

2. **Latest tag:** `latest`
   - Sempre aponta para a última versão em produção

**Exemplo de imagem no ECR:**
```
913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:a1b2c3d
913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:latest
```

---

## 🚀 Como os Workflows são Acionados

### **Pull Request:**
```
git checkout -b feature/minha-feature
git add .
git commit -m "feat: nova funcionalidade"
git push origin feature/minha-feature
# Crie um Pull Request no GitHub
```
**Executa:** Jobs `build_test`, `lint`, e `security`  
**NÃO executa:** `docker_build_push`

### **Push para Main:**
```
git checkout main
git merge feature/minha-feature
git push origin main
```
**Executa:** TODOS os jobs incluindo `docker_build_push`

---

## 📊 Pipeline Flow Diagram

```
┌─────────────────┐
│  Push/PR Event  │
└────────┬────────┘
         │
         v
┌────────────────────┐
│  1. Build & Test   │
│  - Compile         │
│  - Unit Tests      │
│  - Docker Build    │
└────────┬───────────┘
         │
         v
┌────────────────────┐
│  2. Linter         │
│  - flake8/golint   │
└────────┬───────────┘
         │
         v
┌────────────────────┐
│  3. Security Scan  │
│  - SAST (bandit)   │
│  - SCA (trivy fs)  │
│  ⚠️  Fail on CRIT  │
└────────┬───────────┘
         │
         v (only on main)
┌────────────────────┐
│  4. Docker & Push  │
│  - Build Image     │
│  - Trivy Scan      │
│  ⚠️  Fail on CRIT  │
│  - ECR Push        │
│  - GitOps Update   │
└────────────────────┘
```

---

## 🎯 Best Practices Implementadas

✅ **Separation of Concerns** - Jobs separados para cada responsabilidade  
✅ **Security First** - Múltiplas camadas de security scanning  
✅ **Fail Fast** - Pipeline falha imediatamente em vulnerabilidades críticas  
✅ **Immutable Tags** - Usa commit hash para versionamento preciso  
✅ **GitOps Ready** - Atualização automática dos manifests após deploy  
✅ **Parallel Execution** - Jobs independentes rodam em paralelo quando possível  
✅ **Version Pinning** - Actions usam versões específicas (@v4, @v5)  
✅ **Working Directory** - Isolamento correto de cada microsserviço  

---

## 🔧 Troubleshooting

### Pipeline falhou no Security Scan
- Verifique os logs do Trivy/Bandit/Gosec
- Atualize as dependências vulneráveis
- Ou adicione exceções temporárias (não recomendado)

### Falha no Push para ECR
- Verifique se os secrets AWS estão configurados
- Confirme as permissões IAM para ECR
- Verifique se o repositório ECR existe

### Testes falhando
- Execute os testes localmente primeiro: `pytest` ou `go test ./...`
- Verifique dependências no `requirements.txt` ou `go.mod`

---

## 📝 Manutenção

Para adicionar um novo microsserviço:
1. Copie um workflow existente do mesmo tipo (Python/Go)
2. Ajuste os nomes e caminhos (`working-directory`)
3. Adicione o repositório ECR no Terraform
4. Commit e teste com um PR

---

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [golangci-lint](https://golangci-lint.run/)
- [Bandit](https://bandit.readthedocs.io/)
