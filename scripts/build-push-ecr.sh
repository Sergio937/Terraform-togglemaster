#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-913430344673}"
REPOSITORY_PREFIX="${REPOSITORY_PREFIX:-togglemaster}"
TAG="${TAG:-v1.0.0}"
SERVICE="${SERVICE:-all}"
CREATE_MISSING_REPOSITORIES="${CREATE_MISSING_REPOSITORIES:-true}"
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --account-id)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    --repo-prefix)
      REPOSITORY_PREFIX="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --service)
      SERVICE="$2"
      shift 2
      ;;
    --create-missing-repositories)
      CREATE_MISSING_REPOSITORIES="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/build-push-ecr.sh [options]

Options:
  --region <aws-region>                     Default: us-east-1
  --account-id <aws-account-id>             Default: 913430344673
  --repo-prefix <prefix>                    Default: togglemaster
  --service <service-name|all>              Ex: auth-service (default: all)
  --tag <image-tag>                         Tag de versão (ex: v1.0.0). Default: v1.0.0
  --create-missing-repositories <true|false> Default: true

Positional mode (atalho):
  ./scripts/build-push-ecr.sh <service-name> <version-tag>
  Exemplo: ./scripts/build-push-ecr.sh auth-service v1.0.0

Environment variables (alternative):
  AWS_REGION, ACCOUNT_ID, REPOSITORY_PREFIX, TAG, CREATE_MISSING_REPOSITORIES
EOF
      exit 0
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  if [[ ${#POSITIONAL_ARGS[@]} -ne 2 ]]; then
    echo "Uso posicional inválido. Use: ./scripts/build-push-ecr.sh <service-name> <version-tag>"
    exit 1
  fi
  SERVICE="${POSITIONAL_ARGS[0]}"
  TAG="${POSITIONAL_ARGS[1]}"
fi

command -v aws >/dev/null 2>&1 || { echo "AWS CLI não encontrado."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker não encontrado."; exit 1; }

SERVICES=(
  "analytics-service:Kubernetes/analytics-service/analytics-service"
  "auth-service:Kubernetes/auth-service/auth-service"
  "evaluation-service:Kubernetes/evaluation-service/evaluation-service"
  "flag-service:Kubernetes/flag-service/flag-service"
  "targeting-service:Kubernetes/targeting-service/targeting-service"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Tag de versão: ${TAG}"
echo "Serviço selecionado: ${SERVICE}"

echo "Validando credenciais AWS..."
aws sts get-caller-identity >/dev/null

echo "Login no ECR: ${REGISTRY}"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"

if [[ "$SERVICE" != "all" ]]; then
  SERVICE_FOUND="false"
  for entry in "${SERVICES[@]}"; do
    if [[ "${entry%%:*}" == "$SERVICE" ]]; then
      SERVICE_FOUND="true"
      break
    fi
  done

  if [[ "$SERVICE_FOUND" != "true" ]]; then
    echo "Serviço inválido: ${SERVICE}"
    echo "Serviços válidos: analytics-service, auth-service, evaluation-service, flag-service, targeting-service"
    exit 1
  fi
fi

for entry in "${SERVICES[@]}"; do
  service_name="${entry%%:*}"
  service_path_rel="${entry##*:}"

  if [[ "$SERVICE" != "all" && "$service_name" != "$SERVICE" ]]; then
    continue
  fi

  repository_name="${REPOSITORY_PREFIX}/${service_name}"
  image_version="${REGISTRY}/${repository_name}:${TAG}"
  context_path="${REPO_ROOT}/${service_path_rel}"

  if [[ ! -d "$context_path" ]]; then
    echo "Contexto não encontrado para ${service_name}: ${context_path}"
    exit 1
  fi

  if [[ "$CREATE_MISSING_REPOSITORIES" == "true" ]]; then
    if ! aws ecr describe-repositories --region "$AWS_REGION" --repository-names "$repository_name" >/dev/null 2>&1; then
      echo "Criando repositório ECR: ${repository_name}"
      aws ecr create-repository \
        --region "$AWS_REGION" \
        --repository-name "$repository_name" \
        --image-tag-mutability MUTABLE \
        --image-scanning-configuration scanOnPush=true >/dev/null
    fi
  fi

  echo
  echo "=== BUILD ${service_name} ==="
  docker build -t "$image_version" "$context_path"

  echo "=== PUSH  ${service_name} ==="
  docker push "$image_version"
done

echo
echo "Concluído. Imagens publicadas somente com a tag '${TAG}'."
echo "Exemplo de validação:"
echo "aws ecr list-images --region ${AWS_REGION} --repository-name ${REPOSITORY_PREFIX}/analytics-service --query 'imageIds[*].imageTag'"
