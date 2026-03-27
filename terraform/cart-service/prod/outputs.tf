output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = module.cart_service.api_gateway_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = module.cart_service.api_gateway_id
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = module.cart_service.lambda_function_names
}

output "lambda_function_arns" {
  description = "ARNs of Lambda functions"
  value       = module.cart_service.lambda_function_arns
}

output "dynamodb_table_names" {
  description = "Names of DynamoDB tables"
  value       = module.cart_service.dynamodb_table_names
}

output "dynamodb_table_arns" {
  description = "ARNs of DynamoDB tables"
  value       = module.cart_service.dynamodb_table_arns
}
