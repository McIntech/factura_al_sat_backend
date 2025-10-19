#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying FiscalAPI to AWS App Runner...${NC}"

# Variables - Actualizadas según tu configuración actual de App Runner
AWS_REGION="${AWS_REGION:-us-east-2}"
REPO_NAME="${REPO_NAME:-factura_al_sat}"

# Get AWS Account ID
echo -e "${YELLOW}📋 Getting AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo -e "${RED}❌ Failed to get AWS Account ID. Is AWS CLI configured?${NC}"
  exit 1
fi
echo -e "${GREEN}✓ AWS Account: $AWS_ACCOUNT_ID${NC}"

# Setup variables
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG="$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')"
FULL_IMAGE="${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"

# Build Docker image
echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t ${REPO_NAME}:${IMAGE_TAG} .
echo -e "${GREEN}✓ Docker image built successfully${NC}"

# Tag images
echo -e "${YELLOW}🏷️  Tagging images...${NC}"
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${REPO_NAME}:latest
echo -e "${GREEN}✓ Images tagged${NC}"

# Login to ECR
echo -e "${YELLOW}🔐 Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}
echo -e "${GREEN}✓ Logged in to ECR${NC}"

# Skip repository check - assume it exists
echo -e "${GREEN}✓ Using existing ECR repository${NC}"

# Push to ECR
echo -e "${YELLOW}⬆️  Pushing images to ECR...${NC}"
docker push ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${REPO_NAME}:latest
echo -e "${GREEN}✓ Images pushed successfully${NC}"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "📦 Image: ${FULL_IMAGE}"
echo -e "🏷️  Tag: ${IMAGE_TAG}"
echo ""
echo -e "${YELLOW}ℹ️  If you have auto-deploy enabled in App Runner,${NC}"
echo -e "${YELLOW}   your service will automatically update.${NC}"
echo ""
echo -e "${YELLOW}📝 To manually trigger a deployment:${NC}"
echo "   aws apprunner start-deployment --service-arn <YOUR_SERVICE_ARN>"
echo ""
