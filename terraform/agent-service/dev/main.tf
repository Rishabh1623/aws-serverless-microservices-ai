data "aws_caller_identity" "current" {}

# ============================================================================
# DATA SOURCES - Get API URLs from other services
# ============================================================================

data "terraform_remote_state" "hotel_service" {
  backend = "s3"
  config = {
    bucket = "terraform-state-955510722779"
    key    = "hotel-service/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "cart_service" {
  backend = "s3"
  config = {
    bucket = "terraform-state-955510722779"
    key    = "cart-service/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "order_service" {
  backend = "s3"
  config = {
    bucket = "terraform-state-955510722779"
    key    = "order-service/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "payment_service" {
  backend = "s3"
  config = {
    bucket = "terraform-state-955510722779"
    key    = "payment-service/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  service_name = "agent-service"
  environment  = "dev"

  # Get API endpoints from deployed services
  hotel_api_url   = data.terraform_remote_state.hotel_service.outputs.api_gateway_url
  cart_api_url    = data.terraform_remote_state.cart_service.outputs.api_gateway_url
  order_api_url   = data.terraform_remote_state.order_service.outputs.api_gateway_url
  payment_api_url = data.terraform_remote_state.payment_service.outputs.api_gateway_url
}

# ============================================================================
# LAMBDA DEPLOYMENT PACKAGE
# ============================================================================

# Use pre-built package with dependencies
# Build using: cd agent-service && bash build-lambda.sh
resource "null_resource" "check_lambda_package" {
  provisioner "local-exec" {
    command = "test -f ${path.module}/../../../agent-service/agent-service-lambda.zip || (echo 'ERROR: Lambda package not found. Run: cd agent-service && bash build-lambda.sh' && exit 1)"
  }
}

# Lambda Layer with heavy dependencies (Strands, Anthropic, Pydantic)
resource "aws_lambda_layer_version" "dependencies" {
  filename            = "${path.module}/../../../agent-service/layer.zip"
  layer_name          = "strands-dependencies-${local.environment}"
  compatible_runtimes = ["python3.10"]
  description         = "Strands Agents SDK, Anthropic, Pydantic, OpenTelemetry"
}

resource "aws_lambda_function" "agent_package" {
  depends_on = [null_resource.check_lambda_package]
  
  function_name = "${local.service_name}-${local.environment}"
  description   = "AI Travel Assistant using Strands Agents SDK and Bedrock"

  # Deployment package
  filename         = "${path.module}/../../../agent-service/agent-service-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../agent-service/agent-service-lambda.zip")

  # Runtime configuration
  runtime = "python3.10"  # Changed from 3.11 to avoid OpenTelemetry PEP 479 bug
  handler = "app.lambda_handler"
  
  # Lambda Layer with dependencies
  layers = [aws_lambda_layer_version.dependencies.arn]

  # Resource allocation
  memory_size = 512 # MB - Strands Agents needs more memory
  timeout     = 60  # seconds - AI processing can take time

  # Execution role
  role = aws_iam_role.agent_lambda.arn

  # Environment variables
  environment {
    variables = {
      HOTEL_API_URL         = local.hotel_api_url
      CART_API_URL          = local.cart_api_url
      ORDER_API_URL         = local.order_api_url
      PAYMENT_API_URL       = local.payment_api_url
      BEDROCK_MODEL_ID      = "anthropic.claude-3-haiku-20240307-v1:0"
      CONVERSATION_TABLE    = aws_dynamodb_table.conversations.name
      SECRETS_ARN           = module.secrets.secret_arns["bedrock_config"]
      LOG_LEVEL             = "INFO"
      BEDROCK_REGION        = var.aws_region
      USE_ANTHROPIC_DIRECT  = "true"  # Bypass Bedrock billing issues
      ANTHROPIC_API_KEY     = var.anthropic_api_key
    }
  }

  # Tracing
  tracing_config {
    mode = "Active" # Enable X-Ray tracing
  }
}

# ============================================================================
# SECRETS MANAGER
# ============================================================================

module "secrets" {
  source = "../../modules/secrets-manager"

  service_name = local.service_name
  environment  = local.environment

  secrets = {
    bedrock_config = jsonencode({
      model_id = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      region   = var.aws_region
    })
    api_endpoints = jsonencode({
      hotel_api_url   = local.hotel_api_url
      cart_api_url    = local.cart_api_url
      order_api_url   = local.order_api_url
      payment_api_url = local.payment_api_url
    })
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
          "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      }
    ]
  })
}

# Secrets Manager permissions
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.agent_lambda.name
  policy_arn = module.secrets.secrets_access_policy_arn
}

# DynamoDB permissions for conversation history
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${local.service_name}-${local.environment}-dynamodb-policy"
  role = aws_iam_role.agent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.conversations.arn,
          "${aws_dynamodb_table.conversations.arn}/index/*"
        ]
      }
    ]
  })
}

# ============================================================================
# DYNAMODB TABLE FOR CONVERSATION HISTORY
# ============================================================================

resource "aws_dynamodb_table" "conversations" {
  name           = "${local.service_name}-conversations-${local.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  range_key      = "sessionId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false # Enable in production
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Service = local.service_name
  }
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "agent" {
  name              = "/aws/lambda/${aws_lambda_function.agent_package.function_name}"
  retention_in_days = 7 # Keep logs for 7 days (cost optimization)
}

# ============================================================================
# API GATEWAY HTTP API
# ============================================================================

resource "aws_apigatewayv2_api" "agent" {
  name          = "${local.service_name}-${local.environment}"
  protocol_type = "HTTP"
  description   = "AI Travel Assistant API"

  cors_configuration {
    allow_origins = ["*"] # In production, restrict to your domain
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
    throttling_burst_limit = 100 # Max burst
    throttling_rate_limit  = 50  # Requests per second
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

  integration_uri        = aws_lambda_function.agent_package.invoke_arn
  integration_method     = "POST"
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
  function_name = aws_lambda_function.agent_package.function_name
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
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Agent Lambda function error rate is high"

  dimensions = {
    FunctionName = aws_lambda_function.agent_package.function_name
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
  threshold           = 30000 # 30 seconds
  alarm_description   = "Agent Lambda function duration is high"

  dimensions = {
    FunctionName = aws_lambda_function.agent_package.function_name
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
    FunctionName = aws_lambda_function.agent_package.function_name
  }
}
