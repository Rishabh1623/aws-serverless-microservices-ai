output "api_gateway_url" {
  description = "API Gateway URL for Troubleshooting Agent"
  value       = aws_apigatewayv2_api.troubleshooting_agent.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.troubleshooting_agent.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.troubleshooting_agent.arn
}

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.troubleshooting_agent_dlq.url
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.troubleshooting_agent_alerts.arn
}
