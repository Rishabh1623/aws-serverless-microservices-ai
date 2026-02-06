terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# KMS Key for Secrets Encryption
resource "aws_kms_key" "secrets" {
  description             = "KMS key for ${var.service_name} secrets encryption"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  enable_key_rotation     = true
  
  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.service_name}-secrets-${var.environment}"
  target_key_id = aws_kms_key.secrets.key_id
}

# Secrets Manager Secrets
resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets
  
  name        = "${var.service_name}/${var.environment}/${each.key}"
  description = each.value.description
  kms_key_id  = aws_kms_key.secrets.id
  
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = {
    Service     = var.service_name
    Environment = var.environment
    SecretType  = each.value.type
  }
}

# Secret Versions
resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = var.secrets
  
  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode(each.value.value)
}

# Rotation Configuration (for supported secret types)
resource "aws_secretsmanager_secret_rotation" "secrets" {
  for_each = {
    for k, v in var.secrets : k => v
    if v.rotation_enabled
  }
  
  secret_id           = aws_secretsmanager_secret.secrets[each.key].id
  rotation_lambda_arn = var.rotation_lambda_arn
  
  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }
}

# IAM Policy for Lambda to access secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.service_name}-secrets-access-${var.environment}"
  description = "Allow Lambda functions to access secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.secrets : secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}

# CloudWatch Log Group for secret access
resource "aws_cloudwatch_log_group" "secrets_access" {
  name              = "/aws/secretsmanager/${var.service_name}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 90 : 7
}

# CloudWatch Alarm for unauthorized access attempts
resource "aws_cloudwatch_metric_alarm" "unauthorized_access" {
  alarm_name          = "${var.service_name}-secrets-unauthorized-access-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICallsCount"
  namespace           = "AWS/SecretsManager"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert on unauthorized secret access attempts"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ServiceName = var.service_name
  }
}
