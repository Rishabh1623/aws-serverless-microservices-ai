/**
 * Step Functions Workflow Module
 * 
 * Creates AWS Step Functions state machines with best practices:
 * - CloudWatch Logs integration
 * - X-Ray tracing
 * - Error handling and retries
 * - IAM roles with least privilege
 */

# ============================================================================
# VARIABLES
# ============================================================================

variable "workflow_name" {
  description = "Name of the Step Functions workflow"
  type        = string
}

variable "definition" {
  description = "Step Functions state machine definition (Amazon States Language)"
  type        = string
}

variable "workflow_type" {
  description = "Type of workflow: STANDARD or EXPRESS"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.workflow_type)
    error_message = "Workflow type must be STANDARD or EXPRESS"
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "lambda_arns" {
  description = "Map of Lambda function ARNs that the workflow will invoke"
  type        = map(string)
  default     = {}
}

variable "dynamodb_arns" {
  description = "List of DynamoDB table ARNs the workflow needs access to"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "workflow" {
  name              = "/aws/vendedlogs/states/${var.workflow_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.workflow_name}-logs"
  })
}

# ============================================================================
# IAM ROLE FOR STEP FUNCTIONS
# ============================================================================

resource "aws_iam_role" "workflow" {
  name = "${var.workflow_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.workflow_name}-role"
  })
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.workflow_name}-cloudwatch-logs"
  role = aws_iam_role.workflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# X-Ray tracing permissions
resource "aws_iam_role_policy" "xray" {
  name = "${var.workflow_name}-xray"
  role = aws_iam_role.workflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda invocation permissions
resource "aws_iam_role_policy" "lambda_invoke" {
  count = length(var.lambda_arns) > 0 ? 1 : 0
  
  name = "${var.workflow_name}-lambda-invoke"
  role = aws_iam_role.workflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = values(var.lambda_arns)
      }
    ]
  })
}

# DynamoDB permissions
resource "aws_iam_role_policy" "dynamodb" {
  count = length(var.dynamodb_arns) > 0 ? 1 : 0
  
  name = "${var.workflow_name}-dynamodb"
  role = aws_iam_role.workflow.id

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
        Resource = var.dynamodb_arns
      }
    ]
  })
}

# ============================================================================
# STEP FUNCTIONS STATE MACHINE
# ============================================================================

resource "aws_sfn_state_machine" "workflow" {
  name     = var.workflow_name
  role_arn = aws_iam_role.workflow.arn
  type     = var.workflow_type

  definition = var.definition

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.workflow.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = var.workflow_name
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.workflow.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.workflow.name
}

output "role_arn" {
  description = "ARN of the IAM role used by the state machine"
  value       = aws_iam_role.workflow.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.workflow.name
}
