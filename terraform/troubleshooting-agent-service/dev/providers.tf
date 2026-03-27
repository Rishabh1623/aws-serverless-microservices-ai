provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "dev"
      Service     = "troubleshooting-agent-service"
      ManagedBy   = "Terraform"
      Project     = "serverless-microservices"
    }
