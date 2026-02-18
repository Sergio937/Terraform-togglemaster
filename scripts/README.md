# Docker Build & Push Script

Script para fazer build e push de imagens Docker para AWS ECR com verificação de segurança.

## Pré-requisitos

- Docker instalado
- AWS CLI instalado
- Trivy instalado (para scanning de vulnerabilidades)
- AWS credentials configuradas

## Variáveis de Ambiente Necessárias

```bash
export AWS_ACCESS_KEY_ID=<sua-chave>
export AWS_SECRET_ACCESS_KEY=<sua-chave-secreta>
export AWS_REGION=us-east-1
export PROJECT_NAME=togglemaster  # Opcional, padrão é 'togglemaster'
```

## Uso

### Forma 1: Linha de comando

```bash
# Fazer build e push do analytics-service
./scripts/build-and-push.sh analytics-service

# Ou usar outro serviço
./scripts/build-and-push.sh auth-service
./scripts/build-and-push.sh evaluation-service
./scripts/build-and-push.sh flag-service
./scripts/build-and-push.sh targeting-service
```

### Forma 2: Com variáveis de ambiente

```bash
export AWS_ACCESS_KEY_ID=xxxxx
export AWS_SECRET_ACCESS_KEY=xxxxx
export AWS_REGION=us-east-1

./scripts/build-and-push.sh analytics-service
```

### Forma 3: Inline

```bash
AWS_ACCESS_KEY_ID=xxxxx AWS_SECRET_ACCESS_KEY=xxxxx AWS_REGION=us-east-1 ./scripts/build-and-push.sh analytics-service
```

## O que o script faz

1. **Build da imagem Docker**
   - Constrói a imagem com tag do commit hash (ex: v1.0.0-a1b2c3d)

2. **Trivy Container Scan**
   - Faz scanning de vulnerabilidades CRITICAL na imagem
   - Continua mesmo se houver vulnerabilidades (apenas avisa)

3. **Login no AWS ECR**
   - Autentica no ECR usando as credenciais AWS

4. **Push para ECR**
   - Faz push da imagem com a tag do commit hash
   - Faz push da tag `latest` também

## Saída Esperada

```
[INFO] Commit SHA: a1b2c3d
[INFO] Building Docker image: analytics-service:a1b2c3d
[INFO] Docker image built successfully
[INFO] Running Trivy container scan...
[INFO] Trivy scan completed (no CRITICAL vulnerabilities found)
[INFO] Logging in to AWS ECR...
[INFO] Successfully logged in to ECR
[INFO] Tagging image as: 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:a1b2c3d
[INFO] Pushing image to ECR: 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service
[INFO] Successfully pushed 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:a1b2c3d
[INFO] Successfully pushed 913430344673.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service:latest
[INFO] Build and push completed successfully!
```

## Troubleshooting

### "AWS credentials not set"
Certifique-se que as variáveis de ambiente estão configuradas:
```bash
export AWS_ACCESS_KEY_ID=xxxxx
export AWS_SECRET_ACCESS_KEY=xxxxx
export AWS_REGION=us-east-1
```

### "Service path not found"
Verifique se o nome do serviço está correto:
- analytics-service
- auth-service
- evaluation-service
- flag-service
- targeting-service

### "Failed to login to ECR"
Verifique se:
- As credenciais AWS estão corretas
- Você tem permissão para acessar ECR
- A região AWS está correta

## Como integrar no workflow

Se quiser usar esse script em um GitHub Actions workflow, adicione:

```yaml
- name: Build and Push to ECR
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION: ${{ secrets.AWS_REGION }}
    PROJECT_NAME: togglemaster
  run: |
    chmod +x ./scripts/build-and-push.sh
    ./scripts/build-and-push.sh ${{ matrix.service }}
```
