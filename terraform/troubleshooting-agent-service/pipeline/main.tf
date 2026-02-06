terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "troubleshooting-agent-service/pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "pipeline"
      Service     = "troubleshooting-agent-service"
      ManagedBy   = "Terraform"
      Project     = "serverless-microservices"
    }
  }
}

# Use the reusable CI/CD pipeline module
module "cicd_pipeline" {
  source = "../../modules/cicd-pipeline"
  
  # Service configuration
  service_name    = "troubleshooting-agent-service"
  github_owner    = var.github_owner
  github_repo     = var.github_repo
  github_branch   = var.github_branch
  github_token    = var.github_token
  
  # Build configuration
  buildspec_path = "troubleshooting-agent-service/buildspec.yml"
  
  # Test configuration
  run_tests       = true
  testspec_path   = "troubleshooting-agent-service/testspec.yml"
  
  # Deployment configuration
  deploy_to_dev   = true
  deploy_to_prod  = true
  require_approval = true
  approval_email  = var.approval_email
  
  # Terraform paths for deployment
  terraform_dev_path  = "terraform/troubleshooting-agent-service/dev"
  terraform_prod_path = "terraform/troubleshooting-agent-service/prod"
}
