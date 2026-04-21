/**
 * Unified API Gateway
 * 
 * Single API Gateway that routes to all microservices and workflows
 * - Hotel Service endpoints
 * - Order Service endpoints
 * - Payment Service endpoints
 * - Cart Service endpoints
 * - Agent Service endpoints
 * - Step Functions workflow triggers
 */

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}

# Get existing API Gateways
data "aws_api_gateway_rest_api" "hotel_service" {
  name = "hotel-service-dev"
}

data "aws_api_gateway_rest_api" "order_service" {
  name = "order-service-dev"
}

data "aws_api_gateway_rest_api" "payment_service" {
  name = "payment-service-dev"
}

data "aws_api_gateway_rest_api" "agent_service" {
  name = "agent-service-dev"
}

# Get Step Functions state machines
data "aws_sfn_state_machine" "hotel_booking" {
  name = "travel-platform-hotel-booking-dev"
}

data "aws_sfn_state_machine" "order_processing" {
  name = "travel-platform-order-processing-dev"
}

data "aws_sfn_state_machine" "payment_processing" {
  name = "travel-platform-payment-processing-dev"
}

# ============================================================================
# UNIFIED API GATEWAY
# ============================================================================

resource "aws_api_gateway_rest_api" "unified" {
  name        = "${var.project_name}-unified-api-${var.environment}"
  description = "Unified API Gateway for all microservices and workflows"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# API RESOURCES - Workflows
# ============================================================================

resource "aws_api_gateway_resource" "workflows" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  parent_id   = aws_api_gateway_rest_api.unified.root_resource_id
  path_part   = "workflows"
}

resource "aws_api_gateway_resource" "hotel_booking_workflow" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  parent_id   = aws_api_gateway_resource.workflows.id
  path_part   = "hotel-booking"
}

resource "aws_api_gateway_resource" "order_workflow" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  parent_id   = aws_api_gateway_resource.workflows.id
  path_part   = "order-processing"
}

resource "aws_api_gateway_resource" "payment_workflow" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  parent_id   = aws_api_gateway_resource.workflows.id
  path_part   = "payment-processing"
}

# ============================================================================
# IAM ROLE FOR API GATEWAY TO INVOKE STEP FUNCTIONS
# ============================================================================

resource "aws_iam_role" "api_gateway_sfn" {
  name = "${var.project_name}-api-gateway-sfn-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "api_gateway_sfn" {
  name = "${var.project_name}-api-gateway-sfn-${var.environment}"
  role = aws_iam_role.api_gateway_sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution",
          "states:StartSyncExecution"
        ]
        Resource = [
          data.aws_sfn_state_machine.hotel_booking.arn,
          data.aws_sfn_state_machine.order_processing.arn,
          data.aws_sfn_state_machine.payment_processing.arn
        ]
      }
    ]
  })
}

# ============================================================================
# API METHODS - Hotel Booking Workflow
# ============================================================================

resource "aws_api_gateway_method" "hotel_booking_post" {
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  resource_id   = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method   = "POST"
  authorization = "NONE"  # Add Cognito auth later if needed
}

resource "aws_api_gateway_integration" "hotel_booking_post" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_post.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  credentials             = aws_iam_role.api_gateway_sfn.arn

  request_templates = {
    "application/json" = jsonencode({
      stateMachineArn = data.aws_sfn_state_machine.hotel_booking.arn
      input           = "$util.escapeJavaScript($input.body)"
    })
  }
}

resource "aws_api_gateway_method_response" "hotel_booking_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "hotel_booking_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_post.http_method
  status_code = aws_api_gateway_method_response.hotel_booking_post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = jsonencode({
      executionArn = "$input.path('$.executionArn')"
      startDate    = "$input.path('$.startDate')"
      message      = "Workflow started successfully"
    })
  }

  depends_on = [aws_api_gateway_integration.hotel_booking_post]
}

# ============================================================================
# API METHODS - Order Processing Workflow
# ============================================================================

resource "aws_api_gateway_method" "order_workflow_post" {
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  resource_id   = aws_api_gateway_resource.order_workflow.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "order_workflow_post" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.order_workflow.id
  http_method = aws_api_gateway_method.order_workflow_post.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  credentials             = aws_iam_role.api_gateway_sfn.arn

  request_templates = {
    "application/json" = jsonencode({
      stateMachineArn = data.aws_sfn_state_machine.order_processing.arn
      input           = "$util.escapeJavaScript($input.body)"
    })
  }
}

resource "aws_api_gateway_method_response" "order_workflow_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.order_workflow.id
  http_method = aws_api_gateway_method.order_workflow_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "order_workflow_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.order_workflow.id
  http_method = aws_api_gateway_method.order_workflow_post.http_method
  status_code = aws_api_gateway_method_response.order_workflow_post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = jsonencode({
      executionArn = "$input.path('$.executionArn')"
      startDate    = "$input.path('$.startDate')"
      message      = "Order workflow started successfully"
    })
  }

  depends_on = [aws_api_gateway_integration.order_workflow_post]
}

# ============================================================================
# API METHODS - Payment Processing Workflow
# ============================================================================

resource "aws_api_gateway_method" "payment_workflow_post" {
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  resource_id   = aws_api_gateway_resource.payment_workflow.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "payment_workflow_post" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.payment_workflow.id
  http_method = aws_api_gateway_method.payment_workflow_post.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartExecution"
  credentials             = aws_iam_role.api_gateway_sfn.arn

  request_templates = {
    "application/json" = jsonencode({
      stateMachineArn = data.aws_sfn_state_machine.payment_processing.arn
      input           = "$util.escapeJavaScript($input.body)"
    })
  }
}

resource "aws_api_gateway_method_response" "payment_workflow_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.payment_workflow.id
  http_method = aws_api_gateway_method.payment_workflow_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "payment_workflow_post_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.payment_workflow.id
  http_method = aws_api_gateway_method.payment_workflow_post.http_method
  status_code = aws_api_gateway_method_response.payment_workflow_post_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = jsonencode({
      executionArn = "$input.path('$.executionArn')"
      startDate    = "$input.path('$.startDate')"
      message      = "Payment workflow started successfully"
    })
  }

  depends_on = [aws_api_gateway_integration.payment_workflow_post]
}

# ============================================================================
# CORS CONFIGURATION
# ============================================================================

# Hotel Booking CORS
resource "aws_api_gateway_method" "hotel_booking_options" {
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  resource_id   = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hotel_booking_options" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "hotel_booking_options_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "hotel_booking_options_200" {
  rest_api_id = aws_api_gateway_rest_api.unified.id
  resource_id = aws_api_gateway_resource.hotel_booking_workflow.id
  http_method = aws_api_gateway_method.hotel_booking_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.hotel_booking_options]
}

# ============================================================================
# API DEPLOYMENT
# ============================================================================

resource "aws_api_gateway_deployment" "unified" {
  rest_api_id = aws_api_gateway_rest_api.unified.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.hotel_booking_post.id,
      aws_api_gateway_integration.order_workflow_post.id,
      aws_api_gateway_integration.payment_workflow_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.hotel_booking_post,
    aws_api_gateway_integration.order_workflow_post,
    aws_api_gateway_integration.payment_workflow_post,
  ]
}

resource "aws_api_gateway_stage" "unified" {
  deployment_id = aws_api_gateway_deployment.unified.id
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
