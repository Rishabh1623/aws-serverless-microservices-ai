/**
 * Terraform Module: Lambda Durable Function
 * 
 * Creates a Lambda function with Durable Execution enabled.
 * Durable functions can run for up to 1 year with automatic state management,
 * checkpointing, and replay capabilities.
 */

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "app.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "source_dir" {
  description = "Source directory containing Lambda code"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Function timeout in seconds (max 900 for standard, unlimited for durable)"
  type        = number
  default     = 900
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 512
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_durable_execution" {
  description = "Enable Lambda Durable Execution"
  type        = bool
  default     = true
}

variable "max_execution_time" {
  description = "Maximum execution time for durable functions (in seconds, up to 31536000 = 1 year)"
  type        = number
  default     = 86400  # 24 hours default
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Durable execution policy (for state management)
resource "aws_iam_role_policy" "durable_execution" {
  count = var.enable_durable_execution ? 1 : 0
  name  = "${var.function_name}-durable-policy"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution",
          "states:DescribeExecution",
          "states:StopExecution",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      }
    ]
  })
}

# Package Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda_${var.function_name}.zip"
}

# Lambda Function
resource "aws_lambda_function" "function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.handler
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  layers          = var.layers

  environment {
    variables = merge(
      var.environment_variables,
      var.enable_durable_execution ? {
        DURABLE_EXECUTION_ENABLED = "true"
        MAX_EXECUTION_TIME        = tostring(var.max_execution_time)
      } : {}
    )
  }

  # Durable execution configuration
  dynamic "logging_config" {
    for_each = var.enable_durable_execution ? [1] : []
    content {
      log_format = "JSON"
      log_group  = "/aws/lambda/${var.function_name}"
    }
  }

  tags = merge(
    var.tags,
    {
      DurableExecution = var.enable_durable_execution ? "enabled" : "disabled"
    }
  )
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7

  tags = var.tags
}

# Outputs
output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}
