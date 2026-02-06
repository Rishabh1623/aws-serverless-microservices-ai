terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.service_name}-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = concat(
      local.lambda_widgets,
      local.api_gateway_widgets,
      local.dynamodb_widgets,
      local.business_metrics_widgets
    )
  })
}

locals {
  # Lambda Metrics Widgets
  lambda_widgets = [
    {
      type = "metric"
      properties = {
        metrics = [
          for func_name in var.lambda_function_names : [
            "AWS/Lambda", "Invocations", { stat = "Sum", label = func_name }
          ]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "Lambda Invocations"
        yAxis = {
          left = {
            min = 0
          }
        }
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          for func_name in var.lambda_function_names : [
            "AWS/Lambda", "Errors", { stat = "Sum", label = func_name }
          ]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "Lambda Errors"
        yAxis = {
          left = {
            min = 0
          }
        }
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          for func_name in var.lambda_function_names : [
            "AWS/Lambda", "Duration", { stat = "Average", label = func_name }
          ]
        ]
        period = 300
        stat   = "Average"
        region = var.aws_region
        title  = "Lambda Duration (ms)"
        yAxis = {
          left = {
            min = 0
          }
        }
      }
    }
  ]
  
  # API Gateway Metrics Widgets
  api_gateway_widgets = [
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/ApiGateway", "Count", { stat = "Sum" }],
          [".", "4XXError", { stat = "Sum" }],
          [".", "5XXError", { stat = "Sum" }]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "API Gateway Requests"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/ApiGateway", "Latency", { stat = "Average" }],
          [".", "IntegrationLatency", { stat = "Average" }]
        ]
        period = 300
        stat   = "Average"
        region = var.aws_region
        title  = "API Gateway Latency (ms)"
      }
    }
  ]
  
  # DynamoDB Metrics Widgets
  dynamodb_widgets = [
    {
      type = "metric"
      properties = {
        metrics = [
          for table_name in var.dynamodb_table_names : [
            "AWS/DynamoDB", "ConsumedReadCapacityUnits", 
            { stat = "Sum", label = table_name }
          ]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "DynamoDB Read Capacity"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          for table_name in var.dynamodb_table_names : [
            "AWS/DynamoDB", "ConsumedWriteCapacityUnits", 
            { stat = "Sum", label = table_name }
          ]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "DynamoDB Write Capacity"
      }
    }
  ]
  
  # Business Metrics Widgets
  business_metrics_widgets = var.enable_business_metrics ? [
    {
      type = "metric"
      properties = {
        metrics = [
          ["${var.service_name}", "OrdersCreated", { stat = "Sum" }],
          [".", "OrdersCompleted", { stat = "Sum" }],
          [".", "OrdersFailed", { stat = "Sum" }]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "Business Metrics - Orders"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          ["${var.service_name}", "Revenue", { stat = "Sum" }]
        ]
        period = 300
        stat   = "Sum"
        region = var.aws_region
        title  = "Business Metrics - Revenue"
      }
    }
  ] : []
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)
  
  alarm_name          = "${var.service_name}-${each.key}-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Lambda function ${each.key} error rate exceeded"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = each.key
  }
  
  alarm_actions = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.service_name}-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.api_error_threshold
  alarm_description   = "API Gateway 5XX error rate exceeded"
  treat_missing_data  = "notBreaching"
  
  alarm_actions = var.alarm_actions
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.service_name}-alarms-${var.environment}"
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alarm_emails)
  
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}
