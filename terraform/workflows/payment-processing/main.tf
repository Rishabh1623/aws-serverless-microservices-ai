/**
 * Payment Processing Workflow - AWS Step Functions
 * 
 * Orchestrates payment processing with:
 * - Payment validation
 * - Stripe Payment Intent creation
 * - 3D Secure authentication support
 * - Payment confirmation with retries
 * - Order status update
 * - Receipt email
 * - Automatic refund on failures
 */

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}

# Get existing Lambda functions
data "aws_lambda_function" "process_payment" {
  function_name = "payment-service-process-payment-${var.environment}"
}

data "aws_lambda_function" "refund_payment" {
  function_name = "payment-service-refund-payment-${var.environment}"
}

data "aws_lambda_function" "get_payment" {
  function_name = "payment-service-get-payment-${var.environment}"
}

# Get DynamoDB tables
data "aws_dynamodb_table" "payments" {
  name = "payment-service-payments-${var.environment}"
}

data "aws_dynamodb_table" "orders" {
  name = "order-service-orders-${var.environment}"
}

# ============================================================================
# STEP FUNCTIONS WORKFLOW
# ============================================================================

module "payment_workflow" {
  source = "../../modules/step-functions-workflow"

  workflow_name = "${var.project_name}-payment-processing-${var.environment}"
  workflow_type = "STANDARD"  # Use STANDARD for long-running workflows
  environment   = var.environment

  lambda_arns = {
    process_payment = data.aws_lambda_function.process_payment.arn
    refund_payment  = data.aws_lambda_function.refund_payment.arn
    get_payment     = data.aws_lambda_function.get_payment.arn
  }

  dynamodb_arns = [
    data.aws_dynamodb_table.payments.arn,
    data.aws_dynamodb_table.orders.arn,
    "${data.aws_dynamodb_table.payments.arn}/index/*",
    "${data.aws_dynamodb_table.orders.arn}/index/*"
  ]

