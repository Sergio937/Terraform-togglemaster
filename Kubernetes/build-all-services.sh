#!/bin/bash

AWS_REGION=$(aws configure get region)

if [ -z "$AWS_REGION" ]; then
  echo "❌ AWS region not configured. Run: aws configure"
  exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Namespace do Terraform
ECR_NAMESPACE="togglemaster"

GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
GIT_COMMIT=$(git rev-parse --short HEAD)
IMAGE_TAG="${GIT_TAG}-${GIT_COMMIT}"

echo "🏷️ Using tag: $IMAGE_TAG"
echo ""

SERVICES=(
  "analytics-service"
  "auth-service"
  "evaluation-service"
  "flag-service"
  "targeting-service"
)

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION \
| docker login --username AWS --password-stdin $ECR_REGISTRY

SUCCESS=0
FAILED=0

for SERVICE in "${SERVICES[@]}"; do

  echo ""
  echo "========================================"
  echo "🚀 Processing: $SERVICE"
  echo "========================================"

  DOCKERFILE_PATH=$(find ./$SERVICE -name Dockerfile | head -n 1)

  if [ -z "$DOCKERFILE_PATH" ]; then
    echo "❌ Dockerfile not found for $SERVICE"
    ((FAILED++))
    continue
  fi

  CONTEXT_PATH=$(dirname $DOCKERFILE_PATH)

  FULL_IMAGE_NAME="$ECR_REGISTRY/$ECR_NAMESPACE/$SERVICE:$IMAGE_TAG"
  FULL_IMAGE_LATEST="$ECR_REGISTRY/$ECR_NAMESPACE/$SERVICE:latest"

  # Build
  if ! docker build -t $SERVICE:$IMAGE_TAG -f $DOCKERFILE_PATH $CONTEXT_PATH; then
    echo "❌ Build failed for $SERVICE"
    ((FAILED++))
    continue
  fi

  # Tag
  docker tag $SERVICE:$IMAGE_TAG $FULL_IMAGE_NAME
  docker tag $SERVICE:$IMAGE_TAG $FULL_IMAGE_LATEST

  # Push
  if docker push $FULL_IMAGE_NAME && docker push $FULL_IMAGE_LATEST; then
      echo "✅ $SERVICE pushed successfully"
      ((SUCCESS++))
  else
      echo "❌ Push failed for $SERVICE"
      ((FAILED++))
  fi

done

echo ""
echo "========================================"
echo "📊 SUMMARY"
echo "========================================"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo "Tag used: $IMAGE_TAG"
echo "========================================"

if [ $FAILED -gt 0 ]; then
  exit 1
fi

echo "🎉 All services pushed to togglemaster namespace!"
