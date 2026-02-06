variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    filename                = string
    handler                 = string
    runtime                 = string
    memory_size             = number
    timeout                 = number
    environment_variables   = map(string)
  }))
}

variable "api_gateway_resources" {
  description = "API Gateway resources"
  type = map(object({
    path_part = string
  }))
}

variable "api_gateway_methods" {
  description = "API Gateway methods"
  type = map(object({
    resource_key = string
    http_method  = string
    lambda_key   = string
  }))
}

variable "dynamodb_tables" {
  description = "DynamoDB tables to create"
  type = map(object({
    hash_key  = string
    range_key = optional(string)
    attributes = list(object({
      name = string
      type = string
    }))
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      projection_type = string
    })))
  }))
}
