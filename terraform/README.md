# Terraform Infrastructure for Serverless Microservices

## Overview

This directory contains Terraform configurations for deploying Pattern 1 microservices architecture with complete AWS DevOps CI/CD pipelines.

## Structure

```
terraform/
├── modules/
│   ├── lambda-service/          # Reusable Lambda service module
│   ├── cicd-pipeline/           # Reusable CI/CD pipeline module
│   └── api-gateway/             # API Gateway module
├── environments/
│   ├── dev/                     # Dev environment
│   ├── prod/                    # Prod environment
│   └── pipeline/                # CI/CD pipeline infrastructure
├── cart-service/                # Cart service infrastructure
├── product-service/             # Product service infrastructure
└── shared/                      # Shared resources (S3, IAM, etc.)
```

## Prerequisites

```bash
# Install Terraform
terraform --version  # Should be 1.5.0 or higher

# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## Quick Start

### 1. Deploy Shared Resources
```bash
cd terraform/shared
terraform init
terraform plan
terraform apply
```

### 2. Deploy Cart Service Pipeline
```bash
cd terraform/cart-service/pipeline
terraform init
terraform plan -var="github_token=YOUR_TOKEN"
terraform apply -var="github_token=YOUR_TOKEN"
```

### 3. Deploy Cart Service (Dev)
```bash
cd terraform/cart-service/dev
terraform init
terraform plan
terraform apply
```

### 4. Deploy Cart Service (Prod)
```bash
cd terraform/cart-service/prod
terraform init
terraform plan
terraform apply
```

## Features

- **Modular Design**: Reusable Terraform modules
- **Environment Separation**: Dev and Prod isolated
- **State Management**: Remote state in S3 with DynamoDB locking
- **CI/CD Integration**: Complete CodePipeline setup
- **Security**: Least-privilege IAM, encryption at rest
- **Monitoring**: CloudWatch logs, metrics, and alarms
- **Cost Optimization**: On-demand billing, lifecycle policies

## Terraform Backend

All environments use remote state stored in S3:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "cart-service/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Module Usage

### Lambda Service Module
```hcl
module "cart_service" {
  source = "../../modules/lambda-service"
  
  service_name = "cart-service"
  environment  = "dev"
  
  lambda_functions = {
    add_cart = {
      handler     = "app.lambda_handler"
      runtime     = "python3.11"
      memory_size = 512
      timeout     = 30
    }
  }
  
  dynamodb_tables = {
    cart_table = {
      hash_key  = "userId"
      range_key = "productId"
    }
  }
}
```

## Deployment Order

1. **Shared Resources** (S3, IAM base roles)
2. **Pipeline Infrastructure** (CodePipeline, CodeBuild)
3. **Dev Environment** (Lambda, DynamoDB, API Gateway)
4. **Prod Environment** (Lambda, DynamoDB, API Gateway)

## State Management

```bash
# Initialize backend
terraform init

# View state
terraform state list

# Import existing resources
terraform import aws_lambda_function.add_cart cart-service-add-dev

# Refresh state
terraform refresh
```

## Best Practices

1. **Never commit secrets**: Use variables and AWS Secrets Manager
2. **Use workspaces**: Separate dev/prod state
3. **Plan before apply**: Always review changes
4. **Lock state**: Use DynamoDB for state locking
5. **Tag resources**: Consistent tagging for cost tracking
