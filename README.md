# E-Commerce Website with ECS Fargate and CI/CD Pipeline - AWS Console Guide

This project demonstrates deploying an e-commerce website on AWS ECS Fargate with a complete CI/CD pipeline using AWS CodePipeline, CodeBuild, and CodeDeploy. All infrastructure is created using the AWS Management Console.

## Architecture Overview

- **VPC**: Custom Virtual Private Cloud with public/private subnets
- **ECS Fargate**: Serverless container platform
- **Application Load Balancer**: Traffic distribution and health checks
- **ECR**: Container registry for Docker images
- **CodePipeline**: Automated CI/CD pipeline
- **CodeBuild**: Build and test automation
- **CodeDeploy**: Blue/Green deployment strategy

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository for source code
- Docker knowledge (basic)
- AWS CLI installed and configured

## Step-by-Step Implementation Guide

### Phase 1: Network Infrastructure Setup

#### 1. Create VPC
1. Navigate to **VPC Console** → **Create VPC**
2. Choose **VPC and more**
3. Configure:
   - Name: `ecommerce-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - Number of AZs: `2`
   - Public subnets: `2`
   - Private subnets: `2`
   - NAT gateways: `1 per AZ`
   - VPC endpoints: `None`
4. Click **Create VPC**

#### 2. Create Security Groups
**ALB Security Group:**
1. Go to **EC2 Console** → **Security Groups** → **Create security group**
2. Configure:
   - Name: `ecommerce-alb-sg`
   - Description: `Security group for Application Load Balancer`
   - VPC: Select your `ecommerce-vpc`
   - Inbound rules:
     - Type: `HTTP`, Port: `80`, Source: `0.0.0.0/0`
     - Type: `HTTPS`, Port: `443`, Source: `0.0.0.0/0`
3. Click **Create security group**

**ECS Security Group:**
1. Create another security group:
   - Name: `ecommerce-ecs-sg`
   - Description: `Security group for ECS tasks`
   - VPC: Select your `ecommerce-vpc`
   - Inbound rules:
     - Type: `HTTP`, Port: `80`, Source: `ecommerce-alb-sg`
2. Click **Create security group**

### Phase 2: Container Registry Setup

#### 3. Create ECR Repository
1. Navigate to **ECR Console** → **Create repository**
2. Configure:
   - Visibility: `Private`
   - Repository name: `web-app`
   - Tag immutability: `Mutable`
   - Scan on push: `Enabled`
3. Click **Create repository**
4. Note the repository URI for later use

### Phase 3: Load Balancer Setup

#### 4. Create Application Load Balancer
1. Go to **EC2 Console** → **Load Balancers** → **Create Load Balancer**
2. Choose **Application Load Balancer**
3. Configure:
   - Name: `ecommerce-alb`
   - Scheme: `Internet-facing`
   - IP address type: `IPv4`
   - VPC: Select `ecommerce-vpc`
   - Mappings: Select both public subnets
   - Security groups: Select `ecommerce-alb-sg`
4. Configure Listeners:
   - Protocol: `HTTP`, Port: `80`
   - Default action: `Create target group`

#### 5. Create Target Groups
**Blue Target Group:**
1. In the ALB creation process, create target group:
   - Name: `ecommerce-blue-tg`
   - Target type: `IP addresses`
   - Protocol: `HTTP`, Port: `80`
   - VPC: Select `ecommerce-vpc`
   - Health check path: `/`
2. Complete ALB creation

**Green Target Group:**
1. After ALB creation, go to **Target Groups** → **Create target group**
2. Configure:
   - Name: `ecommerce-green-tg`
   - Target type: `IP addresses`
   - Protocol: `HTTP`, Port: `80`
   - VPC: Select `ecommerce-vpc`
   - Health check path: `/`

### Phase 4: ECS Setup

#### 6. Create ECS Cluster
1. Navigate to **ECS Console** → **Clusters** → **Create Cluster**
2. Configure:
   - Cluster name: `ecommerce-cluster`
   - Infrastructure: `AWS Fargate (serverless)`
   - Monitoring: Enable `Container Insights`
3. Click **Create**

#### 7. Create Task Definition
1. Go to **ECS Console** → **Task Definitions** → **Create new task definition**
2. Configure:
   - Task definition family: `ecommerce-task`
   - Launch type: `AWS Fargate`
   - Operating system: `Linux/X86_64`
   - CPU: `0.25 vCPU`
   - Memory: `0.5 GB`
   - Task role: `Create new role` (if needed)
   - Task execution role: `Create new role`

3. Container Definition:
   - Container name: `web-app`
   - Image URI: `[YOUR-ECR-URI]:latest`
   - Port mappings: `80` (HTTP)
   - Log configuration:
     - Log driver: `awslogs`
     - Log group: `/ecs/ecommerce-app`
     - Region: Your AWS region
     - Stream prefix: `ecs`

#### 8. Create ECS Service
1. In **ECS Console** → **Clusters** → Select `ecommerce-cluster`
2. **Services** tab → **Create**
3. Configure:
   - Launch type: `Fargate`
   - Task Definition: `ecommerce-task`
   - Service name: `ecommerce-service`
   - Number of tasks: `2`
   - Minimum healthy percent: `50`
   - Maximum percent: `200`

4. Network Configuration:
   - VPC: Select `ecommerce-vpc`
   - Subnets: Select private subnets
   - Security groups: Select `ecommerce-ecs-sg`
   - Auto-assign public IP: `Disabled`

5. Load Balancer:
   - Load balancer type: `Application Load Balancer`
   - Load balancer: Select `ecommerce-alb`
   - Container to load balance: `web-app:80`
   - Target group: Select `ecommerce-blue-tg`

### Phase 5: Testing CI/CD Components (Before Full Pipeline)

#### 9. Create IAM Roles

**CodeBuild Service Role:**
1. Go to **IAM Console** → **Roles** → **Create role**
2. Select **AWS service** → **CodeBuild**
3. Attach policies:
   - `AmazonEC2ContainerRegistryPowerUser`
   - `CloudWatchLogsFullAccess`
4. Name: `CodeBuildServiceRole`

**CodeDeploy Service Role:**
1. Create another role for **CodeDeploy**
2. Attach policy: `AWSCodeDeployRoleForECS`
3. Name: `CodeDeployServiceRole`

#### 10. Test CodeBuild First
1. Navigate to **CodeBuild Console** → **Create build project**
2. Configure:
   - Project name: `ecommerce-build`
   - Source provider: `GitHub`
   - Repository: Connect your GitHub repo
   - Environment:
     - Environment image: `Managed image`
     - Operating system: `Amazon Linux 2`
     - Runtime: `Standard`
     - Image: `aws/codebuild/amazonlinux2-x86_64-standard:3.0`
     - Privileged: `Enabled` (for Docker)
   - Service role: Select `CodeBuildServiceRole`
   - Buildspec: Use `buildspec.yml` in source root

3. **Test Build:**
   - Click **Start build**
   - Monitor build logs
   - Verify image is pushed to ECR
   - Check build artifacts

#### 11. Create CodeDeploy Application
1. Go to **CodeDeploy Console** → **Applications** → **Create application**
2. Configure:
   - Application name: `ecommerce-app`
   - Compute platform: `Amazon ECS`

3. Create Deployment Group:
   - Deployment group name: `ecommerce-deployment-group`
   - Service role: Select `CodeDeployServiceRole`
   - ECS cluster name: `ecommerce-cluster`
   - ECS service name: `ecommerce-service`
   - Load balancer: Select `ecommerce-alb`
   - Production listener: `HTTP:80`
   - Target groups: Blue: `ecommerce-blue-tg`, Green: `ecommerce-green-tg`

4. **Test Deployment:**
   - Create a deployment manually
   - Use the task definition from CodeBuild artifacts
   - Monitor blue/green deployment process
   - Verify traffic switching

### Phase 6: Full CI/CD Pipeline Setup

#### 12. Create CodePipeline (After Testing Above)

**CodePipeline Service Role:**
1. Create role for **CodePipeline**
2. Attach policies:
   - `AWSCodePipelineServiceRole`
   - Custom policies for S3, CodeBuild, CodeDeploy access
3. Name: `CodePipelineServiceRole`

#### 13. Create CodePipeline
1. Navigate to **CodePipeline Console** → **Create pipeline**
2. Configure:
   - Pipeline name: `ecommerce-pipeline`
   - Service role: Select `CodePipelineServiceRole`

3. Source Stage:
   - Source provider: `GitHub (Version 2)`
   - Connection: Create new connection to GitHub
   - Repository: Select your repository
   - Branch: `main`

4. Build Stage:
   - Build provider: `AWS CodeBuild`
   - Project name: Select `ecommerce-build`

5. Deploy Stage:
   - Deploy provider: `Amazon ECS (Blue/Green)`
   - Application name: `ecommerce-app`
   - Deployment group: `ecommerce-deployment-group`

### Phase 7: Required Files Setup

#### 14. Create AppSpec File
Create `appspec.yaml` in your repository root:

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "web-app"
          ContainerPort: 80
        PlatformVersion: "LATEST"
```

