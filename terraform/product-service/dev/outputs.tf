output "api_gateway_url" {
  description = "Product Service API Gateway URL"
  value       = module.product_service.api_gateway_url
}

output "lambda_function_names" {
  description = "Product Service Lambda function names"
  value       = module.product_service.lambda_function_names
}

output "dynamodb_table_names" {
  description = "Product Service DynamoDB table names"
  value       = module.product_service.dynamodb_table_names
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for API Gateway"
  value       = module.product_service.cloudwatch_log_group
}
