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
    key            = "payment-service/dev/terraform.tfstate"
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
      Service     = "payment-service"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources for Lambda packages
data "archive_file" "process_payment" {
  type        = "zip"
  source_dir  = "${path.module}/../../../payment-service/src/process_payment"
  output_path = "${path.module}/lambda_packages/process_payment.zip"
}

data "archive_file" "get_payment" {
  type        = "zip"
  source_dir  = "${path.module}/../../../payment-service/src/get_payment"
  output_path = "${path.module}/lambda_packages/get_payment.zip"
}

# Payment Service Module
module "payment_service" {
  source = "../../modules/lambda-service"
  
  service_name = "payment-service"
  environment  = "dev"
  
  lambda_functions = {
    process-payment = {
      filename                = data.archive_file.process_payment.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 60  # Longer timeout for payment gateway
      environment_variables   = {
        PAYMENT_TABLE = "payment-service-payment_table-dev"
      }
    }
    get-payment = {
      filename                = data.archive_file.get_payment.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        PAYMENT_TABLE = "payment-service-payment_table-dev"
      }
    }
  }
  
  api_gateway_resources = {
    payments = {
      path_part = "payments"
    }
    payment_id = {
      path_part = "{paymentId}"
    }
  }
  
  api_gateway_methods = {
    process_payment = {
      resource_key = "payments"
      http_method  = "POST"
      lambda_key   = "process-payment"
    }
    get_payment = {
      resource_key = "payment_id"
      http_method  = "GET"
      lambda_key   = "get-payment"
    }
  }
  
  dynamodb_tables = {
    payment_table = {
      hash_key  = "paymentId"
      attributes = [
        {
          name = "paymentId"
          type = "S"
        },
        {
          name = "orderId"
          type = "S"
        },
        {
          name = "idempotencyKey"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "OrderIdIndex"
          hash_key        = "orderId"
          projection_type = "ALL"
        },
        {
          name            = "IdempotencyKeyIndex"
          hash_key        = "idempotencyKey"
          projection_type = "ALL"
        }
      ]
    }
  }
}
