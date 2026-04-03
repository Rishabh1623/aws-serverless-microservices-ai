variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "payment-service"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "stripe_api_key" {
  description = "Stripe API key (will be stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = "sk_test_demo_key"
}
