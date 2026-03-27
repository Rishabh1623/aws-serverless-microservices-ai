}
  
  backend "s3" {
    bucket         = "terraform-state-543927035352"
    key            = "troubleshooting-agent-service/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

  }
}

data "aws_caller_identity" "current" {}

locals {
  service_name = "troubleshooting-agent-service"
  environment  = "prod"
  
  # Get unified MCP server URL from outputs (must be deployed first)
  aws_observability_mcp_url = var.aws_observability_mcp_url
}

# ============================================================================
# LAMBDA FUNCTION - TROUBLESHOOTING AGENT (PRODUCTION)
# ============================================================================

resource "aws_lambda_function" "troubleshooting_agent" {
  function_name = "${local.service_name}-${local.environment}"
  description   = "AI DevOps Troubleshooting Assistant using Strands Agents SDK and MCP (Production)"
  
  # Deployment package
  filename         = "${path.module}/../../../troubleshooting-agent-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../troubleshooting-agent-lambda.zip")
  
  # Runtime configuration
  runtime = "python3.11"
  handler = "app.lambda_handler"
  
  # Resource allocation (production)
  memory_size = 1536  # MB - More memory for production
  timeout     = 120   # seconds
  
  # Execution role
  role = aws_iam_role.troubleshooting_agent_lambda.arn
  
  # Environment variables
  environment {
    variables = {
      AWS_OBSERVABILITY_MCP_URL = local.aws_observability_mcp_url
      BEDROCK_MODEL_ID          = "anthropic.claude-3-sonnet-20240229-v1:0"
      LOG_LEVEL                 = "INFO"
      ENVIRONMENT               = "prod"
    }
  }
  
  # Tracing
  tracing_config {
    mode = "Active"
  }
  
  # Reserved concurrency (production)
  reserved_concurrent_executions = 10  # Max 10 concurrent executions
  
  # Dead Letter Queue
  dead_letter_config {
    target_arn = aws_sqs_queue.troubleshooting_agent_dlq.arn
  }
}

# ============================================================================
# DEAD LETTER QUEUE (DLQ)
# ============================================================================

resource "aws_sqs_queue" "troubleshooting_agent_dlq" {
  name                      = "${local.service_name}-${local.environment}-dlq"
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Name = "${local.service_name}-${local.environment}-dlq"
  }
}

# Allow Lambda to send messages to DLQ
resource "aws_sqs_queue_policy" "troubleshooting_agent_dlq" {
  queue_url = aws_sqs_queue.troubleshooting_agent_dlq.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.troubleshooting_agent_dlq.arn
    }]
  })
}

# ============================================================================
# SNS TOPIC FOR ALERTS
# ============================================================================

resource "aws_sns_topic" "troubleshooting_agent_alerts" {
  name = "${local.service_name}-${local.environment}-alerts"
  
  tags = {
    Name = "${local.service_name}-${local.environment}-alerts"
  }
}

resource "aws_sns_topic_subscription" "troubleshooting_agent_alerts_email" {
  topic_arn = aws_sns_topic.troubleshooting_agent_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================================
# IAM ROLE FOR LAMBDA
# ============================================================================

resource "aws_iam_role" "troubleshooting_agent_lambda" {
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
  role       = aws_iam_role.troubleshooting_agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray tracing permissions
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.troubleshooting_agent_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Bedrock permissions
resource "aws_iam_role_policy" "bedrock_access" {
  name = "${local.service_name}-${local.environment}-bedrock-policy"
  role = aws_iam_role.troubleshooting_agent_lambda.id
  
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
  role = aws_iam_role.troubleshooting_agent_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage"
      ]
      Resource = aws_sqs_queue.troubleshooting_agent_dlq.arn
    }]
  })
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "troubleshooting_agent" {
  name              = "/aws/lambda/${aws_lambda_function.troubleshooting_agent.function_name}"
  retention_in_days = 30  # Keep logs for 30 days in production
}

# ============================================================================
# API GATEWAY HTTP API
# ============================================================================

resource "aws_apigatewayv2_api" "troubleshooting_agent" {
  name          = "${local.service_name}-${local.environment}"
  protocol_type = "HTTP"
  description   = "AI DevOps Troubleshooting Assistant API (Production)"
  
  cors_configuration {
    allow_origins = ["*"]  # In production, restrict to your domain
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "troubleshooting_agent" {
  api_id      = aws_apigatewayv2_api.troubleshooting_agent.id
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
  
  # Throttling (production)
  default_route_settings {
    throttling_burst_limit = 100   # Max burst
    throttling_rate_limit  = 50    # Requests per second
  }
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.service_name}-${local.environment}"
  retention_in_days = 30
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "troubleshooting_agent" {
  api_id           = aws_apigatewayv2_api.troubleshooting_agent.id
  integration_type = "AWS_PROXY"
  
  integration_uri    = aws_lambda_function.troubleshooting_agent.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# API Gateway route
resource "aws_apigatewayv2_route" "troubleshooting_agent" {
  api_id    = aws_apigatewayv2_api.troubleshooting_agent.id
  route_key = "POST /troubleshoot"
  target    = "integrations/${aws_apigatewayv2_integration.troubleshooting_agent.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.troubleshooting_agent.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.troubleshooting_agent.execution_arn}/*/*"
}

# ============================================================================
# CLOUDWATCH ALARMS (PRODUCTION)
# ============================================================================

# Alarm for high error rate
resource "aws_cloudwatch_metric_alarm" "troubleshooting_agent_errors" {
  alarm_name          = "${local.service_name}-${local.environment}-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Troubleshooting Agent Lambda function error rate is high"
  alarm_actions       = [aws_sns_topic.troubleshooting_agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.troubleshooting_agent.function_name
  }
}

# Alarm for high latency
resource "aws_cloudwatch_metric_alarm" "troubleshooting_agent_duration" {
  alarm_name          = "${local.service_name}-${local.environment}-high-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 60000
  alarm_description   = "Troubleshooting Agent Lambda function duration is high"
  alarm_actions       = [aws_sns_topic.troubleshooting_agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.troubleshooting_agent.function_name
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
  alarm_actions       = [aws_sns_topic.troubleshooting_agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.troubleshooting_agent.function_name
  }
}

# Alarm for DLQ messages
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.service_name}-${local.environment}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Messages in DLQ - Lambda failures detected"
  alarm_actions       = [aws_sns_topic.troubleshooting_agent_alerts.arn]
  
  dimensions = {
    QueueName = aws_sqs_queue.troubleshooting_agent_dlq.name
  }
}

# Alarm for high cost (Bedrock usage)
resource "aws_cloudwatch_metric_alarm" "high_cost" {
  alarm_name          = "${local.service_name}-${local.environment}-high-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = 86400  # 24 hours
  statistic           = "Sum"
  threshold           = 1000   # Alert if > 1000 invocations/day
  alarm_description   = "High invocation count - potential cost issue"
  alarm_actions       = [aws_sns_topic.troubleshooting_agent_alerts.arn]
  
  dimensions = {
    FunctionName = aws_lambda_function.troubleshooting_agent.function_name
  }
}
