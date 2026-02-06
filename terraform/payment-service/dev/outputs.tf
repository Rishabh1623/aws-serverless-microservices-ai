output "api_gateway_url" {
  description = "Payment Service API Gateway URL"
  value       = module.payment_service.api_gateway_url
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = module.payment_service.lambda_function_names
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value       = module.payment_service.dynamodb_table_names
}
