provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      Service     = "order-service"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
