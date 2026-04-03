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
