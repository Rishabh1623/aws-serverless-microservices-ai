output "api_gateway_url" {
  description = "Cart Service API Gateway URL"
  value       = module.cart_service.api_gateway_url
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = module.cart_service.lambda_function_names
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value       = module.cart_service.dynamodb_table_names
}

output "api_endpoint_ssm_parameter" {
  description = "SSM parameter for API endpoint"
  value       = module.cart_service.api_endpoint_ssm_parameter
}
