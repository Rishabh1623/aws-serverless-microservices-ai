variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "agent-service"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# API Endpoints
variable "product_api_url" {
  description = "Product service API URL"
  type        = string
  default     = "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev"
}

variable "cart_api_url" {
  description = "Cart service API URL"
  type        = string
  default     = "https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev"
}

variable "order_api_url" {
  description = "Order service API URL"
  type        = string
  default     = "https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev"
}

variable "payment_api_url" {
  description = "Payment service API URL"
  type        = string
  default     = "https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev"
}

# Lambda Configuration
variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = 50
}

# Bedrock Configuration
variable "bedrock_model_id" {
  description = "AWS Bedrock model ID"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

# Monitoring
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "your-email@example.com"
}

# API Gateway
variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 500
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 200
}

# Alarms
variable "error_threshold" {
  description = "Error count threshold for alarms"
  type        = number
  default     = 10
}

variable "duration_threshold" {
  description = "Duration threshold in milliseconds for alarms"
  type        = number
  default     = 30000
}

variable "cost_threshold" {
  description = "Daily cost threshold in USD for alarms"
  type        = number
  default     = 50
}
