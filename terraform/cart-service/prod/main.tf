# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================
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

# ============================================================================
# CART SERVICE MODULE
# ============================================================================

module "cart_service" {
  source = "../../modules/lambda-service"
  
  service_name = var.service_name
  environment  = var.environment
  
  lambda_functions = {
    add-cart = {
      filename              = data.archive_file.add_cart.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        CART_TABLE  = "${var.service_name}-cart_table-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    remove-cart = {
      filename              = data.archive_file.remove_cart.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        CART_TABLE  = "${var.service_name}-cart_table-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    get-cart = {
      filename              = data.archive_file.get_cart.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        CART_TABLE  = "${var.service_name}-cart_table-${var.environment}"
        ENVIRONMENT = var.environment
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
