# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================

data "aws_caller_identity" "current" {}

data "archive_file" "add_to_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/add_to_cart"
  output_path = "${path.module}/lambda_packages/add_to_cart.zip"
}

data "archive_file" "get_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/get_cart"
  output_path = "${path.module}/lambda_packages/get_cart.zip"
}

data "archive_file" "remove_from_cart" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/remove_from_cart"
  output_path = "${path.module}/lambda_packages/remove_from_cart.zip"
}

data "archive_file" "apply_promo" {
  type        = "zip"
  source_dir  = "${path.module}/../../../cart-service/src/apply_promo"
  output_path = "${path.module}/lambda_packages/apply_promo.zip"
}

# ============================================================================
# CART SERVICE MODULE
# ============================================================================

module "cart_service" {
  source = "../../modules/lambda-service"

  service_name = var.service_name
  environment  = var.environment

  lambda_functions = {
    add-to-cart = {
      filename    = data.archive_file.add_to_cart.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        CART_TABLE   = "${var.service_name}-carts-${var.environment}"
        HOTELS_TABLE = "hotel-service-hotels-${var.environment}"
        ENVIRONMENT  = var.environment
      }
    }
    get-cart = {
      filename    = data.archive_file.get_cart.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        CART_TABLE  = "${var.service_name}-carts-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    remove-from-cart = {
      filename    = data.archive_file.remove_from_cart.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        CART_TABLE  = "${var.service_name}-carts-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    apply-promo = {
      filename    = data.archive_file.apply_promo.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = 256
      timeout     = 30
      environment_variables = {
        CART_TABLE  = "${var.service_name}-carts-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
  }

  # Simplified - only root resources, use HTTP methods for operations
  api_gateway_resources = {
    cart = {
      path_part = "cart"
    }
    items = {
      path_part = "items"
    }
    promo = {
      path_part = "promo"
    }
  }

  api_gateway_methods = {
    get_cart = {
      resource_key = "cart"
      http_method  = "GET"
      lambda_key   = "get-cart"
    }
    add_to_cart = {
      resource_key = "items"
      http_method  = "POST"
      lambda_key   = "add-to-cart"
    }
    remove_from_cart = {
      resource_key = "items"
      http_method  = "DELETE"
      lambda_key   = "remove-from-cart"
    }
    apply_promo = {
      resource_key = "promo"
      http_method  = "POST"
      lambda_key   = "apply-promo"
    }
  }

  dynamodb_tables = {
    carts = {
      hash_key = "cartItemId"
      attributes = [
        {
          name = "cartItemId"
          type = "S"
        },
        {
          name = "userId"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "UserIdIndex"
          hash_key        = "userId"
          projection_type = "ALL"
        }
      ]
      ttl_enabled        = true
      ttl_attribute_name = "ttl"
      point_in_time_recovery = true
    }
  }
}

# ============================================================================
# EVENT-DRIVEN ARCHITECTURE
# ============================================================================

data "terraform_remote_state" "event_driven" {
  backend = "s3"
  config = {
    bucket = "terraform-state-955510722779"
    key    = "hotel-service/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

# ============================================================================
# GRANT PERMISSIONS
# ============================================================================

# Grant Lambda access to EventBridge
resource "aws_iam_role_policy" "lambda_eventbridge" {
  for_each = module.cart_service.lambda_roles

  role = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/hotel-service-${var.environment}"
      }
    ]
  })
}

# Grant Lambda access to read Hotels table
resource "aws_iam_role_policy" "lambda_hotels_read" {
  for_each = {
    add-to-cart = module.cart_service.lambda_roles["add-to-cart"]
  }

  role = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/hotel-service-hotels-${var.environment}"
      }
    ]
  })
}