  definition = jsonencode({
    Comment = "Payment Processing Workflow with Stripe integration, 3D Secure, and automatic refunds"
    StartAt = "ValidatePaymentRequest"
    States = {
      
      # Step 1: Validate payment request
      ValidatePaymentRequest = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.process_payment.arn
          Payload = {
            "action" = "validate"
            "payment.$" = "$"
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
        Next = "CreatePaymentIntent"
      }

      # Step 2: Create Stripe Payment Intent
      CreatePaymentIntent = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.process_payment.arn
          Payload = {
            "action" = "create_intent"
            "payment.$" = "$"
          }
        }
        ResultPath = "$.paymentIntentResult"
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
            Next = "PaymentIntentFailed"
          }
        ]
        Next = "CheckRequires3DSecure"
      }

      # Step 3: Check if 3D Secure authentication is required
      CheckRequires3DSecure = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.paymentIntentResult.Payload.requires_action"
            BooleanEquals = true
            Next = "Wait3DSecure"
          }
        ]
        Default = "ConfirmPayment"
      }

      # Step 4: Wait for 3D Secure authentication (if required)
      Wait3DSecure = {
        Type = "Wait"
        Seconds = 300  # Wait up to 5 minutes for user authentication
        Next = "Check3DSecureStatus"
      }

      # Step 5: Check 3D Secure authentication status
      Check3DSecureStatus = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.get_payment.arn
          Payload = {
            "paymentIntentId.$" = "$.paymentIntentResult.Payload.id"
          }
        }
        ResultPath = "$.authStatusResult"
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
            Next = "AuthenticationFailed"
          }
        ]
        Next = "IsAuthenticationComplete"
      }

      # Step 6: Check if authentication is complete
      IsAuthenticationComplete = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.authStatusResult.Payload.status"
            StringEquals = "succeeded"
            Next = "ConfirmPayment"
          },
          {
            Variable = "$.authStatusResult.Payload.status"
            StringEquals = "requires_action"
            Next = "Wait3DSecure"
          }
        ]
        Default = "AuthenticationFailed"
      }

      # Step 7: Confirm payment
      ConfirmPayment = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.process_payment.arn
          Payload = {
            "action" = "confirm"
            "paymentIntentId.$" = "$.paymentIntentResult.Payload.id"
            "payment.$" = "$"
          }
        }
        ResultPath = "$.confirmResult"
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
            Next = "PaymentConfirmationFailed"
          }
        ]
        Next = "CreatePaymentRecord"
      }

      # Step 8: Create payment record in DynamoDB
      CreatePaymentRecord = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:putItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.payments.name
          Item = {
            paymentId = {
              "S.$" = "$.confirmResult.Payload.paymentId"
            }
            orderId = {
              "S.$" = "$.orderId"
            }
            userId = {
              "S.$" = "$.userId"
            }
            amount = {
              "N.$" = "States.Format('{}', $.amount)"
            }
            currency = {
              S = "USD"
            }
            status = {
              S = "succeeded"
            }
            stripePaymentIntentId = {
              "S.$" = "$.paymentIntentResult.Payload.id"
            }
            createdAt = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
        }
        ResultPath = "$.paymentRecordResult"
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
            Next = "PaymentRecordFailed"
          }
        ]
        Next = "UpdateOrderStatus"
      }

      # Step 9: Update order status to paid
      UpdateOrderStatus = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.orders.name
          Key = {
            orderId = {
              "S.$" = "$.orderId"
            }
          }
          UpdateExpression = "SET #status = :paid, paymentId = :paymentId, paidAt = :timestamp"
          ExpressionAttributeNames = {
            "#status" = "status"
          }
          ExpressionAttributeValues = {
            ":paid" = {
              S = "paid"
            }
            ":paymentId" = {
              "S.$" = "$.confirmResult.Payload.paymentId"
            }
            ":timestamp" = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
        }
        ResultPath = "$.orderUpdateResult"
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
            Next = "PaymentSuccessOrderUpdateFailed"  # Continue even if order update fails
          }
        ]
        Next = "SendReceiptEmail"
      }

      # Step 10: Send receipt email
      SendReceiptEmail = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.process_payment.arn
          Payload = {
            "action" = "send_receipt"
            "payment.$" = "$"
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
            Next = "PaymentSuccessEmailFailed"  # Continue even if email fails
          }
        ]
        Next = "PaymentSuccess"
      }

      # Success states
      PaymentSuccess = {
        Type = "Succeed"
      }

      PaymentSuccessEmailFailed = {
        Type = "Succeed"
      }

      PaymentSuccessOrderUpdateFailed = {
        Type = "Succeed"
      }

      # Error states
      ValidationFailed = {
        Type = "Fail"
        Error = "ValidationError"
        Cause = "Payment request validation failed"
      }

      PaymentIntentFailed = {
        Type = "Fail"
        Error = "PaymentIntentError"
        Cause = "Failed to create Stripe Payment Intent"
      }

      AuthenticationFailed = {
        Type = "Fail"
        Error = "AuthenticationError"
        Cause = "3D Secure authentication failed or timed out"
      }

      PaymentConfirmationFailed = {
        Type = "Pass"
        Result = "Payment confirmation failed, initiating refund"
        ResultPath = "$.rollbackReason"
        Next = "RefundPayment"
      }

      PaymentRecordFailed = {
        Type = "Pass"
        Result = "Payment succeeded but record creation failed, initiating refund"
        ResultPath = "$.rollbackReason"
        Next = "RefundPayment"
      }

      # Rollback state
      RefundPayment = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.refund_payment.arn
          Payload = {
            "paymentIntentId.$" = "$.paymentIntentResult.Payload.id"
            "reason" = "Payment processing failed"
          }
        }
        ResultPath = null
        Next = "PaymentFailed"
      }

      PaymentFailed = {
        Type = "Fail"
        Error = "PaymentFailed"
        Cause = "Payment processing failed and was refunded"
      }
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment-processing-workflow"
  }
}
