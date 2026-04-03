# ============================================================================
# SES NOTIFICATIONS MODULE
# ============================================================================
# Amazon SES for transactional emails (booking confirmations, receipts)

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain for email sending (e.g., example.com)"
  type        = string
}

variable "from_email" {
  description = "From email address"
  type        = string
  default     = "noreply"
}

variable "verified_emails" {
  description = "List of verified email addresses for testing"
  type        = list(string)
  default     = []
}

# ============================================================================
# SES EMAIL IDENTITIES (for testing in sandbox)
# ============================================================================

# Use email verification instead of domain verification for faster setup
resource "aws_ses_email_identity" "from_email" {
  email = "${var.from_email}@${var.domain_name}"
}

resource "aws_ses_email_identity" "verified" {
  count = length(var.verified_emails)
  email = var.verified_emails[count.index]
}

# ============================================================================
# SES CONFIGURATION SET
# ============================================================================

resource "aws_ses_configuration_set" "main" {
  name = "travel-platform-${var.environment}"
  
  delivery_options {
    tls_policy = "Require"
  }
}

# CloudWatch event destination for tracking
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "bounce", "complaint", "delivery", "reject"]
  
  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}

# ============================================================================
# EMAIL TEMPLATES
# ============================================================================

resource "aws_ses_template" "booking_confirmation" {
  name    = "booking-confirmation-${var.environment}"
  subject = "Booking Confirmation - {{hotelName}}"
  html    = <<-HTML
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9fafb; }
        .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
        .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Booking Confirmed!</h1>
        </div>
        <div class="content">
          <p>Dear {{guestName}},</p>
          <p>Your booking has been confirmed. We look forward to welcoming you!</p>
          
          <div class="booking-details">
            <h3>Booking Details</h3>
            <p><strong>Confirmation Number:</strong> {{bookingId}}</p>
            <p><strong>Hotel:</strong> {{hotelName}}</p>
            <p><strong>Room Type:</strong> {{roomType}}</p>
            <p><strong>Check-in:</strong> {{checkIn}}</p>
            <p><strong>Check-out:</strong> {{checkOut}}</p>
            <p><strong>Guests:</strong> {{guests}}</p>
            <p><strong>Total Price:</strong> $${{totalPrice}}</p>
          </div>
          
          <p>If you have any questions, please contact us.</p>
        </div>
        <div class="footer">
          <p>&copy; 2024 Travel Platform. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  HTML
  text    = "Booking Confirmed! Confirmation: {{bookingId}}, Hotel: {{hotelName}}, Check-in: {{checkIn}}, Check-out: {{checkOut}}"
}

resource "aws_ses_template" "payment_receipt" {
  name    = "payment-receipt-${var.environment}"
  subject = "Payment Receipt - {{bookingId}}"
  html    = <<-HTML
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #10b981; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9fafb; }
        .receipt { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
        .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Payment Received</h1>
        </div>
        <div class="content">
          <p>Dear {{guestName}},</p>
          <p>Thank you for your payment. Here is your receipt:</p>
          
          <div class="receipt">
            <h3>Payment Details</h3>
            <p><strong>Receipt Number:</strong> {{paymentId}}</p>
            <p><strong>Booking ID:</strong> {{bookingId}}</p>
            <p><strong>Amount Paid:</strong> $${{amount}}</p>
            <p><strong>Payment Method:</strong> {{paymentMethod}}</p>
            <p><strong>Date:</strong> {{paymentDate}}</p>
          </div>
        </div>
        <div class="footer">
          <p>&copy; 2024 Travel Platform. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  HTML
  text    = "Payment Receipt: {{paymentId}}, Booking: {{bookingId}}, Amount: $${{amount}}"
}

# ============================================================================
# IAM POLICY FOR LAMBDA TO SEND EMAILS
# ============================================================================

resource "aws_iam_policy" "ses_send_email" {
  name        = "ses-send-email-${var.environment}"
  description = "Allow Lambda to send emails via SES"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendTemplatedEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "domain_identity_arn" {
  description = "SES domain identity ARN"
  value       = aws_ses_domain_identity.main.arn
}

output "configuration_set_name" {
  description = "SES configuration set name"
  value       = aws_ses_configuration_set.main.name
}

output "from_email_address" {
  description = "From email address"
  value       = "${var.from_email}@${var.domain_name}"
}

output "ses_send_policy_arn" {
  description = "IAM policy ARN for sending emails"
  value       = aws_iam_policy.ses_send_email.arn
}

output "booking_confirmation_template" {
  description = "Booking confirmation template name"
  value       = aws_ses_template.booking_confirmation.name
}

output "payment_receipt_template" {
  description = "Payment receipt template name"
  value       = aws_ses_template.payment_receipt.name
}
