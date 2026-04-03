# ============================================================================
# DYNAMODB BACKUP & RECOVERY MODULE
# ============================================================================
# Enables Point-in-Time Recovery and automated backups

variable "table_names" {
  description = "List of DynamoDB table names to enable backup"
  type        = list(string)
}

variable "service_name" {
  description = "Service name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# ============================================================================
# POINT-IN-TIME RECOVERY
# ============================================================================

# PITR is enabled directly in the DynamoDB table definitions
# See lambda-service module: point_in_time_recovery { enabled = true }

# ============================================================================
# BACKUP PLAN
# ============================================================================

resource "aws_backup_vault" "main" {
  name = "${var.service_name}-${var.environment}-vault"

  tags = {
    Name        = "${var.service_name}-${var.environment}-vault"
    Environment = var.environment
    Service     = var.service_name
  }
}

resource "aws_backup_plan" "dynamodb" {
  name = "${var.service_name}-${var.environment}-dynamodb-backup"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"  # 2 AM UTC daily

    lifecycle {
      delete_after = var.backup_retention_days
    }

    recovery_point_tags = {
      Environment = var.environment
      Service     = var.service_name
      BackupType  = "Automated"
    }
  }

  # Weekly backup with longer retention
  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)"  # 3 AM UTC every Sunday

    lifecycle {
      delete_after = 90  # Keep weekly backups for 90 days
    }

    recovery_point_tags = {
      Environment = var.environment
      Service     = var.service_name
      BackupType  = "Weekly"
    }
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-backup-plan"
    Environment = var.environment
    Service     = var.service_name
  }
}

# ============================================================================
# BACKUP SELECTION
# ============================================================================

resource "aws_backup_selection" "dynamodb_tables" {
  name         = "${var.service_name}-${var.environment}-dynamodb-selection"
  plan_id      = aws_backup_plan.dynamodb.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    for table in var.table_names :
    "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${table}"
  ]
}

# ============================================================================
# IAM ROLE FOR AWS BACKUP
# ============================================================================

resource "aws_iam_role" "backup" {
  name = "${var.service_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.service_name}-${var.environment}-backup-role"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Attach AWS managed policy for DynamoDB backup
resource "aws_iam_role_policy" "backup_dynamodb" {
  name = "${var.service_name}-${var.environment}-backup-policy"
  role = aws_iam_role.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:CreateBackup"
        ]
        Resource = [
          for table in var.table_names :
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${table}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeBackup",
          "dynamodb:DeleteBackup"
        ]
        Resource = [
          for table in var.table_names :
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${table}/backup/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "restore_dynamodb" {
  name = "${var.service_name}-${var.environment}-restore-policy"
  role = aws_iam_role.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:RestoreTableFromBackup",
          "dynamodb:RestoreTableToPointInTime"
        ]
        Resource = [
          for table in var.table_names :
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${table}"
        ]
      }
    ]
  })
}

# ============================================================================
# BACKUP VAULT NOTIFICATIONS
# ============================================================================

resource "aws_sns_topic" "backup_notifications" {
  name = "${var.service_name}-${var.environment}-backup-notifications"

  tags = {
    Name        = "${var.service_name}-${var.environment}-backup-notifications"
    Environment = var.environment
    Service     = var.service_name
  }
}

resource "aws_backup_vault_notifications" "main" {
  backup_vault_name   = aws_backup_vault.main.name
  sns_topic_arn       = aws_sns_topic.backup_notifications.arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}

# Allow Backup service to publish to SNS
resource "aws_sns_topic_policy" "backup_notifications" {
  arn = aws_sns_topic.backup_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.backup_notifications.arn
    }]
  })
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# OUTPUTS
# ============================================================================

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.dynamodb.id
}

output "backup_notifications_topic_arn" {
  description = "ARN of backup notifications SNS topic"
  value       = aws_sns_topic.backup_notifications.arn
}
