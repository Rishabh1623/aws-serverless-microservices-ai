# ============================================================================
# OUTPUTS
# ============================================================================

output "state_machine_arn" {
  description = "ARN of the payment processing workflow"
  value       = module.payment_workflow.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the payment processing workflow"
  value       = module.payment_workflow.state_machine_name
}

output "log_group_name" {
  description = "CloudWatch log group for workflow execution logs"
  value       = module.payment_workflow.log_group_name
}

output "role_arn" {
  description = "IAM role ARN used by the state machine"
  value       = module.payment_workflow.role_arn
}
