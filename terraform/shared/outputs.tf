output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_lock_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "aws_543927035352" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.543927035352
}
