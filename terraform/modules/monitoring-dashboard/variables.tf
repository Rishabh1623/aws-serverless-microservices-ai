variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
}

variable "dynamodb_table_names" {
  description = "List of DynamoDB table names to monitor"
  type        = list(string)
}

variable "enable_business_metrics" {
  description = "Enable business metrics widgets"
  type        = bool
  default     = true
}

variable "error_threshold" {
  description = "Threshold for Lambda error alarms"
  type        = number
  default     = 5
}

variable "api_error_threshold" {
  description = "Threshold for API Gateway error alarms"
  type        = number
  default     = 10
}

variable "alarm_emails" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}
