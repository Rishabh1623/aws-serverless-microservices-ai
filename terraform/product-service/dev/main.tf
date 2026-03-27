}
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "product-service/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

  }
}

# Data source for Lambda deployment packages
data "archive_file" "list_products" {
  type        = "zip"
  source_dir  = "${path.module}/../../../product-service/src/list_products"
  output_path = "${path.module}/lambda_packages/list_products.zip"
}

data "archive_file" "get_product" {
  type        = "zip"
  source_dir  = "${path.module}/../../../product-service/src/get_product"
  output_path = "${path.module}/lambda_packages/get_product.zip"
}

# Product Service Module
module "product_service" {
  source = "../../modules/lambda-service"
  
  service_name = "product-service"
  environment  = "dev"
  
  lambda_functions = {
    list-products = {
      filename                = data.archive_file.list_products.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        PRODUCT_TABLE = "product-service-product_table-dev"
      }
    }
    get-product = {
      filename                = data.archive_file.get_product.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        PRODUCT_TABLE = "product-service-product_table-dev"
      }
    }
  }
  
  api_gateway_resources = {
    products = {
      path_part = "products"
    }
    product_id = {
      path_part = "{productId}"
    }
  }
  
  api_gateway_methods = {
    list_products = {
      resource_key = "products"
      http_method  = "GET"
      lambda_key   = "list-products"
    }
    get_product = {
      resource_key = "product_id"
      http_method  = "GET"
      lambda_key   = "get-product"
    }
  }
  
  dynamodb_tables = {
    product_table = {
      hash_key  = "productId"
      attributes = [
        {
          name = "productId"
          type = "S"
        }
      ]
    }
  }
}
