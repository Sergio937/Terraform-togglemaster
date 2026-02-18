#!/bin/bash

# Build and Push All Services
# Usage: ./build-all-services.sh

set -e

SERVICES=(
    "analytics-service"
    "auth-service"
    "evaluation-service"
    "flag-service"
    "targeting-service"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if credentials are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
    log_error "AWS credentials not set. Please set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION"
    exit 1
fi

log_section "Building and Pushing All Services"

SUCCESSFUL=0
FAILED=0

for SERVICE in "${SERVICES[@]}"; do
    log_section "Processing: $SERVICE"
    
    if ./scripts/build-and-push.sh "$SERVICE"; then
        log_info "✓ $SERVICE completed successfully"
        ((SUCCESSFUL++))
    else
        log_error "✗ $SERVICE failed"
        ((FAILED++))
    fi
done

log_section "Summary"
echo -e "${GREEN}Successful: $SUCCESSFUL${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -gt 0 ]; then
    exit 1
else
    log_info "All services built and pushed successfully!"
    exit 0
fi
