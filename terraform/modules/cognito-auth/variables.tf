variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "api_gateway_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "callback_urls" {
  description = "Callback URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "Logout URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/logout"]
}

variable "lambda_triggers" {
  description = "Lambda triggers for Cognito"
  type        = map(any)
  default     = {}
}
