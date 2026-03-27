provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Service   = "agent-service"
      ManagedBy = "Terraform"
      Project   = "serverless-microservices"
    }
