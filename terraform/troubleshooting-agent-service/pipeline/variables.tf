variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub repository owner (username or organization)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "serverless-microservices"
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "approval_email" {
  description = "Email address for deployment approval notifications"
  type        = string
}
