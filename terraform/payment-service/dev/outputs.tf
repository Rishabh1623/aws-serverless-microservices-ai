output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.payment_service.api_gateway_url
}

output "lambda_functions" {
  description = "Lambda function details"
  value = {
    for key, func in module.payment_service.lambda_functions : key => {
      arn           = func.arn
      function_name = func.function_name
    }
  }
}

output "dynamodb_tables" {
  description = "DynamoDB table details"
  value = {
    for key, table in module.payment_service.dynamodb_tables : key => {
      name = table.name
      arn  = table.arn
    }
  }
}

output "stripe_secret_arn" {
  description = "Stripe secret ARN"
  value       = module.secrets.secret_arns["stripe"]
  sensitive   = true
}
