variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_observability_mcp_url" {
  description = "AWS Observability MCP server URL (unified server from mcp-servers deployment)"
  type        = string
}

variable "alert_email" {
  description = "Email address for production alerts"
  type        = string
}
