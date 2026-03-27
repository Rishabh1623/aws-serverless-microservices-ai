# ============================================================================
# DAX CACHE MODULE
# ============================================================================
# DynamoDB Accelerator (DAX) for microsecond read latency

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "DAX cluster name"
  type        = string
  default     = "travel-platform-dax"
}

variable "node_type" {
  description = "DAX node type"
  type        = string
  default     = "dax.t3.small"  # Smallest instance for dev
}

variable "replication_factor" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 1  # 1 for dev, 3 for prod
}

variable "subnet_ids" {
  description = "List of subnet IDs for DAX cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

# ============================================================================
# DAX SUBNET GROUP
# ============================================================================

resource "aws_dax_subnet_group" "main" {
  name       = "${var.cluster_name}-${var.environment}"
  subnet_ids = var.subnet_ids
  
  description = "DAX subnet group for ${var.environment}"
}

# ============================================================================
# SECURITY GROUP
# ============================================================================

resource "aws_security_group" "dax" {
  name        = "${var.cluster_name}-${var.environment}-sg"
  description = "Security group for DAX cluster"
  vpc_id      = var.vpc_id
  
  # Allow inbound from Lambda (port 8111)
  ingress {
    from_port   = 8111
    to_port     = 8111
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Adjust to your VPC CIDR
    description = "DAX cluster access"
  }
  
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.cluster_name}-${var.environment}-sg"
    Environment = var.environment
  }
}

# ============================================================================
# IAM ROLE FOR DAX
# ============================================================================

resource "aws_iam_role" "dax" {
  name = "${var.cluster_name}-${var.environment}-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "dax.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "dax_dynamodb" {
  name = "dax-dynamodb-access"
  role = aws_iam_role.dax.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# DAX PARAMETER GROUP
# ============================================================================

resource "aws_dax_parameter_group" "main" {
  name = "${var.cluster_name}-${var.environment}"
  
  parameters {
    name  = "query-ttl-millis"
    value = "300000"  # 5 minutes
  }
  
  parameters {
    name  = "record-ttl-millis"
    value = "300000"  # 5 minutes
  }
}

# ============================================================================
# DAX CLUSTER
# ============================================================================

resource "aws_dax_cluster" "main" {
  cluster_name       = "${var.cluster_name}-${var.environment}"
  iam_role_arn       = aws_iam_role.dax.arn
  node_type          = var.node_type
  replication_factor = var.replication_factor
  
  subnet_group_name  = aws_dax_subnet_group.main.name
  security_group_ids = [aws_security_group.dax.id]
  parameter_group_name = aws_dax_parameter_group.main.name
  
  # Encryption
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name        = "${var.cluster_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "cluster_arn" {
  description = "DAX cluster ARN"
  value       = aws_dax_cluster.main.arn
}

output "cluster_endpoint" {
  description = "DAX cluster endpoint"
  value       = aws_dax_cluster.main.cluster_address
}

output "cluster_port" {
  description = "DAX cluster port"
  value       = aws_dax_cluster.main.port
}

output "configuration_endpoint" {
  description = "DAX configuration endpoint"
  value       = aws_dax_cluster.main.configuration_endpoint
}
