variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "hotel_api_url" {
  description = "Hotel Service API URL"
  type        = string
  default     = "https://api.example.com/hotels"
}

variable "cart_api_url" {
  description = "Cart Service API URL"
  type        = string
  default     = "https://api.example.com/cart"
}

variable "order_api_url" {
  description = "Order Service API URL"
  type        = string
  default     = "https://api.example.com/orders"
}

variable "payment_api_url" {
  description = "Payment Service API URL"
  type        = string
  default     = "https://api.example.com/payments"
}

variable "bedrock_model_id" {
  description = "AWS Bedrock model ID for the AI agent"
  type        = string
  default     = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
}
