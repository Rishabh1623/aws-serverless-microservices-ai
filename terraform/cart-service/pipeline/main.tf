terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"  # Replace with your account ID
    key            = "cart-service/pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      Service     = "cart-service"
      Component   = "pipeline"
      ManagedBy   = "terraform"
    }
  }
}

module "cart_service_pipeline" {
  source = "../../modules/cicd-pipeline"
  
  service_name = "cart-service"
  aws_region   = var.aws_region
  
  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch
  github_token  = var.github_token
  
  approval_email = var.approval_email
  
  buildspec_path              = "cart-service/buildspec.yml"
  testspec_path               = "cart-service/testspec.yml"
  integration_testspec_path   = "cart-service/integration-testspec.yml"
}
