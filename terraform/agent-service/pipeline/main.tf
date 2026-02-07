terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "agent-service/pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Service   = "agent-service"
      ManagedBy = "Terraform"
      Project   = "serverless-microservices"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  service_name = "agent-service"
}

# Use the reusable CI/CD pipeline module
module "cicd_pipeline" {
  source = "../../modules/cicd-pipeline"
  
  service_name = local.service_name
  aws_region   = var.aws_region
  
  # GitHub configuration
  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch
  github_token  = var.github_token
  
  # Build configuration
  buildspec_path             = "agent-service/buildspec.yml"
  testspec_path              = "agent-service/testspec.yml"
  integration_testspec_path  = "agent-service/integration-testspec.yml"
  
  # Approval configuration
  approval_email = var.approval_email
  
  # Additional environment variables for build
  build_environment_variables = {
    PYTHON_VERSION = "3.11"
    SERVICE_NAME   = local.service_name
  }
}
