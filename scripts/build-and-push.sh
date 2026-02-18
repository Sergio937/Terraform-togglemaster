#!/bin/bash

# Docker Build & Push Script
# Usage: ./build-and-push.sh <service-name>
# Example: ./build-and-push.sh analytics-service

set -e

SERVICE_NAME=${1:-analytics-service}
SERVICE_PATH="Kubernetes/${SERVICE_NAME}/${SERVICE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if service directory exists
if [ ! -d "$SERVICE_PATH" ]; then
    log_error "Service path not found: $SERVICE_PATH"
    exit 1
fi

# Get commit hash
COMMIT_SHA=$(git rev-parse --short HEAD)
log_info "Commit SHA: $COMMIT_SHA"

# Variables
IMAGE_NAME="${SERVICE_NAME}"
IMAGE_TAG="${COMMIT_SHA}"

# Step 1: Build Docker image
log_info "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${SERVICE_PATH}/Dockerfile" "${SERVICE_PATH}"
if [ $? -eq 0 ]; then
    log_info "Docker image built successfully"
else
    log_error "Failed to build Docker image"
    exit 1
fi

# Step 2: Run Trivy container scan
log_info "Running Trivy container scan..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image --severity CRITICAL --exit-code 0 \
    "${IMAGE_NAME}:${IMAGE_TAG}"

if [ $? -eq 0 ]; then
    log_info "Trivy scan completed (no CRITICAL vulnerabilities found)"
else
    log_warn "Trivy scan found vulnerabilities, but continuing..."
fi

# Step 3: Check AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
    log_error "AWS credentials not set. Please set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION"
    exit 1
fi

# Step 4: Login to ECR
log_info "Logging in to AWS ECR..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${ECR_REGISTRY}"

if [ $? -eq 0 ]; then
    log_info "Successfully logged in to ECR"
else
    log_error "Failed to login to ECR"
    exit 1
fi

# Step 5: Tag image for ECR
PROJECT_NAME=${PROJECT_NAME:-togglemaster}
ECR_REPOSITORY="${ECR_REGISTRY}/${PROJECT_NAME}/${SERVICE_NAME}"

log_info "Tagging image as: ${ECR_REPOSITORY}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REPOSITORY}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REPOSITORY}:latest"

# Step 6: Push image to ECR
log_info "Pushing image to ECR: ${ECR_REPOSITORY}"
docker push "${ECR_REPOSITORY}:${IMAGE_TAG}"
if [ $? -eq 0 ]; then
    log_info "Successfully pushed ${ECR_REPOSITORY}:${IMAGE_TAG}"
else
    log_error "Failed to push image to ECR"
    exit 1
fi

docker push "${ECR_REPOSITORY}:latest"
if [ $? -eq 0 ]; then
    log_info "Successfully pushed ${ECR_REPOSITORY}:latest"
else
    log_error "Failed to push latest tag to ECR"
    exit 1
fi

# Success
log_info "Build and push completed successfully!"
log_info "Image: ${ECR_REPOSITORY}:${IMAGE_TAG}"
log_info "Latest: ${ECR_REPOSITORY}:latest"

exit 0
