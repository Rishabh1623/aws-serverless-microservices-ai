output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "CloudWatch Dashboard ARN"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "alarm_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_arns" {
  description = "ARNs of created CloudWatch alarms"
  value = merge(
    { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn },
    { "api_gateway_5xx" = aws_cloudwatch_metric_alarm.api_gateway_5xx.arn }
  )
}
