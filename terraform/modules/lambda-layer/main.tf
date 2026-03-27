# ============================================================================
# LAMBDA LAYER MODULE
# ============================================================================
# Shared Python libraries for Lambda functions

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "layer_name" {
  description = "Lambda layer name"
  type        = string
  default     = "travel-platform-shared"
}

variable "source_path" {
  description = "Path to shared Python libraries"
  type        = string
}

variable "compatible_runtimes" {
  description = "Compatible Lambda runtimes"
  type        = list(string)
  default     = ["python3.11", "python3.12"]
}

# ============================================================================
# PACKAGE LAMBDA LAYER
# ============================================================================

data "archive_file" "layer" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/layer.zip"
}

# ============================================================================
# LAMBDA LAYER
# ============================================================================

resource "aws_lambda_layer_version" "shared" {
  filename            = data.archive_file.layer.output_path
  layer_name          = "${var.layer_name}-${var.environment}"
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = var.compatible_runtimes
  
  description = "Shared libraries for ${var.environment} environment"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "layer_arn" {
  description = "Lambda layer ARN"
  value       = aws_lambda_layer_version.shared.arn
}

output "layer_version" {
  description = "Lambda layer version"
  value       = aws_lambda_layer_version.shared.version
}
