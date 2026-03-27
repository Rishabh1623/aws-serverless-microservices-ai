# ============================================================================
# IDEMPOTENCY TABLE MODULE
# ============================================================================
# Prevents duplicate API requests by storing request IDs and responses
# Used for: Booking creation, payment processing, order creation

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name for idempotency keys"
  type        = string
  default     = "idempotency-keys"
}

variable "ttl_days" {
  description = "Number of days to keep idempotency records"
  type        = number
  default     = 7
}

# ============================================================================
# DYNAMODB TABLE
# ============================================================================

resource "aws_dynamodb_table" "idempotency" {
  name           = "${var.table_name}-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing
  hash_key       = "idempotencyKey"
  
  attribute {
    name = "idempotencyKey"
    type = "S"
  }
  
  # TTL to auto-delete old records
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
  
  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }
  
  # Encryption at rest
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name        = "${var.table_name}-${var.environment}"
    Environment = var.environment
    Purpose     = "Idempotency"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "table_name" {
  description = "Idempotency table name"
  value       = aws_dynamodb_table.idempotency.name
}

output "table_arn" {
  description = "Idempotency table ARN"
  value       = aws_dynamodb_table.idempotency.arn
}
