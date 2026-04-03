# ============================================================================
# SECRETS MANAGER MODULE
# ============================================================================
# Manages sensitive configuration and API keys securely

variable "service_name" {
  description = "Service name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "secrets" {
  description = "Map of secret names to values"
  type        = map(string)
  sensitive   = false
}

variable "rotation_enabled" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

# ============================================================================
# SECRETS
# ============================================================================

resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets

  name        = "${var.service_name}/${var.environment}/${each.key}"
  description = "Secret for ${each.key} in ${var.service_name} ${var.environment}"

  tags = {
    Name        = "${var.service_name}-${var.environment}-${each.key}"
    Environment = var.environment
    Service     = var.service_name
  }
}

resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = each.value
}

# ============================================================================
# IAM POLICY FOR LAMBDA ACCESS
# ============================================================================

resource "aws_iam_policy" "secrets_access" {
  name        = "${var.service_name}-${var.environment}-secrets-access"
  description = "Allow Lambda functions to read secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [for secret in aws_secretsmanager_secret.secrets : secret.arn]
      }
    ]
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "secret_arns" {
  description = "ARNs of created secrets"
  value       = { for k, v in aws_secretsmanager_secret.secrets : k => v.arn }
}

output "secrets_access_policy_arn" {
  description = "IAM policy ARN for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}
