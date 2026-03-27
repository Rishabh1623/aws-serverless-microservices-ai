# ============================================================================
# LAMBDA LAYER FOR SHARED LIBRARIES
# ============================================================================

# Package shared Python libraries
data "archive_file" "shared_layer" {
  type        = "zip"
  output_path = "${path.module}/lambda_packages/shared_layer.zip"

  source {
    content  = file("${path.module}/../../../shared/python/dynamodb_transactions.py")
    filename = "python/dynamodb_transactions.py"
  }

  source {
    content  = file("${path.module}/../../../shared/python/resilience.py")
    filename = "python/resilience.py"
  }

  source {
    content  = file("${path.module}/../../../shared/python/secrets_helper.py")
    filename = "python/secrets_helper.py"
  }
}

resource "aws_lambda_layer_version" "shared_libraries" {
  filename            = data.archive_file.shared_layer.output_path
  layer_name          = "${var.service_name}-shared-${var.environment}"
  compatible_runtimes = [var.lambda_runtime]

  description = "Shared libraries for ${var.service_name}"
}

# Attach layer to Lambda functions
resource "aws_lambda_function" "attach_layer" {
  for_each = module.hotel_service.lambda_functions

  function_name = each.value.function_name
  layers        = [aws_lambda_layer_version.shared_libraries.arn]

  # This is a workaround - in production, add layers to lambda-service module
  lifecycle {
    ignore_changes = [layers]
  }
}
