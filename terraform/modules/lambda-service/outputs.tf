output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "lambda_function_arns" {
  description = "ARNs of Lambda functions"
  value       = { for k, v in aws_lambda_function.functions : k => v.arn }
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = { for k, v in aws_lambda_function.functions : k => v.function_name }
}

output "dynamodb_table_names" {
  description = "Names of DynamoDB tables"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.name }
}

output "dynamodb_table_arns" {
  description = "ARNs of DynamoDB tables"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.arn }
}

output "api_endpoint_ssm_parameter" {
  description = "SSM parameter name for API endpoint"
  value       = aws_ssm_parameter.api_endpoint.name
}
