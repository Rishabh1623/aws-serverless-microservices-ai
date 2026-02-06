variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "product_api_url" {
  description = "Product Service API URL (Production)"
  type        = string
}

variable "cart_api_url" {
  description = "Cart Service API URL (Production)"
  type        = string
}

variable "order_api_url" {
  description = "Order Service API URL (Production)"
  type        = string
}

variable "payment_api_url" {
  description = "Payment Service API URL (Production)"
  type        = string
}

variable "allowed_origins" {
  description = "Allowed CORS origins for production"
  type        = list(string)
  default     = ["https://yourdomain.com"]  # Replace with your actual domain
}

variable "alert_email" {
  description = "Email address for production alerts"
  type        = string
}
