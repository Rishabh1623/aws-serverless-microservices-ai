/**
 * Payment Service - Durable Function Deployment
 * 
 * Deploys the payment processing orchestrator as a Lambda Durable Function.
 * Handles Stripe payments with retries, 3D Secure, and refunds.
 */

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "travel-platform"
}

# Data sources
data "aws_dynamodb_table" "payments" {
  name = "${var.project_name}-payments-${var.environment}"
}

data "aws_dynamodb_table" "orders" {
  name = "${var.project_name}-orders-${var.environment}"
}

# Shared Lambda layer (contains shared Python libraries)
data "aws_lambda_layer_version" "shared_layer" {
  layer_name = "${var.project_name}-shared-layer-${var.environment}"
}

# Deploy payment orchestrator as durable function
module "payment_orchestrator" {
  source = "../modules/durable-function"

  function_name = "${var.project_name}-payment-orchestrator-${var.environment}"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  source_dir    = "../../payment-service/src/payment_orchestrator"
  
  timeout     = 900  # 15 minutes for initial execution
  memory_size = 1024

  layers = [
    data.aws_lambda_layer_version.shared_layer.arn
  ]

  enable_durable_execution = true
  max_execution_time       = 86400  # 24 hours (for 3D Secure waits)

  environment_variables = {
    PAYMENTS_TABLE      = data.aws_dynamodb_table.payments.name
    ORDERS_TABLE        = data.aws_dynamodb_table.orders.name
    FROM_EMAIL          = "payments@${var.project_name}.com"
    RECEIPT_TEMPLATE    = "payment-receipt-${var.environment}"
    STRIPE_SECRET_NAME  = "${var.project_name}-stripe-key-${var.environment}"
    ENVIRONMENT         = var.environment
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment-service"
    Type        = "durable-function"
  }
}

# Grant DynamoDB permissions
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.project_name}-payment-orchestrator-dynamodb-${var.environment}"
  role = module.payment_orchestrator.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          data.aws_dynamodb_table.payments.arn,
          data.aws_dynamodb_table.orders.arn
        ]
      }
    ]
  })
}

# Grant SES permissions for receipt emails
resource "aws_iam_role_policy" "ses_access" {
  name = "${var.project_name}-payment-orchestrator-ses-${var.environment}"
  role = module.payment_orchestrator.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendTemplatedEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Grant Secrets Manager permissions for Stripe key
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-payment-orchestrator-secrets-${var.environment}"
  role = module.payment_orchestrator.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}-stripe-key-${var.environment}-*"
      }
    ]
  })
}

# Grant CloudWatch metrics permissions
resource "aws_iam_role_policy" "cloudwatch_access" {
  name = "${var.project_name}-payment-orchestrator-cloudwatch-${var.environment}"
  role = module.payment_orchestrator.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway integration
resource "aws_apigatewayv2_integration" "payment_orchestrator" {
  api_id           = data.aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = module.payment_orchestrator.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

data "aws_apigatewayv2_api" "main" {
  name = "${var.project_name}-api-${var.environment}"
}

# API Gateway route
resource "aws_apigatewayv2_route" "payment_orchestrator" {
  api_id    = data.aws_apigatewayv2_api.main.id
  route_key = "POST /payments/orchestrated"
  target    = "integrations/${aws_apigatewayv2_integration.payment_orchestrator.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.payment_orchestrator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Outputs
output "function_arn" {
  description = "ARN of the payment orchestrator function"
  value       = module.payment_orchestrator.function_arn
}

output "function_name" {
  description = "Name of the payment orchestrator function"
  value       = module.payment_orchestrator.function_name
}

output "api_endpoint" {
  description = "API endpoint for orchestrated payments"
  value       = "${data.aws_apigatewayv2_api.main.api_endpoint}/payments/orchestrated"
}
