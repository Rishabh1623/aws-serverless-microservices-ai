# ============================================================================
# EVENT-DRIVEN ARCHITECTURE MODULE
# ============================================================================
# EventBridge + SNS + SQS for async processing and notifications

variable "service_name" {
  description = "Service name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "event_bus_name" {
  description = "EventBridge event bus name"
  type        = string
  default     = "default"
}

# ============================================================================
# EVENTBRIDGE EVENT BUS
# ============================================================================

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.service_name}-${var.environment}"

  tags = {
    Name        = "${var.service_name}-${var.environment}"
    Environment = var.environment
    Service     = var.service_name
  }
}

# ============================================================================
# SNS TOPICS
# ============================================================================

# Booking notifications
resource "aws_sns_topic" "booking_notifications" {
  name              = "${var.service_name}-${var.environment}-booking-notifications"
  display_name      = "Booking Notifications"
  fifo_topic        = false
  
  # Enable encryption
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.service_name}-${var.environment}-booking-notifications"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Payment notifications
resource "aws_sns_topic" "payment_notifications" {
  name              = "${var.service_name}-${var.environment}-payment-notifications"
  display_name      = "Payment Notifications"
  fifo_topic        = false
  
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.service_name}-${var.environment}-payment-notifications"
    Environment = var.environment
    Service     = var.service_name
  }
}

# System alerts
resource "aws_sns_topic" "system_alerts" {
  name              = "${var.service_name}-${var.environment}-system-alerts"
  display_name      = "System Alerts"
  fifo_topic        = false
  
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.service_name}-${var.environment}-system-alerts"
    Environment = var.environment
    Service     = var.service_name
  }
}

# ============================================================================
# SQS QUEUES
# ============================================================================

# Booking processing queue
resource "aws_sqs_queue" "booking_processing" {
  name                       = "${var.service_name}-${var.environment}-booking-processing"
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 10      # Long polling
  visibility_timeout_seconds = 300     # 5 minutes

  # Dead letter queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.booking_processing_dlq.arn
    maxReceiveCount     = 3
  })

  # Encryption
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.service_name}-${var.environment}-booking-processing"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Booking processing DLQ
resource "aws_sqs_queue" "booking_processing_dlq" {
  name                      = "${var.service_name}-${var.environment}-booking-processing-dlq"
  message_retention_seconds = 1209600 # 14 days
  
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.service_name}-${var.environment}-booking-processing-dlq"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Email queue
resource "aws_sqs_queue" "email_queue" {
  name                       = "${var.service_name}-${var.environment}-email-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60      # 1 minute

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_queue_dlq.arn
    maxReceiveCount     = 5
  })

  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.service_name}-${var.environment}-email-queue"
    Environment = var.environment
    Service     = var.service_name
  }
}

# Email queue DLQ
resource "aws_sqs_queue" "email_queue_dlq" {
  name                      = "${var.service_name}-${var.environment}-email-queue-dlq"
  message_retention_seconds = 1209600
  
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.service_name}-${var.environment}-email-queue-dlq"
    Environment = var.environment
    Service     = var.service_name
  }
}

# ============================================================================
# SNS TO SQS SUBSCRIPTIONS
# ============================================================================

# Subscribe booking queue to booking notifications
resource "aws_sns_topic_subscription" "booking_to_queue" {
  topic_arn = aws_sns_topic.booking_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.booking_processing.arn

  # Filter policy (optional)
  filter_policy = jsonencode({
    event_type = ["booking_created", "booking_updated", "booking_cancelled"]
  })
}

# Subscribe email queue to booking notifications
resource "aws_sns_topic_subscription" "booking_to_email" {
  topic_arn = aws_sns_topic.booking_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_queue.arn

  filter_policy = jsonencode({
    event_type = ["booking_confirmed"]
  })
}

# ============================================================================
# SQS QUEUE POLICIES
# ============================================================================

# Allow SNS to send to booking queue
resource "aws_sqs_queue_policy" "booking_processing" {
  queue_url = aws_sqs_queue.booking_processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.booking_processing.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.booking_notifications.arn
        }
      }
    }]
  })
}

# Allow SNS to send to email queue
resource "aws_sqs_queue_policy" "email_queue" {
  queue_url = aws_sqs_queue.email_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.email_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.booking_notifications.arn
        }
      }
    }]
  })
}

# ============================================================================
# EVENTBRIDGE RULES
# ============================================================================

# Rule for booking events
resource "aws_cloudwatch_event_rule" "booking_events" {
  name           = "${var.service_name}-${var.environment}-booking-events"
  description    = "Capture booking events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["travel.bookings"]
    detail-type = ["Booking Created", "Booking Updated", "Booking Cancelled"]
  })
}

# Target: Send booking events to SNS
resource "aws_cloudwatch_event_target" "booking_to_sns" {
  rule           = aws_cloudwatch_event_rule.booking_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sns_topic.booking_notifications.arn
}

# Allow EventBridge to publish to SNS
resource "aws_sns_topic_policy" "booking_notifications" {
  arn = aws_sns_topic.booking_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.booking_notifications.arn
    }]
  })
}

# ============================================================================
# CLOUDWATCH ALARMS FOR DLQ
# ============================================================================

# Alarm for booking DLQ
resource "aws_cloudwatch_metric_alarm" "booking_dlq" {
  alarm_name          = "${var.service_name}-${var.environment}-booking-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when messages appear in booking DLQ"
  alarm_actions       = [aws_sns_topic.system_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.booking_processing_dlq.name
  }
}

# Alarm for email DLQ
resource "aws_cloudwatch_metric_alarm" "email_dlq" {
  alarm_name          = "${var.service_name}-${var.environment}-email-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when messages appear in email DLQ"
  alarm_actions       = [aws_sns_topic.system_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.email_queue_dlq.name
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "event_bus_name" {
  description = "EventBridge event bus name"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "EventBridge event bus ARN"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "booking_notifications_topic_arn" {
  description = "Booking notifications SNS topic ARN"
  value       = aws_sns_topic.booking_notifications.arn
}

output "payment_notifications_topic_arn" {
  description = "Payment notifications SNS topic ARN"
  value       = aws_sns_topic.payment_notifications.arn
}

output "system_alerts_topic_arn" {
  description = "System alerts SNS topic ARN"
  value       = aws_sns_topic.system_alerts.arn
}

output "booking_processing_queue_url" {
  description = "Booking processing SQS queue URL"
  value       = aws_sqs_queue.booking_processing.url
}

output "booking_processing_queue_arn" {
  description = "Booking processing SQS queue ARN"
  value       = aws_sqs_queue.booking_processing.arn
}

output "email_queue_url" {
  description = "Email SQS queue URL"
  value       = aws_sqs_queue.email_queue.url
}

output "email_queue_arn" {
  description = "Email SQS queue ARN"
  value       = aws_sqs_queue.email_queue.arn
}
