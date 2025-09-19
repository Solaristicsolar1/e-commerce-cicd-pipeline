#!/bin/bash

# E-Commerce ECS Deployment Script
# This script helps with initial Docker image build and push to ECR

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="192018386876"
ECR_REPOSITORY_NAME="web-app"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting E-Commerce ECS Deployment...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Login to ECR
echo -e "${YELLOW}Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
cd infra/src
docker build -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .

# Tag image for ECR
REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME
docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $REPOSITORY_URI:$IMAGE_TAG

# Push image to ECR
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $REPOSITORY_URI:$IMAGE_TAG

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Image URI: $REPOSITORY_URI:$IMAGE_TAG${NC}"
echo -e "${YELLOW}You can now create your ECS service using this image.${NC}"
