/**
 * Order Processing Workflow - AWS Step Functions
 * 
 * Orchestrates the complete order processing with:
 * - Cart validation
 * - Pricing calculation (with promo codes)
 * - Order creation
 * - Payment processing with retries
 * - Cart cleanup
 * - Email confirmation
 * - Automatic rollback on failures
 */

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}

# Get existing Lambda functions
data "aws_lambda_function" "create_order" {
  function_name = "order-service-create-order-${var.environment}"
}

data "aws_lambda_function" "get_cart" {
  function_name = "cart-service-get-cart-${var.environment}"
}

data "aws_lambda_function" "process_payment" {
  function_name = "payment-service-process-payment-${var.environment}"
}

# Get DynamoDB tables
data "aws_dynamodb_table" "orders" {
  name = "order-service-orders-${var.environment}"
}

data "aws_dynamodb_table" "carts" {
  name = "cart-service-carts-${var.environment}"
}

data "aws_dynamodb_table" "payments" {
  name = "payment-service-payments-${var.environment}"
}

# ============================================================================
# STEP FUNCTIONS WORKFLOW
# ============================================================================

module "order_workflow" {
  source = "../../modules/step-functions-workflow"

  workflow_name = "${var.project_name}-order-processing-${var.environment}"
  workflow_type = "STANDARD"  # Use STANDARD for long-running workflows
  environment   = var.environment

  lambda_arns = {
    create_order     = data.aws_lambda_function.create_order.arn
    get_cart         = data.aws_lambda_function.get_cart.arn
    process_payment  = data.aws_lambda_function.process_payment.arn
  }

  dynamodb_arns = [
    data.aws_dynamodb_table.orders.arn,
    data.aws_dynamodb_table.carts.arn,
    data.aws_dynamodb_table.payments.arn,
    "${data.aws_dynamodb_table.carts.arn}/index/*"
  ]

  definition = jsonencode({
    Comment = "Order Processing Workflow with cart validation, pricing, payment, and notification"
    StartAt = "ValidateOrderRequest"
    States = {
      
      # Step 1: Validate order request
      ValidateOrderRequest = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_order.arn
          Payload = {
            "action" = "validate"
            "order.$" = "$"
          }
        }
        ResultPath = "$.validationResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "ValidationFailed"
          }
        ]
        Next = "GetCartItems"
      }

      # Step 2: Get cart items
      GetCartItems = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.get_cart.arn
          Payload = {
            "userId.$" = "$.userId"
          }
        }
        ResultPath = "$.cartData"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "CartNotFound"
          }
        ]
        Next = "CheckCartNotEmpty"
      }

      # Step 3: Check if cart has items
      CheckCartNotEmpty = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.cartData.Payload.itemCount"
            NumericGreaterThan = 0
            Next = "CalculatePricing"
          }
        ]
        Default = "CartEmpty"
      }

      # Step 4: Calculate pricing with promo codes
      CalculatePricing = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_order.arn
          Payload = {
            "action" = "calculate_pricing"
            "cart.$" = "$.cartData.Payload"
            "promoCode.$" = "$.promoCode"
          }
        }
        ResultPath = "$.pricingResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "PricingFailed"
          }
        ]
        Next = "CreateOrderRecord"
      }

      # Step 5: Create order record
      CreateOrderRecord = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_order.arn
          Payload = {
            "action" = "create"
            "order.$" = "$"
          }
        }
        ResultPath = "$.orderResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "OrderCreationFailed"
          }
        ]
        Next = "ProcessPayment"
      }

      # Step 6: Process payment (with retries)
      ProcessPayment = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.process_payment.arn
          Payload = {
            "orderId.$" = "$.orderResult.Payload.orderId"
            "amount.$" = "$.pricingResult.Payload.total"
            "currency" = "USD"
            "userId.$" = "$.userId"
            "paymentMethod.$" = "$.paymentMethod"
          }
        }
        ResultPath = "$.paymentResult"
        Retry = [
          {
            ErrorEquals = ["PaymentTemporaryError"]
            IntervalSeconds = 5
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "PaymentFailed"
          }
        ]
        Next = "ClearCart"
      }

      # Step 7: Clear cart after successful payment
      ClearCart = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.carts.name
          Key = {
            userId = {
              "S.$" = "$.userId"
            }
          }
          UpdateExpression = "SET items = :empty, itemCount = :zero, updatedAt = :timestamp"
          ExpressionAttributeValues = {
            ":empty" = {
              L = []
            }
            ":zero" = {
              N = "0"
            }
            ":timestamp" = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
        }
        ResultPath = "$.cartClearResult"
        Retry = [
          {
            ErrorEquals = ["DynamoDB.ProvisionedThroughputExceededException"]
            IntervalSeconds = 1
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "OrderSuccessCartNotCleared"  # Continue even if cart clear fails
          }
        ]
        Next = "SendConfirmationEmail"
      }

      # Step 8: Send confirmation email
      SendConfirmationEmail = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_order.arn
          Payload = {
            "action" = "send_confirmation"
            "order.$" = "$"
          }
        }
        ResultPath = "$.emailResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts = 2
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "OrderSuccessEmailFailed"  # Continue even if email fails
          }
        ]
        Next = "OrderSuccess"
      }

      # Success states
      OrderSuccess = {
        Type = "Succeed"
      }

      OrderSuccessEmailFailed = {
        Type = "Succeed"
      }

      OrderSuccessCartNotCleared = {
        Type = "Succeed"
      }

      # Error states
      ValidationFailed = {
        Type = "Fail"
        Error = "ValidationError"
        Cause = "Order request validation failed"
      }

      CartNotFound = {
        Type = "Fail"
        Error = "CartNotFound"
        Cause = "User cart not found"
      }

      CartEmpty = {
        Type = "Fail"
        Error = "CartEmpty"
        Cause = "Cart has no items"
      }

      PricingFailed = {
        Type = "Fail"
        Error = "PricingError"
        Cause = "Failed to calculate order pricing"
      }

      OrderCreationFailed = {
        Type = "Fail"
        Error = "OrderCreationError"
        Cause = "Failed to create order record"
      }

      PaymentFailed = {
        Type = "Pass"
        Result = "Payment failed, rolling back order"
        ResultPath = "$.rollbackReason"
        Next = "RollbackOrder"
      }

      # Rollback states
      RollbackOrder = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_order.arn
          Payload = {
            "action" = "rollback"
            "orderId.$" = "$.orderResult.Payload.orderId"
          }
        }
        ResultPath = null
        Next = "RestoreCart"
      }

      RestoreCart = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.carts.name
          Key = {
            userId = {
              "S.$" = "$.userId"
            }
          }
          UpdateExpression = "SET #status = :active, updatedAt = :timestamp"
          ExpressionAttributeNames = {
            "#status" = "status"
          }
          ExpressionAttributeValues = {
            ":active" = {
              S = "active"
            }
            ":timestamp" = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
        }
        ResultPath = null
        Next = "OrderFailed"
      }

      OrderFailed = {
        Type = "Fail"
        Error = "OrderFailed"
        Cause = "Order processing failed and was rolled back"
      }
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "order-processing-workflow"
  }
}
