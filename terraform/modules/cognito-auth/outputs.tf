output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.main.id
}

output "authorizer_id" {
  description = "API Gateway Cognito Authorizer ID"
  value       = aws_api_gateway_authorizer.cognito.id
}

output "login_url" {
  description = "Cognito hosted UI login URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=code&redirect_uri=${var.callback_urls[0]}"
}

data "aws_region" "current" {}
