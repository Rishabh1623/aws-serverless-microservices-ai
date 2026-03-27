provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      Service     = "cart-service"
      Component   = "pipeline"
      ManagedBy   = "terraform"
    }
