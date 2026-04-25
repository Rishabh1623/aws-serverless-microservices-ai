# ============================================================================
# API GATEWAY CLOUDWATCH ROLE (Account-level, created once)
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Import existing role if it exists, otherwise create it
resource "aws_iam_role" "api_gateway_cloudwatch" {
  count = var.environment == "dev" && var.service_name == "hotel-service" ? 1 : 0
  name = "api-gateway-cloudwatch-global"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  count      = var.environment == "dev" && var.service_name == "hotel-service" ? 1 : 0
  role       = aws_iam_role.api_gateway_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Use existing role for other services
data "aws_iam_role" "api_gateway_cloudwatch_existing" {
  count = var.environment == "dev" && var.service_name != "hotel-service" ? 1 : 0
  name  = "api-gateway-cloudwatch-global"
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = var.environment == "dev" && var.service_name == "hotel-service" ? aws_iam_role.api_gateway_cloudwatch[0].arn : (var.environment == "dev" && var.service_name != "hotel-service" ? data.aws_iam_role.api_gateway_cloudwatch_existing[0].arn : null)
  
  # Only manage this resource in dev environment
  count = var.environment == "dev" ? 1 : 0
}

# ============================================================================
# API GATEWAY REST API
# ============================================================================

# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.service_name}-${var.environment}"
  description = "${var.service_name} API Gateway"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body,
      aws_api_gateway_integration.lambda_integrations,
      aws_api_gateway_integration.options,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [
    aws_api_gateway_integration.lambda_integrations,
    aws_api_gateway_integration_response.options
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment
  
  xray_tracing_enabled = true
  
  depends_on = [aws_api_gateway_account.this[0]]
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.service_name}-${var.environment}"
  retention_in_days = 7
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = var.lambda_functions
  
  function_name = "${var.service_name}-${each.key}-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  
  filename         = each.value.filename
  source_code_hash = filebase64sha256(each.value.filename)
  
  handler     = each.value.handler
  runtime     = each.value.runtime
  memory_size = each.value.memory_size
  timeout     = each.value.timeout
  
  environment {
    variables = merge(
      each.value.environment_variables,
      {
        ENVIRONMENT = var.environment
      }
    )
  }
  
  tracing_config {
    mode = "Active"
  }
  
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Lambda Aliases for Canary Deployments
resource "aws_lambda_alias" "live" {
  for_each = var.lambda_functions
  
  name             = "live"
  function_name    = aws_lambda_function.functions[each.key].function_name
  function_version = aws_lambda_function.functions[each.key].version
  
  dynamic "routing_config" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      additional_version_weights = {}
    }
  }
}

# CloudWatch Log Groups for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = var.lambda_functions
  
  name              = "/aws/lambda/${var.service_name}-${each.key}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.service_name}-lambda-role-${var.environment}"
  
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
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda X-Ray Policy
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Lambda DynamoDB Policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.service_name}-lambda-dynamodb-${var.environment}"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          for table in aws_dynamodb_table.tables : table.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          for table in aws_dynamodb_table.tables : "${table.arn}/index/*"
        ]
      }
    ]
  })
}

# Lambda EventBridge Policy
resource "aws_iam_role_policy" "lambda_eventbridge" {
  name = "${var.service_name}-lambda-eventbridge-${var.environment}"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway Lambda Permissions
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.lambda_functions
  
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# API Gateway Resources - Simplified Single-Pass Approach
# Terraform automatically handles dependency order when resources reference each other

locals {
  # Separate resources by level for ordered creation
  root_resources = {
    for k, v in var.api_gateway_resources : k => v
    if lookup(v, "parent_key", null) == null
  }
  child_resources = {
    for k, v in var.api_gateway_resources : k => v
    if lookup(v, "parent_key", null) != null
  }
}

# Create root resources first
resource "aws_api_gateway_resource" "root" {
  for_each = local.root_resources
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

# Create child resources (any level) - they reference parents automatically
resource "aws_api_gateway_resource" "child" {
  for_each = local.child_resources
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = try(
    aws_api_gateway_resource.child[each.value.parent_key].id,
    aws_api_gateway_resource.root[each.value.parent_key].id
  )
  path_part = each.value.path_part
  
  depends_on = [aws_api_gateway_resource.root]
}

# Merge all resource maps
locals {
  all_resources = merge(
    aws_api_gateway_resource.root,
    aws_api_gateway_resource.child
  )
}

resource "aws_api_gateway_method" "methods" {
  for_each = var.api_gateway_methods
  
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.all_resources[each.value.resource_key].id
  http_method   = each.value.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integrations" {
  for_each = var.api_gateway_methods
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.value.resource_key].id
  http_method = aws_api_gateway_method.methods[each.key].http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions[each.value.lambda_key].invoke_arn
}

# ============================================================================
# CORS SUPPORT - OPTIONS Methods
# ============================================================================

# OPTIONS method for each resource (CORS preflight)
resource "aws_api_gateway_method" "options" {
  for_each = var.api_gateway_resources
  
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.all_resources[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Mock integration for OPTIONS (no Lambda needed)
resource "aws_api_gateway_integration" "options" {
  for_each = var.api_gateway_resources
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS method response
resource "aws_api_gateway_method_response" "options" {
  for_each = var.api_gateway_resources
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  
  response_models = {
    "application/json" = "Empty"
  }
}

# OPTIONS integration response with CORS headers
resource "aws_api_gateway_integration_response" "options" {
  for_each = var.api_gateway_resources
  
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  
  depends_on = [aws_api_gateway_integration.options]
}

# DynamoDB Tables
resource "aws_dynamodb_table" "tables" {
  for_each = var.dynamodb_tables
  
  name           = "${var.service_name}-${each.key}-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = each.value.hash_key
  range_key      = try(each.value.range_key, null)
  
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  
  dynamic "global_secondary_index" {
    for_each = try(each.value.global_secondary_indexes, null) != null ? each.value.global_secondary_indexes : []
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = global_secondary_index.value.projection_type
    }
  }
  
  point_in_time_recovery {
    enabled = var.environment == "prod"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Service = var.service_name
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.environment == "prod" ? var.lambda_functions : {}
  
  alarm_name          = "${var.service_name}-${each.key}-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.functions[each.key].function_name
  }
}

# SSM Parameter for API Endpoint
resource "aws_ssm_parameter" "api_endpoint" {
  name        = "/${var.service_name}/${var.environment}/api-endpoint"
  description = "${var.service_name} API endpoint"
  type        = "String"
  value       = aws_api_gateway_stage.this.invoke_url
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "lambda_functions" {
  description = "Map of Lambda functions"
  value       = aws_lambda_function.functions
}

output "lambda_roles" {
  description = "Map of Lambda IAM roles"
  value       = { for k, v in aws_lambda_function.functions : k => aws_iam_role.lambda_role }
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "dynamodb_tables" {
  description = "Map of DynamoDB tables"
  value       = aws_dynamodb_table.tables
}
