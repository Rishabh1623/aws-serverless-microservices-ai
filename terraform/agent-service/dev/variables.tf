variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "product_api_url" {
  description = "Product Service API URL"
  type        = string
  # Get this from Product Service deployment output
  # Example: "https://abc123.execute-api.us-east-1.amazonaws.com"
}

variable "cart_api_url" {
  description = "Cart Service API URL"
  type        = string
  # Get this from Cart Service deployment output
}

variable "order_api_url" {
  description = "Order Service API URL"
  type        = string
  # Get this from Order Service deployment output
}

variable "payment_api_url" {
  description = "Payment Service API URL"
  type        = string
  # Get this from Payment Service deployment output
}
