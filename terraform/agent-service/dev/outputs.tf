output "api_gateway_url" {
  description = "Agent Service API Gateway URL"
  value       = aws_apigatewayv2_api.agent.api_endpoint
}

output "api_endpoint" {
  description = "Agent Service API endpoint (full URL with /agent path)"
  value       = "${aws_apigatewayv2_api.agent.api_endpoint}/agent"
}

output "lambda_function_name" {
  description = "Agent Lambda function name"
  value       = aws_lambda_function.agent_package.function_name
}

output "lambda_function_arn" {
  description = "Agent Lambda function ARN"
  value       = aws_lambda_function.agent_package.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Agent Lambda"
  value       = aws_cloudwatch_log_group.agent.name
}

output "conversation_table_name" {
  description = "DynamoDB table for conversation history"
  value       = aws_dynamodb_table.conversations.name
}
