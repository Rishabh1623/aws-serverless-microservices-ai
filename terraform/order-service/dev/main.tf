# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================

data "aws_caller_identity" "current" {}

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

data "archive_file" "cancel_order" {
  type        = "zip"
  source_dir  = "${path.module}/../../../order-service/src/cancel_order"
  output_path = "${path.module}/lambda_packages/cancel_order.zip"
}

data "archive_file" "order_orchestrator" {
  type        = "zip"
  source_dir  = "${path.module}/../../../order-service/src/order_orchestrator"
  output_path = "${path.module}/lambda_packages/order_orchestrator.zip"
}

# ============================================================================
# ORDER SERVICE MODULE
# ============================================================================

module "order_service" {
  source = "../../modules/lambda-service"

  service_name = var.service_name
  environment  = var.environment

  lambda_functions = {
    create-order = {
      filename    = data.archive_file.create_order.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        ORDERS_TABLE   = "${var.service_name}-orders-${var.environment}"
        CART_TABLE     = "cart-service-carts-${var.environment}"
        EVENT_BUS_NAME = "hotel-service-${var.environment}"
        ENVIRONMENT    = var.environment
      }
    }
    get-order = {
      filename    = data.archive_file.get_order.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        ORDERS_TABLE = "${var.service_name}-orders-${var.environment}"
        ENVIRONMENT  = var.environment
      }
    }
    list-user-orders = {
      filename    = data.archive_file.list_user_orders.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        ORDERS_TABLE = "${var.service_name}-orders-${var.environment}"
        ENVIRONMENT  = var.environment
      }
    }
    cancel-order = {
      filename    = data.archive_file.cancel_order.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = 256
      timeout     = 30
      environment_variables = {
        ORDERS_TABLE   = "${var.service_name}-orders-${var.environment}"
        EVENT_BUS_NAME = "hotel-service-${var.environment}"
        ENVIRONMENT    = var.environment
      }
    }
    order-orchestrator = {
      filename    = data.archive_file.order_orchestrator.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = 1024
      timeout     = 900
      environment_variables = {
        ORDERS_TABLE        = "${var.service_name}-orders-${var.environment}"
        CART_TABLE          = "cart-service-carts-${var.environment}"
        PAYMENTS_TABLE      = "payment-service-payments-${var.environment}"
        FROM_EMAIL          = "orders@travel-platform.com"
        TEMPLATE_NAME       = "order-confirmation-${var.environment}"
        STRIPE_SECRET_NAME  = "travel-platform-stripe-key-${var.environment}"
        ENVIRONMENT         = var.environment
        AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
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
    list_orders = {
      resource_key = "orders"
      http_method  = "GET"
      lambda_key   = "list-user-orders"
    }
    cancel_order = {
      resource_key = "orders"
      http_method  = "DELETE"
      lambda_key   = "cancel-order"
    }
    create_order_orchestrated = {
      resource_key = "orders"
      http_method  = "PUT"
      lambda_key   = "order-orchestrator"
    }
  }

  dynamodb_tables = {
    orders = {
      hash_key = "orderId"
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
      global_secondary_indexes = [
        {
          name            = "UserIdIndex"
          hash_key        = "userId"
          projection_type = "ALL"
        }
      ]
      point_in_time_recovery = true
    }
  }
}

# ============================================================================
# GRANT PERMISSIONS
# ============================================================================

# Grant Lambda access to EventBridge
resource "aws_iam_role_policy" "lambda_eventbridge" {
  for_each = module.order_service.lambda_roles

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

# Grant Lambda access to Cart table
resource "aws_iam_role_policy" "lambda_cart_access" {
  for_each = {
    create-order = module.order_service.lambda_roles["create-order"]
  }

  role = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/cart-service-carts-${var.environment}",
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/cart-service-carts-${var.environment}/index/*"
        ]
      }
    ]
  })
}

# ============================================================================
# DURABLE FUNCTION CONFIGURATION
# ============================================================================

# Enable durable execution for order orchestrator
resource "aws_lambda_function_event_invoke_config" "order_orchestrator" {
  function_name = module.order_service.lambda_functions["order-orchestrator"].function_name

  maximum_event_age_in_seconds = 21600  # 6 hours
  maximum_retry_attempts       = 2
}

# Grant additional permissions for orchestrator
resource "aws_iam_role_policy" "orchestrator_permissions" {
  name = "${var.service_name}-orchestrator-permissions-${var.environment}"
  role = module.order_service.lambda_roles["order-orchestrator"].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendTemplatedEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:travel-platform-stripe-key-${var.environment}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/payment-service-payments-${var.environment}"
      }
    ]
  })
}
