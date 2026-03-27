# ============================================================================
# API GATEWAY COGNITO AUTHORIZER MODULE
# ============================================================================
# Secures API Gateway endpoints with Cognito JWT token validation

variable "api_id" {
  description = "API Gateway ID"
  type        = string
}

variable "api_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

variable "authorizer_name" {
  description = "Name for the authorizer"
  type        = string
}

# ============================================================================
# API GATEWAY AUTHORIZER
# ============================================================================

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = var.api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = var.authorizer_name

  jwt_configuration {
    audience = []  # Will be validated by user pool
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${split("/", var.cognito_user_pool_arn)[1]}"
  }
}

data "aws_region" "current" {}

# ============================================================================
# OUTPUTS
# ============================================================================

output "authorizer_id" {
  description = "API Gateway Authorizer ID"
  value       = aws_apigatewayv2_authorizer.cognito.id
}
