terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "mcp-servers/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Service     = "mcp-servers"
      ManagedBy   = "Terraform"
      Project     = "serverless-microservices"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  environment = var.environment
  
  # Common tags
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = "serverless-microservices"
  }
}

# ============================================================================
# AWS OBSERVABILITY MCP SERVER (UNIFIED)
# ============================================================================
# Single unified MCP server providing:
# - CloudWatch Logs tools (4 tools)
# - CloudWatch Metrics tools (3 tools)
# - AWS Services tools (4 tools)
# Total: 11 tools in one server
# ============================================================================

# Lambda function for AWS Observability MCP Server
resource "aws_lambda_function" "aws_observability_mcp" {
  function_name = "aws-observability-mcp-${local.environment}"
  description   = "Unified MCP server for AWS observability (Logs, Metrics, Services)"
  
  # Deployment package
  filename         = "${path.module}/../../mcp-servers/aws-observability/aws-observability-mcp.zip"
  source_code_hash = filebase64sha256("${path.module}/../../mcp-servers/aws-observability/aws-observability-mcp.zip")
  
  # Runtime configuration
  runtime = "python3.11"
  handler = "server.lambda_handler"
  
  # Resource allocation
  memory_size = 512  # MB (needs more for boto3 + MCP SDK)
  timeout     = 30   # seconds
  
  # Execution role
  role = aws_iam_role.aws_observability_mcp_lambda.arn
  
  # Environment variables
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
  
  # Tracing
  tracing_config {
    mode = "Active"
  }
  
  tags = merge(local.common_tags, {
    Name = "aws-observability-mcp-${local.environment}"
  })
}

# IAM role for AWS Observability MCP Lambda
resource "aws_iam_role" "aws_observability_mcp_lambda" {
  name = "aws-observability-mcp-lambda-role-${local.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  
  tags = local.common_tags
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy_attachment" "aws_observability_mcp_logs" {
  role       = aws_iam_role.aws_observability_mcp_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray tracing permissions
resource "aws_iam_role_policy_attachment" "aws_observability_mcp_xray" {
  role       = aws_iam_role.aws_observability_mcp_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Unified observability permissions (Logs + Metrics + Services)
resource "aws_iam_role_policy" "aws_observability_mcp_access" {
  name = "aws-observability-mcp-access-${local.environment}"
  role = aws_iam_role.aws_observability_mcp_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs permissions
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ]
        Resource = "*"
      },
      # CloudWatch Metrics permissions
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      # Lambda inspection permissions
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:ListFunctions"
        ]
        Resource = "*"
      },
      # DynamoDB inspection permissions
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ]
        Resource = "*"
      },
      # CodePipeline inspection permissions
      {
        Effect = "Allow"
        Action = [
          "codepipeline:GetPipeline",
          "codepipeline:GetPipelineState",
          "codepipeline:GetPipelineExecution",
          "codepipeline:ListPipelineExecutions"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "aws_observability_mcp" {
  name              = "/aws/lambda/${aws_lambda_function.aws_observability_mcp.function_name}"
  retention_in_days = 7
  
  tags = local.common_tags
}

# ============================================================================
# API GATEWAY FOR AWS OBSERVABILITY MCP SERVER
# ============================================================================

resource "aws_apigatewayv2_api" "aws_observability_mcp" {
  name          = "aws-observability-mcp-${local.environment}"
  protocol_type = "HTTP"
  description   = "Unified MCP server for AWS observability"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
  
  tags = local.common_tags
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "aws_observability_mcp" {
  api_id      = aws_apigatewayv2_api.aws_observability_mcp.id
  name        = "$default"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.aws_observability_mcp_api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
    })
  }
  
  tags = local.common_tags
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "aws_observability_mcp_api" {
  name              = "/aws/apigateway/aws-observability-mcp-${local.environment}"
  retention_in_days = 7
  
  tags = local.common_tags
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "aws_observability_mcp" {
  api_id           = aws_apigatewayv2_api.aws_observability_mcp.id
  integration_type = "AWS_PROXY"
  
  integration_uri        = aws_lambda_function.aws_observability_mcp.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# API Gateway route
resource "aws_apigatewayv2_route" "aws_observability_mcp" {
  api_id    = aws_apigatewayv2_api.aws_observability_mcp.id
  route_key = "POST /mcp"
  target    = "integrations/${aws_apigatewayv2_integration.aws_observability_mcp.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "aws_observability_mcp_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_observability_mcp.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.aws_observability_mcp.execution_arn}/*/*"
}

# ============================================================================
# MONITORING & ALARMS
# ============================================================================

# Alarm: High error rate
resource "aws_cloudwatch_metric_alarm" "mcp_errors" {
  alarm_name          = "aws-observability-mcp-errors-${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "MCP server error rate is too high"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.aws_observability_mcp.function_name
  }
  
  tags = local.common_tags
}

# Alarm: High duration
resource "aws_cloudwatch_metric_alarm" "mcp_duration" {
  alarm_name          = "aws-observability-mcp-duration-${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 10000  # 10 seconds
  alarm_description   = "MCP server response time is too high"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.aws_observability_mcp.function_name
  }
  
  tags = local.common_tags
}

# Alarm: Throttling
resource "aws_cloudwatch_metric_alarm" "mcp_throttles" {
  alarm_name          = "aws-observability-mcp-throttles-${local.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "MCP server is being throttled"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.aws_observability_mcp.function_name
  }
  
  tags = local.common_tags
}
