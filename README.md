# E-Commerce Website with ECS and CI/CD Pipeline

In today’s digital landscape, delivering a scalable, resilient, and automated platform for your e-commerce business is key to staying competitive. This project demonstrates a complete, enterprise-grade approach to deploying an e-commerce website on AWS ECS Fargate — a serverless container platform — alongside Application Load Balancer (ALB), a custom VPC, and Docker containers sourced from Amazon Elastic Container Registry (ECR).

To enable a smooth and reliable delivery pipeline, we’ve implemented AWS CodePipeline, which is triggered directly by code pushes to a Github repository. This automated pipeline handles everything from building your container images to safely rolling out your application to production — with blue/green deployments to enable zero-downtime updates. All the underlying infrastructure — from networks to load balancing and ECS clusters — is provisioned and managed end-to-end using Terraform as Infrastructure as Code (IaC), ensuring your stack is reproducible, auditable, and easy to modify.

In this article, we’ll walk you through each step of this architecture, explain its key components, and show you how you can deploy a scalable, containerized e-commerce platform with confidence, ease, and operational excellence.

## Project Architecture

<p align="center">
<img src="https://i.imgur.com/PJ4eSIE.png" height="80%" width="80%" alt="Disk Sanitization Steps"/>
<br />
  
## Infrastructure Components

- **VPC**: Isolated network with public and private subnets
- **ECS Cluster**: Fargate-based container hosting
- **ALB**: Load balancer for routing traffic
- **ECR**: Container registry for Docker images
- **CodePipeline**: Orchestrates the CI/CD workflow
- **CodeBuild**: Builds Docker images
- **CodeDeploy**: Deploys to ECS with blue/green strategy

## How it Works

The architecture is designed to enable continuous delivery with zero-downtime deployments while retaining complete control over your stack through Infrastructure as Code. Here’s a step-by-step walkthrough of how everything works together:

- **Developer Pushes Code to GitHub**: The pipeline starts when a developer pushes a new code change to the application’s GitHub repository (typically to the main or master branch).
- **Source Capture by CodePipeline**: AWS CodePipeline is configured to track this repository. Once a new commit is made, CodePipeline is triggered, retrieving the updated code for processing.
- **Docker Image Build and Push to ECR**: CodeBuild, integrated into the pipeline, builds a new Docker image from your application’s source code. This image is then pushed to Amazon Elastic Container Registry (ECR), a fully managed container image repository.

- **Infrastructure Managed by Terraform**: All related AWS resources — VPC, ECS Cluster, Application Load Balancer, Security Groups, Auto Scaling configuration, and more — are defined and deployed using Terraform. This guarantees a consistent, auditable, and reproducible environment across stages (development, staging, production).

- **Blue/Green Deployment with ECS and ALB**: ECS Fargate runs your container workloads in tasks placed within your ECS Cluster.
The Application Load Balancer is configured with blue and green target groups — allowing for a shift of live traffic from the old version (blue) to the new version (green) — after health checks pass, ensuring zero-downtime for your users.

- **Automated Validation and Promotion**: Once the new containers become healthy, CodePipeline performs automated checks (such as health checks or smoke tests). If everything is healthy, the pipeline promotes the green environment, sending all live customer requests to it. The previous (blue) environment is kept alive briefly for fallback if needed.

- **Continuous Improvement and Repeat** This process forms a fully automated pipeline — from code commit to production — allowing you to deploy new features and bug fixes safely, frequently, and efficiently, with confidence in your platform’s stability.

## Prerequisites

- AWS Account
- GitHub repository with your code
- Terraform installed locally
- AWS CLI configured

## Setup Instructions

### 1. Update GitHub Repository Information

Update the GitHub repository variables in `infra/terraform.tfvars`:

```hcl
github_repo  = "your-github-username/e-commerce-website-with-ecs"
github_branch = "main"
```

### 2. Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply --auto-approve
```

### 3. Complete GitHub Connection

After deployment, you need to complete the GitHub connection:

1. Go to AWS Console > Developer Tools > Settings > Connections
2. Find the connection named "github-connection"
3. Click "Update pending connection"
4. Follow the prompts to connect to your GitHub account

### 4. Push Code to Trigger Pipeline

Once the connection is established, push code to your repository to trigger the pipeline:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

## Cleanup

To remove all resources:

```bash
cd infra
terraform destroy
```# E-Commerce-CICD-with-ECS
# e-commerce-cicd-pipeline
