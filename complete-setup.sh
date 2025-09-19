#!/bin/bash

# E-Commerce CI/CD Pipeline Complete Setup Script
# This script creates all necessary AWS resources for the project

set -e

# Configuration
REGION="us-east-1"
ACCOUNT_ID="192018386876"
VPC_ID="vpc-00a47217f21912f66"  # CI/CD demo-vpc
ECR_REPO="web-app"
CLUSTER_NAME="ecommerce-cluster"
SERVICE_NAME="ecommerce-service"
TASK_FAMILY="ecommerce-task"

echo "🚀 Starting E-Commerce CI/CD Pipeline Setup..."

# 1. Create CloudWatch Log Group
echo "📝 Creating CloudWatch Log Group..."
aws logs create-log-group \
    --log-group-name "/ecs/ecommerce-app" \
    --region $REGION || echo "Log group already exists"

# 2. Get VPC subnets
echo "🔍 Getting VPC subnet information..."
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' \
    --output text \
    --region $REGION)

PUBLIC_SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
    --query 'Subnets[*].SubnetId' \
    --output text \
    --region $REGION)

PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=false" \
    --query 'Subnets[*].SubnetId' \
    --output text \
    --region $REGION)

echo "Public subnets: $PUBLIC_SUBNETS"
echo "Private subnets: $PRIVATE_SUBNETS"

# 3. Create Security Groups
echo "🔒 Creating Security Groups..."

# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name "ecommerce-alb-sg" \
    --description "Security group for Application Load Balancer" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=ecommerce-alb-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' \
    --output text \
    --region $REGION)

# Add rules to ALB Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "HTTP rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "HTTPS rule already exists"

# ECS Security Group
ECS_SG_ID=$(aws ec2 create-security-group \
    --group-name "ecommerce-ecs-sg" \
    --description "Security group for ECS tasks" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=ecommerce-ecs-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' \
    --output text \
    --region $REGION)

# Add rule to ECS Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG_ID \
    --protocol tcp \
    --port 80 \
    --source-group $ALB_SG_ID \
    --region $REGION 2>/dev/null || echo "ECS rule already exists"

echo "ALB Security Group: $ALB_SG_ID"
echo "ECS Security Group: $ECS_SG_ID"

# 4. Create Target Groups
echo "🎯 Creating Target Groups..."

# Blue Target Group
BLUE_TG_ARN=$(aws elbv2 create-target-group \
    --name "ecommerce-blue-tg" \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path "/" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names "ecommerce-blue-tg" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION)

# Green Target Group
GREEN_TG_ARN=$(aws elbv2 create-target-group \
    --name "ecommerce-green-tg" \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path "/" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names "ecommerce-green-tg" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION)

echo "Blue Target Group: $BLUE_TG_ARN"
echo "Green Target Group: $GREEN_TG_ARN"

# 5. Create Application Load Balancer
echo "⚖️ Creating Application Load Balancer..."

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name "ecommerce-alb" \
    --subnets $PUBLIC_SUBNETS \
    --security-groups $ALB_SG_ID \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws elbv2 describe-load-balancers \
    --names "ecommerce-alb" \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region $REGION)

# Create Listener
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$BLUE_TG_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text \
    --region $REGION 2>/dev/null || \
    aws elbv2 describe-listeners \
    --load-balancer-arn $ALB_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text \
    --region $REGION)

echo "Load Balancer: $ALB_ARN"
echo "Listener: $LISTENER_ARN"

# 6. Create ECS Cluster
echo "🐳 Creating ECS Cluster..."
aws ecs create-cluster \
    --cluster-name $CLUSTER_NAME \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --region $REGION 2>/dev/null || echo "Cluster already exists"

# 7. Register Task Definition
echo "📋 Registering Task Definition..."
TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://taskdef.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text \
    --region $REGION)

echo "Task Definition: $TASK_DEF_ARN"

# 8. Create ECS Service
echo "🚀 Creating ECS Service..."

# Use first private subnet for service
FIRST_PRIVATE_SUBNET=$(echo $PRIVATE_SUBNETS | cut -d' ' -f1)
SECOND_PRIVATE_SUBNET=$(echo $PRIVATE_SUBNETS | cut -d' ' -f2)

aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$FIRST_PRIVATE_SUBNET,$SECOND_PRIVATE_SUBNET],securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$BLUE_TG_ARN,containerName=web-app,containerPort=80" \
    --region $REGION 2>/dev/null || echo "Service already exists"

# 9. Get ALB DNS Name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region $REGION)

echo ""
echo "✅ Setup Complete!"
echo "🌐 Your application will be available at: http://$ALB_DNS"
echo ""
echo "📊 Resource Summary:"
echo "- VPC: $VPC_ID"
echo "- ALB Security Group: $ALB_SG_ID"
echo "- ECS Security Group: $ECS_SG_ID"
echo "- Blue Target Group: $BLUE_TG_ARN"
echo "- Green Target Group: $GREEN_TG_ARN"
echo "- Load Balancer: $ALB_ARN"
echo "- ECS Cluster: $CLUSTER_NAME"
echo "- ECS Service: $SERVICE_NAME"
echo ""
echo "⏳ Wait 5-10 minutes for the service to become healthy, then visit the URL above."
