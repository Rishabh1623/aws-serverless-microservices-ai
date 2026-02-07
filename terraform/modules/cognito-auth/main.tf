terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.service_name}-user-pool-${var.environment}"
  
  # Password policy
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }
  
  # MFA configuration
  mfa_configuration = var.environment == "prod" ? "OPTIONAL" : "OFF"
  
  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
    
    string_attribute_constraints {
      min_length = 5
      max_length = 255
    }
  }
  
  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    
    string_attribute_constraints {
      min_length = 1
      max_length = 255
    }
  }
  
  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  # Auto-verified attributes
  auto_verified_attributes = ["email"]
  
  # Username configuration
  username_attributes = ["email"]
  
  # Advanced security
  user_pool_add_ons {
    advanced_security_mode = var.environment == "prod" ? "ENFORCED" : "AUDIT"
  }
  
  # Lambda triggers (optional)
  dynamic "lambda_config" {
    for_each = var.lambda_triggers
    content {
      pre_sign_up       = lookup(lambda_config.value, "pre_sign_up", null)
      post_confirmation = lookup(lambda_config.value, "post_confirmation", null)
      pre_authentication = lookup(lambda_config.value, "pre_authentication", null)
    }
  }
  
  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.service_name}-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
  
  # OAuth settings
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  
  # Token validity
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour
  refresh_token_validity = 30 # 30 days
  
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  
  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"
  
  # Read/write attributes
  read_attributes  = ["email", "name", "email_verified"]
  write_attributes = ["email", "name"]
  
  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.service_name}-${var.environment}-${data.aws_caller_identity.current.543927035352}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Cognito Identity Pool (for AWS credentials)
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.service_name}_identity_pool_${var.environment}"
  allow_unauthenticated_identities = false
  
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "${var.service_name}-cognito-authenticated-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# IAM policy for authenticated users
resource "aws_iam_role_policy" "authenticated" {
  name = "${var.service_name}-cognito-authenticated-policy-${var.environment}"
  role = aws_iam_role.authenticated.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-identity:GetCredentialsForIdentity",
          "cognito-identity:GetId"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach roles to identity pool
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id
  
  roles = {
    authenticated = aws_iam_role.authenticated.arn
  }
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.service_name}-cognito-authorizer-${var.environment}"
  rest_api_id     = var.api_gateway_id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.main.arn]
  identity_source = "method.request.header.Authorization"
}

# CloudWatch Log Group for Cognito
resource "aws_cloudwatch_log_group" "cognito" {
  name              = "/aws/cognito/${var.service_name}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

# Data source
data "aws_caller_identity" "current" {}
