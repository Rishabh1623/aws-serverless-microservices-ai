}
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "order-service/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

  }
}

# Data sources for Lambda packages
data "archive_file" "create_order" {
  type        = "zip"
  source_dir  = "${path.module}/../../../order-service/src/create_order"
  output_path = "${path.module}/lambda_packages/create_order.zip"
}

data "archive_file" "get_order" {
  type        = "zip"
  source_dir  = "${path.module}/../../../order-service/src/get_order"
  output_path = "${path.module}/lambda_packages/get_order.zip"
}

data "archive_file" "list_user_orders" {
  type        = "zip"
  source_dir  = "${path.module}/../../../order-service/src/list_user_orders"
  output_path = "${path.module}/lambda_packages/list_user_orders.zip"
}

# Get service endpoints from SSM
data "aws_ssm_parameter" "cart_api_endpoint" {
  name = "/cart-service/dev/api-endpoint"
}

data "aws_ssm_parameter" "payment_api_endpoint" {
  name = "/payment-service/dev/api-endpoint"
}

# Order Service Module
module "order_service" {
  source = "../../modules/lambda-service"
  
  service_name = "order-service"
  environment  = "dev"
  
  lambda_functions = {
    create-order = {
      filename                = data.archive_file.create_order.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 60  # Longer timeout for service calls
      environment_variables   = {
        ORDER_TABLE           = "order-service-order_table-dev"
        CART_SERVICE_URL      = data.aws_ssm_parameter.cart_api_endpoint.value
        PAYMENT_SERVICE_URL   = data.aws_ssm_parameter.payment_api_endpoint.value
      }
    }
    get-order = {
      filename                = data.archive_file.get_order.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        ORDER_TABLE = "order-service-order_table-dev"
      }
    }
    list-user-orders = {
      filename                = data.archive_file.list_user_orders.output_path
      handler                 = "app.lambda_handler"
      runtime                 = "python3.11"
      memory_size             = 512
      timeout                 = 30
      environment_variables   = {
        ORDER_TABLE = "order-service-order_table-dev"
      }
    }
  }
  
  api_gateway_resources = {
    orders = {
      path_part = "orders"
    }
  }
  
  api_gateway_methods = {
    create_order = {
      resource_key = "orders"
      http_method  = "POST"
      lambda_key   = "create-order"
    }
  }
  
  dynamodb_tables = {
    order_table = {
      hash_key  = "orderId"
      range_key = "userId"
      attributes = [
        {
          name = "orderId"
          type = "S"
        },
        {
          name = "userId"
          type = "S"
        }
      ]
    }
  }
}
