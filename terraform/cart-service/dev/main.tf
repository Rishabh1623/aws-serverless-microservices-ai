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
    key            = "cart-service/dev/terraform.tfstate"
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
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Data source for Lambda deployment packages
data "archive_file" "add_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/add_cart"
  output_path = "${path.module}/lambda_packages/add_cart.zip"
}

data "archive_file" "remove_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/remove_cart"
  output_path = "${path.module}/lambda_packages/remove_cart.zip"
}

data "archive_file" "get_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/get_cart"
  output_path = "${path.module}/lambda_packages/get_cart.zip"
}

# Cart Service Module
module "cart_service" {
  source = "../../modules/lambda-service"
  
  service_name = "cart-service"
  environment  = "dev"
  
  lambda_functions = {
    add-cart = {
      filename                = data.archive_file.add_cart.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        CART_TABLE = "cart-service-cart_table-dev"
      }
    }
    remove-cart = {
      filename                = data.archive_file.remove_cart.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        CART_TABLE = "cart-service-cart_table-dev"
      }
    }
    get-cart = {
      filename                = data.archive_file.get_cart.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        CART_TABLE = "cart-service-cart_table-dev"
      }
    }
  }
  
  api_gateway_resources = {
    cart = {
      path_part = "cart"
    }
    cart_add = {
      path_part = "add"
    }
    cart_remove = {
      path_part = "remove"
    }
    cart_user = {
      path_part = "{userId}"
    }
  }
  
  api_gateway_methods = {
    add_cart = {
      resource_key = "cart_add"
      http_method  = "POST"
      lambda_key   = "add-cart"
    }
    remove_cart = {
      resource_key = "cart_remove"
      http_method  = "DELETE"
      lambda_key   = "remove-cart"
    }
    get_cart = {
      resource_key = "cart_user"
      http_method  = "GET"
      lambda_key   = "get-cart"
    }
  }
  
  dynamodb_tables = {
    cart_table = {
      hash_key  = "userId"
      range_key = "productId"
      attributes = [
        {
          name = "userId"
          type = "S"
        },
        {
          name = "productId"
          type = "S"
        }
      ]
    }
  }
}