#### 15. Update Task Definition Template
Update `infra/website_taskdef.tpl` to be a complete task definition JSON:

```json
{
  "family": "ecommerce-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::[ACCOUNT-ID]:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "web-app",
      "image": "<IMAGE1_URI>",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecommerce-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Phase 8: Initial Deployment

#### 16. Build and Push Initial Image
1. Build your Docker image locally:
```bash
cd infra/src
docker build -t web-app .
```

2. Tag and push to ECR:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ACCOUNT-ID].dkr.ecr.us-east-1.amazonaws.com
docker tag web-app:latest [ECR-URI]:latest
docker push [ECR-URI]:latest
```

#### 17. Test the Pipeline
1. Commit and push changes to your GitHub repository
2. Monitor the pipeline execution in CodePipeline console
3. Verify deployment in ECS console
4. Test the application via ALB DNS name

## Monitoring and Troubleshooting

### CloudWatch Logs
- ECS task logs: `/ecs/ecommerce-app`
- CodeBuild logs: Available in CodeBuild console

### Common Issues
1. **Task fails to start**: Check security groups and subnet routing
2. **Health check failures**: Verify application responds on port 80
3. **Pipeline failures**: Check IAM permissions and buildspec.yml

### Useful Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-service

# View task logs
aws logs get-log-events --log-group-name /ecs/ecommerce-app --log-stream-name [STREAM-NAME]

# Manual deployment trigger
aws codepipeline start-pipeline-execution --name ecommerce-pipeline
```

## Security Best Practices

1. Use least privilege IAM policies
2. Enable VPC Flow Logs
3. Use AWS Secrets Manager for sensitive data
4. Enable ALB access logs
5. Implement WAF for web application protection

## Cost Optimization

1. Use Fargate Spot for non-production workloads
2. Implement auto-scaling based on metrics
3. Use lifecycle policies for ECR images
4. Monitor costs with AWS Cost Explorer

## Next Steps

1. Add HTTPS/SSL certificate to ALB
2. Implement auto-scaling policies
3. Add monitoring and alerting
4. Set up backup strategies
5. Implement infrastructure as code for reproducibility

## Cleanup

To avoid ongoing charges, delete resources in reverse order:
1. CodePipeline
2. CodeDeploy application
3. CodeBuild project
4. ECS service and cluster
5. Load balancer and target groups
6. ECR repository
7. VPC and associated resources
