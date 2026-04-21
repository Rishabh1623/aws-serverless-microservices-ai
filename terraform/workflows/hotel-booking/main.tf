/**
 * Hotel Booking Workflow - AWS Step Functions
 * 
 * Orchestrates the complete hotel booking process with:
 * - Validation
 * - Availability checking
 * - Room reservation
 * - Payment processing with retries
 * - Email confirmation
 * - Automatic rollback on failures
 */

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}

# Get existing Lambda functions
data "aws_lambda_function" "create_booking" {
  function_name = "hotel-service-create-booking-${var.environment}"
}

data "aws_lambda_function" "booking_notification" {
  function_name = "hotel-service-booking-notification-${var.environment}"
}

# Get DynamoDB tables
data "aws_dynamodb_table" "bookings" {
  name = "hotel-service-bookings-${var.environment}"
}

data "aws_dynamodb_table" "rooms" {
  name = "hotel-service-rooms-${var.environment}"
}

data "aws_dynamodb_table" "hotels" {
  name = "hotel-service-hotels-${var.environment}"
}

# ============================================================================
# STEP FUNCTIONS WORKFLOW
# ============================================================================

module "booking_workflow" {
  source = "../../modules/step-functions-workflow"

  workflow_name = "${var.project_name}-hotel-booking-${var.environment}"
  workflow_type = "STANDARD"  # Use STANDARD for long-running workflows
  environment   = var.environment

  lambda_arns = {
    create_booking        = data.aws_lambda_function.create_booking.arn
    booking_notification  = data.aws_lambda_function.booking_notification.arn
  }

  dynamodb_arns = [
    data.aws_dynamodb_table.bookings.arn,
    data.aws_dynamodb_table.rooms.arn,
    data.aws_dynamodb_table.hotels.arn
  ]

  definition = jsonencode({
    Comment = "Hotel Booking Workflow with validation, reservation, payment, and notification"
    StartAt = "ValidateBookingRequest"
    States = {
      
      # Step 1: Validate booking request
      ValidateBookingRequest = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_booking.arn
          Payload = {
            "action" = "validate"
            "booking.$" = "$"
          }
        }
        ResultPath = "$.validationResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "ValidationFailed"
          }
        ]
        Next = "CheckRoomAvailability"
      }

      # Step 2: Check room availability
      CheckRoomAvailability = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:getItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.rooms.name
          Key = {
            roomId = {
              "S.$" = "$.roomId"
            }
          }
        }
        ResultPath = "$.roomData"
        Retry = [
          {
            ErrorEquals = ["DynamoDB.ProvisionedThroughputExceededException"]
            IntervalSeconds = 1
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "RoomNotAvailable"
          }
        ]
        Next = "IsRoomAvailable"
      }

      # Step 3: Check if room is available
      IsRoomAvailable = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.roomData.Item.available.BOOL"
            BooleanEquals = true
            Next = "ReserveRoom"
          }
        ]
        Default = "RoomNotAvailable"
      }

      # Step 4: Reserve the room
      ReserveRoom = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.rooms.name
          Key = {
            roomId = {
              "S.$" = "$.roomId"
            }
          }
          UpdateExpression = "SET available = :false, reservedBy = :userId, reservedAt = :timestamp"
          ExpressionAttributeValues = {
            ":false" = {
              BOOL = false
            }
            ":userId" = {
              "S.$" = "$.userId"
            }
            ":timestamp" = {
              "S.$" = "$$.State.EnteredTime"
            }
          }
          ConditionExpression = "available = :true"
          ExpressionAttributeValues = {
            ":true" = {
              BOOL = true
            }
          }
        }
        ResultPath = "$.reservationResult"
        Retry = [
          {
            ErrorEquals = ["DynamoDB.ConditionalCheckFailedException"]
            MaxAttempts = 0  # Don't retry if room was taken
          },
          {
            ErrorEquals = ["DynamoDB.ProvisionedThroughputExceededException"]
            IntervalSeconds = 1
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["DynamoDB.ConditionalCheckFailedException"]
            ResultPath = "$.error"
            Next = "RoomNotAvailable"
          },
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "ReservationFailed"
          }
        ]
        Next = "CreateBookingRecord"
      }

      # Step 5: Create booking record
      CreateBookingRecord = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_booking.arn
          Payload = {
            "action" = "create"
            "booking.$" = "$"
          }
        }
        ResultPath = "$.bookingResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "RollbackReservation"
          }
        ]
        Next = "ProcessPayment"
      }

      # Step 6: Process payment (with retries)
      ProcessPayment = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_booking.arn
          Payload = {
            "action" = "payment"
            "booking.$" = "$"
          }
        }
        ResultPath = "$.paymentResult"
        Retry = [
          {
            ErrorEquals = ["PaymentTemporaryError"]
            IntervalSeconds = 5
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "PaymentFailed"
          }
        ]
        Next = "SendConfirmationEmail"
      }

      # Step 7: Send confirmation email
      SendConfirmationEmail = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.booking_notification.arn
          Payload = {
            "booking.$" = "$"
          }
        }
        ResultPath = "$.emailResult"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts = 2
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath = "$.error"
            Next = "BookingSuccessEmailFailed"  # Continue even if email fails
          }
        ]
        Next = "BookingSuccess"
      }

      # Success state
      BookingSuccess = {
        Type = "Succeed"
      }

      # Success but email failed
      BookingSuccessEmailFailed = {
        Type = "Succeed"
      }

      # Error states
      ValidationFailed = {
        Type = "Fail"
        Error = "ValidationError"
        Cause = "Booking request validation failed"
      }

      RoomNotAvailable = {
        Type = "Fail"
        Error = "RoomNotAvailable"
        Cause = "The requested room is not available"
      }

      ReservationFailed = {
        Type = "Fail"
        Error = "ReservationError"
        Cause = "Failed to reserve the room"
      }

      PaymentFailed = {
        Type = "Pass"
        Result = "Payment failed, rolling back"
        ResultPath = "$.rollbackReason"
        Next = "RollbackBooking"
      }

      # Rollback states
      RollbackReservation = {
        Type = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = data.aws_dynamodb_table.rooms.name
          Key = {
            roomId = {
              "S.$" = "$.roomId"
            }
          }
          UpdateExpression = "SET available = :true REMOVE reservedBy, reservedAt"
          ExpressionAttributeValues = {
            ":true" = {
              BOOL = true
            }
          }
        }
        ResultPath = null
        Next = "BookingFailed"
      }

      RollbackBooking = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = data.aws_lambda_function.create_booking.arn
          Payload = {
            "action" = "rollback"
            "booking.$" = "$"
          }
        }
        ResultPath = null
        Next = "RollbackReservation"
      }

      BookingFailed = {
        Type = "Fail"
        Error = "BookingFailed"
        Cause = "Booking process failed and was rolled back"
      }
    }
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "hotel-booking-workflow"
  }
}
