provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "serverless-microservices"
      ManagedBy   = "terraform"
      Environment = "shared"
    }
