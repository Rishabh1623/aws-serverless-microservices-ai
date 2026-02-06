terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID"
    key            = "agent-service/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "prod"
      Service     = "agent-service"
      ManagedBy   = "Terraform"
      Project     = "serverless-microservices"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  service_name = "agent-service"
  environment  = "prod"
  
  # Production API endpoints
  product_api_url = var.product_api_url
  cart_api_url    = var.cart_api_url
  order_api_url   = var.order_api_url
  payment_api_url = var.payment_api_url
}

# ============================================================================
# LAMBDA FUNCTION - SHOPPING AGENT (PRODUCTION)
# ============================================================================

resource "aws_lambda_function" "agent" {
  function_name = "${local.service_name}-${local.environment}"
  description   = "AI Shopping Assistant (Production) - Strands Agents + Bedrock"
  
  filename         = "${path.module}/../../../agent-service-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../agent-service-lambda.zip")
  
  runtime = "python3.11"
  handler = "app.lambda_handler"
  
  # Production resource allocation (higher than dev)
  memory_size = 1024  # MB - More memory for production
  timeout     = 60    # seconds
  
  role = aws_iam_role.agent_lambda.arn
  
  environment {
    variables = {
      PRODUCT_API_URL  = local.product_api_url
      CART_API_URL     = local.cart_api_url
      ORDER_API_URL    = local.order_api_url
      PAYMENT_API_URL  = local.payment_api_url
      BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
      LOG_LEVEL        = "INFO"
      ENVIRONMENT      = "prod"
    }
  }
  
  tracing_config {
    mode = "Active"
  }
  
  # Production: Higher concurrency limit
  reserved_concurrent_executions = 50  # Max 50 concurrent (vs 10 in dev)
  
  # Dead letter queue for failed invocations
  dead_letter_config {
    target_arn = aws_sqs_queue.agent_dlq.arn
  }
}

# Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "agent_dlq" {
  name                      = "${local.service_name}-${local.environment}-dlq"
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Name = "${local.service_name}-${local.environment}-dlq"
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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

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

# DLQ permissions
resource "aws_iam_role_policy" "dlq_access" {
  name = "${local.service_name}-${local.environment}-dlq-policy"
  role = aws_iam_role.agent_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.agent_dlq.arn
      }
    ]
  })
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/aws/lambda/${aws_lambda_function.agent.function_name}"
  retention_in_days = 30  # Keep logs longer in production
}

# ============================================================================
# API GATEWAY HTTP API (PRODUCTION)
# ============================================================================

resource "aws_apigatewayv2_api" "agent" {
  name          = "${local.service_name}-${local.environment}"
  protocol_type = "HTTP"
  description   = "AI Shopping Assistant API (Production)"
  
  cors_configuration {
    allow_origins = var.allowed_origins  # Restrict to your domain in prod
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

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
      errorMessage   = "$context.error.message"
    })
  }
  
  # Production throttling (higher limits)
  default_route_settings {
    throttling_burst_limit = 500   # Higher burst for production
    throttling_rate_limit  = 200   # 200 req/sec
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.service_name}-${local.environment}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "agent" {
  api_id           = aws_apigatewayv2_api.agent.id
  integration_type = "AWS_PROXY"
  
  integration_uri        = aws_lambda_function.agent.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "agent" {
  api_id    = aws_apigatewayv2_api.agent.id
  route_key = "POST /agent"
  target    = "integrations/${aws_apigatewayv2_integration.agent.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}

# ============================================================================
# CLOUDWATCH ALARMS (PRODUCTION)
# ============================================================================

# SNS topic for production alerts
resource "aws_sns_topic" "agent_alerts" {
  name = "${local.service_name}-${local.environment}-alerts"
}

resource "aws_sns_topic_subscription" "agent_alerts_email" {
  topic_arn = aws_sns_topic.agent_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# High error rate alarm
resource "aws_cloudwatch_metric_alarm" "agent_errors" {
  alarm_name          = "${local.service_name}-${local.environment}-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "PRODUCTION: Agent Lambda error rate is high"
  alarm_actions       = [aws_sns_topic.agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}

# High latency alarm
resource "aws_cloudwatch_metric_alarm" "agent_duration" {
  alarm_name          = "${local.service_name}-${local.environment}-high-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 30000
  alarm_description   = "PRODUCTION: Agent Lambda duration is high"
  alarm_actions       = [aws_sns_topic.agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}

# Throttling alarm
resource "aws_cloudwatch_metric_alarm" "agent_throttles" {
  alarm_name          = "${local.service_name}-${local.environment}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "PRODUCTION: Agent Lambda is being throttled"
  alarm_actions       = [aws_sns_topic.agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.agent.function_name
  }
}

# DLQ messages alarm
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.service_name}-${local.environment}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "PRODUCTION: Messages in DLQ - Lambda failures detected"
  alarm_actions       = [aws_sns_topic.agent_alerts.arn]
  
  dimensions = {
    QueueName = aws_sqs_queue.agent_dlq.name
  }
}

# Cost alarm (Bedrock usage)
resource "aws_cloudwatch_metric_alarm" "bedrock_cost" {
  alarm_name          = "${local.service_name}-${local.environment}-high-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600  # 6 hours
  statistic           = "Maximum"
  threshold           = 50  # Alert if daily cost > $50
  alarm_description   = "PRODUCTION: Bedrock costs are high"
  alarm_actions       = [aws_sns_topic.agent_alerts.arn]
  
  dimensions = {
    ServiceName = "AmazonBedrock"
    Currency    = "USD"
  }
}
