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
    key            = "agent-service/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "dev"
      Service     = "agent-service"
      ManagedBy   = "Terraform"
      Project     = "serverless-microservices"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  service_name = "agent-service"
  environment  = "dev"
  
  # Get API endpoints from other services
  # These should be outputs from other service deployments
  product_api_url = var.product_api_url
  cart_api_url    = var.cart_api_url
  order_api_url   = var.order_api_url
  payment_api_url = var.payment_api_url
}

# ============================================================================
# LAMBDA FUNCTION - SHOPPING AGENT
# ============================================================================

resource "aws_lambda_function" "agent" {
  function_name = "${local.service_name}-${local.environment}"
  description   = "AI Shopping Assistant using Strands Agents SDK and Bedrock"
  
  # Deployment package
  filename         = "${path.module}/../../../agent-service-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../agent-service-lambda.zip")
  
  # Runtime configuration
  runtime = "python3.11"
  handler = "app.lambda_handler"
  
  # Resource allocation
  memory_size = 512  # MB - Strands Agents needs more memory
  timeout     = 60   # seconds - AI processing can take time
  
  # Execution role
  role = aws_iam_role.agent_lambda.arn
  
  # Environment variables
  environment {
    variables = {
      PRODUCT_API_URL  = local.product_api_url
      CART_API_URL     = local.cart_api_url
      ORDER_API_URL    = local.order_api_url
      PAYMENT_API_URL  = local.payment_api_url
      BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
      LOG_LEVEL        = "INFO"
    }
  }
  
  # Tracing
  tracing_config {
    mode = "Active"  # Enable X-Ray tracing
  }
}

# ============================================================================
# IAM ROLE FOR LAMBDA
# ============================================================================

resource "aws_iam_role" "agent_lambda" {
  name = "${local.service_name}-${local.environment}-lambda-role"
  
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
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray tracing permissions
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Bedrock permissions
resource "aws_iam_role_policy" "bedrock_access" {
  name = "${local.service_name}-${local.environment}-bedrock-policy"
  role = aws_iam_role.agent_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
        ]
      }
    ]
  })
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/aws/lambda/${aws_lambda_function.agent.function_name}"
  retention_in_days = 7  # Keep logs for 7 days (cost optimization)
}

# ============================================================================
# API GATEWAY HTTP API
# ============================================================================

resource "aws_apigatewayv2_api" "agent" {
  name          = "${local.service_name}-${local.environment}"
  protocol_type = "HTTP"
  description   = "AI Shopping Assistant API"
  
  cors_configuration {
    allow_origins = ["*"]  # In production, restrict to your domain
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "agent" {
  api_id      = aws_apigatewayv2_api.agent.id
  name        = "$default"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  
  # Throttling (cost control + security)
  default_route_settings {
    throttling_burst_limit = 100   # Max burst
    throttling_rate_limit  = 50    # Requests per second
  }
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.service_name}-${local.environment}"
  retention_in_days = 7
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "agent" {
  api_id           = aws_apigatewayv2_api.agent.id
  integration_type = "AWS_PROXY"
  
  integration_uri    = aws_lambda_function.agent.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# API Gateway route
resource "aws_apigatewayv2_route" "agent" {
  api_id    = aws_apigatewayv2_api.agent.id
  route_key = "POST /agent"
  target    = "integrations/${aws_apigatewayv2_integration.agent.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}

# ============================================================================
# CLOUDWATCH ALARMS
# ============================================================================

# Alarm for high error rate
resource "aws_cloudwatch_metric_alarm" "agent_errors" {
  alarm_name          = "${local.service_name}-${local.environment}-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300  # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Agent Lambda function error rate is high"
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}

# Alarm for high latency
resource "aws_cloudwatch_metric_alarm" "agent_duration" {
  alarm_name          = "${local.service_name}-${local.environment}-high-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 30000  # 30 seconds
  alarm_description   = "Agent Lambda function duration is high"
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}

# Alarm for Bedrock throttling
resource "aws_cloudwatch_metric_alarm" "bedrock_throttles" {
  alarm_name          = "${local.service_name}-${local.environment}-bedrock-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Bedrock API is being throttled"
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}
