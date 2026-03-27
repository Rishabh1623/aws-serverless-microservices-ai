# ============================================================================
# COGNITO USER POOL MODULE
# ============================================================================
# Provides authentication and authorization for the travel platform
# Features: User registration, login, MFA, password policies, JWT tokens

variable "service_name" {
  description = "Service name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "callback_urls" {
  description = "Allowed callback URLs after authentication"
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "logout_urls" {
  description = "Allowed logout URLs"
  type        = list(string)
  default     = ["http://localhost:5173"]
}

# ============================================================================
# COGNITO USER POOL
# ============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.service_name}-${var.environment}"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

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
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Custom attributes for travel platform
  schema {
    name                = "loyalty_tier"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 20
    }
  }

  # MFA configuration
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Tags
  tags = {
    Name        = "${var.service_name}-${var.environment}"
    Environment = var.environment
    Service     = var.service_name
  }
}

# ============================================================================
# COGNITO USER POOL CLIENT
# ============================================================================

resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.service_name}-${var.environment}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Token validity
  id_token_validity      = 60  # minutes
  access_token_validity  = 60  # minutes
  refresh_token_validity = 30  # days

  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  # Security
  prevent_user_existence_errors = "ENABLED"
  
  # Read/write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "custom:loyalty_tier"
  ]

  write_attributes = [
    "email",
    "name"
  ]
}

# ============================================================================
# COGNITO USER POOL DOMAIN
# ============================================================================

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.service_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

data "aws_caller_identity" "current" {}

# ============================================================================
# COGNITO IDENTITY POOL (for AWS service access)
# ============================================================================

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.service_name}_${var.environment}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.web.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "${var.service_name}-${var.environment}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
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
    }]
  })
}

# Attach policy to authenticated role
resource "aws_iam_role_policy" "authenticated" {
  name = "${var.service_name}-${var.environment}-authenticated-policy"
  role = aws_iam_role.authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*",
          "cognito-identity:*"
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

# ============================================================================
# OUTPUTS
# ============================================================================

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.main.id
}

output "hosted_ui_url" {
  description = "Cognito Hosted UI URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

data "aws_region" "current" {}
