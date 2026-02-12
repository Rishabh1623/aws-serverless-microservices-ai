variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "product_api_url" {
  description = "Product Service API URL for enriching cart items"
  type        = string
  default     = "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev"
}
