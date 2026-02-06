variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
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
  description = "Email address for pipeline approval notifications"
  type        = string
}
