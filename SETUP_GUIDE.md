# Quick Setup Guide - E-Commerce ECS CI/CD Pipeline

## Project Status Check

✅ **Files Present:**
- Application source code (`infra/src/`)
- Dockerfile for containerization
- buildspec.yml for CodeBuild
- ECS task definition template
- AppSpec file for CodeDeploy
- Task definition JSON
- Deployment script

## Missing Components (To Create via AWS Console)

### 1. Infrastructure Components
- [ ] VPC with public/private subnets
- [ ] Security Groups (ALB and ECS)
- [ ] ECR Repository
- [ ] Application Load Balancer
- [ ] Target Groups (Blue/Green)
- [ ] ECS Cluster
- [ ] CloudWatch Log Group

### 2. CI/CD Components
- [ ] IAM Roles (CodeBuild, CodeDeploy, CodePipeline)
- [ ] CodeBuild Project
- [ ] CodeDeploy Application
- [ ] CodePipeline

## Quick Start Steps

### Step 1: Initial Image Build (Optional)
Run the deployment script to build and push your first image:
```bash
./deploy.sh
```

### Step 2: Follow README Instructions
Follow the detailed step-by-step guide in `README.md` to create all AWS resources via the Management Console.

### Step 3: Key Configuration Points
- Update `taskdef.json` with your actual AWS Account ID
- Ensure ECR repository name matches in buildspec.yml
- Configure GitHub connection in CodePipeline
- Set up proper IAM permissions

## Important Notes

1. **Account ID**: Update `192018386876` with your actual AWS Account ID in:
   - `buildspec.yml`
   - `taskdef.json`
   - `deploy.sh`

2. **Region**: All configurations are set for `us-east-1`. Change if using different region.

3. **Repository**: Ensure your GitHub repository is properly connected to CodePipeline.

## Troubleshooting

### Common Issues:
1. **ECR Login Failed**: Check AWS CLI configuration and permissions
2. **Docker Build Failed**: Ensure Docker is running and Dockerfile is correct
3. **ECS Task Won't Start**: Check security groups and subnet configuration
4. **Pipeline Fails**: Verify IAM roles have proper permissions

### Useful Commands:
```bash
# Check AWS CLI configuration
aws sts get-caller-identity

# Test Docker build locally
cd infra/src && docker build -t test-app .

# Check ECR repositories
aws ecr describe-repositories --region us-east-1
```

## Next Steps After Setup

1. Test the application via ALB DNS name
2. Make a code change and push to GitHub
3. Monitor the CI/CD pipeline execution
4. Verify blue/green deployment works
5. Set up monitoring and alerting
