output "aws_observability_mcp_url" {
  description = "AWS Observability MCP server URL (unified server for Logs, Metrics, Services)"
  value       = "${aws_apigatewayv2_api.aws_observability_mcp.api_endpoint}/mcp"
}

output "aws_observability_mcp_function_name" {
  description = "AWS Observability MCP Lambda function name"
  value       = aws_lambda_function.aws_observability_mcp.function_name
}

output "aws_observability_mcp_function_arn" {
  description = "AWS Observability MCP Lambda function ARN"
  value       = aws_lambda_function.aws_observability_mcp.arn
}

output "aws_observability_mcp_api_id" {
  description = "API Gateway ID for MCP server"
  value       = aws_apigatewayv2_api.aws_observability_mcp.id
}

output "aws_observability_mcp_log_group" {
  description = "CloudWatch Log Group for MCP server"
  value       = aws_cloudwatch_log_group.aws_observability_mcp.name
}

# Summary output for easy reference
output "mcp_server_summary" {
  description = "Summary of MCP server deployment"
  value = {
    server_url      = "${aws_apigatewayv2_api.aws_observability_mcp.api_endpoint}/mcp"
    function_name   = aws_lambda_function.aws_observability_mcp.function_name
    environment     = var.environment
    tools_count     = 11
    tools_categories = "CloudWatch Logs (4), CloudWatch Metrics (3), AWS Services (4)"
  }
}
