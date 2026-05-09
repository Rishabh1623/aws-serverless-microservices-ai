terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend for state management with locking
  backend "s3" {
    bucket         = "terraform-state-955510722779"
    key            = "api-gateway-unified/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Service     = "api-gateway-unified"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
