output "api_gateway_url" {
  description = "Agent Service API Gateway URL"
  value       = aws_apigatewayv2_api.agent.api_endpoint
}

output "lambda_function_name" {
  description = "Agent Lambda function name"
  value       = aws_lambda_function.agent.function_name
}

output "lambda_function_arn" {
  description = "Agent Lambda function ARN"
  value       = aws_lambda_function.agent.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Agent Lambda"
  value       = aws_cloudwatch_log_group.agent.name
}
