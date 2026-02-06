variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
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
  description = "Email for manual approval notifications"
  type        = string
}

variable "buildspec_path" {
  description = "Path to buildspec file"
  type        = string
  default     = "buildspec.yml"
}

variable "testspec_path" {
  description = "Path to testspec file"
  type        = string
  default     = "testspec.yml"
}

variable "integration_testspec_path" {
  description = "Path to integration testspec file"
  type        = string
  default     = "integration-testspec.yml"
}
