provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      Service     = "payment-service"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
