/**
 * Hotel Service - Durable Function Deployment
 * 
 * Deploys the hotel booking orchestrator as a Lambda Durable Function.
 * This replaces the EventBridge-based orchestration with a single durable execution.
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

variable "api_gateway_id" {
  description = "API Gateway ID for integration (optional - leave empty to skip API Gateway integration)"
  type        = string
  default     = ""
}

# Data sources
data "aws_dynamodb_table" "bookings" {
  name = "${var.project_name}-bookings-${var.environment}"
}

data "aws_dynamodb_table" "rooms" {
  name = "${var.project_name}-rooms-${var.environment}"
}

data "aws_dynamodb_table" "hotels" {
  name = "${var.project_name}-hotels-${var.environment}"
}

# Shared Lambda layer (contains shared Python libraries)
data "aws_lambda_layer_version" "shared_layer" {
  layer_name = "${var.project_name}-shared-layer-${var.environment}"
}

# Deploy booking orchestrator as durable function
module "booking_orchestrator" {
  source = "../modules/durable-function"

  function_name = "${var.project_name}-booking-orchestrator-${var.environment}"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  source_dir    = "../../hotel-service/src/booking_orchestrator"
  
  timeout     = 900  # 15 minutes for initial execution
  memory_size = 1024

  layers = [
    data.aws_lambda_layer_version.shared_layer.arn
  ]

  enable_durable_execution = true
  max_execution_time       = 2592000  # 30 days (for long-running workflows)

  environment_variables = {
    BOOKING_TABLE       = data.aws_dynamodb_table.bookings.name
    ROOM_TABLE          = data.aws_dynamodb_table.rooms.name
    HOTEL_TABLE         = data.aws_dynamodb_table.hotels.name
    IDEMPOTENCY_TABLE   = "${var.project_name}-idempotency-${var.environment}"
    FROM_EMAIL          = "bookings@${var.project_name}.com"
    TEMPLATE_NAME       = "booking-confirmation-${var.environment}"
    ENVIRONMENT         = var.environment
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "hotel-service"
    Type        = "durable-function"
  }
}

# Grant DynamoDB permissions
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.project_name}-booking-orchestrator-dynamodb-${var.environment}"
  role = module.booking_orchestrator.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem"
        ]
        Resource = [
          data.aws_dynamodb_table.bookings.arn,
          data.aws_dynamodb_table.rooms.arn,
          data.aws_dynamodb_table.hotels.arn,
          "${data.aws_dynamodb_table.bookings.arn}/index/*",
          "${data.aws_dynamodb_table.rooms.arn}/index/*"
        ]
      }
    ]
  })
}

# Grant SES permissions for email notifications
resource "aws_iam_role_policy" "ses_access" {
  name = "${var.project_name}-booking-orchestrator-ses-${var.environment}"
  role = module.booking_orchestrator.role_name

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

# Grant CloudWatch metrics permissions
resource "aws_iam_role_policy" "cloudwatch_access" {
  name = "${var.project_name}-booking-orchestrator-cloudwatch-${var.environment}"
  role = module.booking_orchestrator.role_name

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

# API Gateway integration (optional)
resource "aws_apigatewayv2_integration" "booking_orchestrator" {
  count = var.api_gateway_id != "" ? 1 : 0

  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  integration_uri    = module.booking_orchestrator.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# API Gateway route
resource "aws_apigatewayv2_route" "booking_orchestrator" {
  count = var.api_gateway_id != "" ? 1 : 0

  api_id    = var.api_gateway_id
  route_key = "POST /bookings/orchestrated"
  target    = "integrations/${aws_apigatewayv2_integration.booking_orchestrator[0].id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  count = var.api_gateway_id != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.booking_orchestrator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:*:${var.api_gateway_id}/*/*"
}

# Outputs
output "function_arn" {
  description = "ARN of the booking orchestrator function"
  value       = module.booking_orchestrator.function_arn
}

output "function_name" {
  description = "Name of the booking orchestrator function"
  value       = module.booking_orchestrator.function_name
}

output "api_endpoint" {
  description = "API endpoint for orchestrated bookings (empty if API Gateway not configured)"
  value       = var.api_gateway_id != "" ? "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/bookings/orchestrated" : "Not configured - invoke Lambda directly"
}
