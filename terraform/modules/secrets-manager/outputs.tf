output "secret_arns" {
  description = "ARNs of created secrets"
  value       = { for k, v in aws_secretsmanager_secret.secrets : k => v.arn }
}

output "secret_ids" {
  description = "IDs of created secrets"
  value       = { for k, v in aws_secretsmanager_secret.secrets : k => v.id }
}

output "kms_key_id" {
  description = "KMS key ID for secrets encryption"
  value       = aws_kms_key.secrets.id
}

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "secrets_access_policy_arn" {
  description = "IAM policy ARN for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}
