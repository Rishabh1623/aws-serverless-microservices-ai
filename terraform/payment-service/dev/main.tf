# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================

data "aws_caller_identity" "current" {}

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

data "archive_file" "refund_payment" {
  type        = "zip"
  source_dir  = "${path.module}/../../../payment-service/src/refund_payment"
  output_path = "${path.module}/lambda_packages/refund_payment.zip"
}

data "archive_file" "stripe_webhook" {
  type        = "zip"
  source_dir  = "${path.module}/../../../payment-service/src/stripe_webhook"
  output_path = "${path.module}/lambda_packages/stripe_webhook.zip"
}

# ============================================================================
# PAYMENT SERVICE MODULE
# ============================================================================

module "payment_service" {
  source = "../../modules/lambda-service"

  service_name = var.service_name
  environment  = var.environment

  lambda_functions = {
    process-payment = {
      filename    = data.archive_file.process_payment.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        PAYMENTS_TABLE     = "${var.service_name}-payments-${var.environment}"
        ORDERS_TABLE       = "order-service-orders-${var.environment}"
        STRIPE_SECRET_NAME = "${var.service_name}-stripe-${var.environment}"
        EVENT_BUS_NAME     = "hotel-service-${var.environment}"
        ENVIRONMENT        = var.environment
      }
    }
    get-payment = {
      filename    = data.archive_file.get_payment.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        PAYMENTS_TABLE = "${var.service_name}-payments-${var.environment}"
        ENVIRONMENT    = var.environment
      }
    }
    refund-payment = {
      filename    = data.archive_file.refund_payment.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        PAYMENTS_TABLE = "${var.service_name}-payments-${var.environment}"
        EVENT_BUS_NAME = "hotel-service-${var.environment}"
        ENVIRONMENT    = var.environment
      }
    }
    stripe-webhook = {
      filename    = data.archive_file.stripe_webhook.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = 256
      timeout     = 30
      environment_variables = {
        PAYMENTS_TABLE = "${var.service_name}-payments-${var.environment}"
        EVENT_BUS_NAME = "hotel-service-${var.environment}"
        ENVIRONMENT    = var.environment
      }
    }
  }

  api_gateway_resources = {
    payments = {
      path_part = "payments"
    }
    payment_id = {
      path_part  = "{paymentId}"
      parent_key = "payments"
    }
    payment_refund = {
      path_part  = "refund"
      parent_key = "payment_id"
    }
    webhook = {
      path_part  = "webhook"
      parent_key = "payments"
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
    refund_payment = {
      resource_key = "payment_refund"
      http_method  = "POST"
      lambda_key   = "refund-payment"
    }
    stripe_webhook = {
      resource_key = "webhook"
      http_method  = "POST"
      lambda_key   = "stripe-webhook"
    }
  }

  dynamodb_tables = {
    payments = {
      hash_key = "paymentId"
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
          name = "userId"
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
# SECRETS MANAGER - Stripe API Key
# ============================================================================

module "secrets" {
  source = "../../modules/secrets-manager"

  service_name = var.service_name
  environment  = var.environment

  secrets = {
    stripe = {
      description = "Stripe API configuration"
      secret_string = jsonencode({
        api_key = var.stripe_api_key
      })
    }
  }
}

# ============================================================================
# GRANT PERMISSIONS
# ============================================================================

# Grant Lambda access to EventBridge
resource "aws_iam_role_policy" "lambda_eventbridge" {
  for_each = module.payment_service.lambda_roles

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

# Grant Lambda access to Secrets Manager
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  for_each = module.payment_service.lambda_roles

  role       = each.value.name
  policy_arn = module.secrets.secrets_read_policy_arn
}

# Grant Lambda access to Orders table
resource "aws_iam_role_policy" "lambda_orders_access" {
  for_each = {
    process-payment = module.payment_service.lambda_roles["process-payment"]
  }

  role = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/order-service-orders-${var.environment}"
      }
    ]
  })
}
