variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    description      = string
    type            = string
    value           = map(string)
    rotation_enabled = bool
    rotation_days   = number
  }))
}

variable "rotation_lambda_arn" {
  description = "ARN of Lambda function for secret rotation"
  type        = string
  default     = ""
}
