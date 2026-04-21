# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================

data "aws_caller_identity" "current" {}

data "archive_file" "search_hotels" {
  type        = "zip"
  source_dir  = "${path.module}/../../../hotel-service/src/search_hotels"
  output_path = "${path.module}/lambda_packages/search_hotels.zip"
}

data "archive_file" "get_hotel" {
  type        = "zip"
  source_dir  = "${path.module}/../../../hotel-service/src/get_hotel"
  output_path = "${path.module}/lambda_packages/get_hotel.zip"
}

data "archive_file" "create_booking" {
  type        = "zip"
  source_dir  = "${path.module}/../../../hotel-service/src/create_booking"
  output_path = "${path.module}/lambda_packages/create_booking.zip"
}

data "archive_file" "booking_notification" {
  type        = "zip"
  source_dir  = "${path.module}/../../../hotel-service/src/booking_notification"
  output_path = "${path.module}/lambda_packages/booking_notification.zip"
}

# ============================================================================
# HOTEL SERVICE MODULE
# ============================================================================

module "hotel_service" {
  source = "../../modules/lambda-service"

  service_name = var.service_name
  environment  = var.environment

  lambda_functions = {
    search-hotels = {
      filename    = data.archive_file.search_hotels.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        HOTEL_TABLE = "${var.service_name}-hotels-${var.environment}"
        ROOM_TABLE  = "${var.service_name}-rooms-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    get-hotel = {
      filename    = data.archive_file.get_hotel.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        HOTEL_TABLE = "${var.service_name}-hotels-${var.environment}"
        ROOM_TABLE  = "${var.service_name}-rooms-${var.environment}"
        ENVIRONMENT = var.environment
      }
    }
    create-booking = {
      filename    = data.archive_file.create_booking.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = var.lambda_memory_size
      timeout     = var.lambda_timeout
      environment_variables = {
        BOOKING_TABLE     = "${var.service_name}-bookings-${var.environment}"
        ROOM_TABLE        = "${var.service_name}-rooms-${var.environment}"
        IDEMPOTENCY_TABLE = "${var.service_name}-idempotency-${var.environment}"
        EVENT_BUS_NAME    = module.event_driven.event_bus_name
        ENVIRONMENT       = var.environment
      }
    }
    booking-notification = {
      filename    = data.archive_file.booking_notification.output_path
      handler     = "app.lambda_handler"
      runtime     = var.lambda_runtime
      memory_size = 256
      timeout     = 30
      environment_variables = {
        HOTEL_TABLE           = "${var.service_name}-hotels-${var.environment}"
        BOOKING_TABLE         = "${var.service_name}-bookings-${var.environment}"
        SES_CONFIGURATION_SET = module.ses_notifications.configuration_set_name
        FROM_EMAIL            = module.ses_notifications.from_email_address
        TEMPLATE_NAME         = module.ses_notifications.booking_confirmation_template
        ENVIRONMENT           = var.environment
      }
    }
  }

  api_gateway_resources = {
    hotels = {
      path_part = "hotels"
    }
    hotel_id = {
      path_part  = "{hotelId}"
      parent_key = "hotels"
    }
    bookings = {
      path_part = "bookings"
    }
  }

  api_gateway_methods = {
    search_hotels = {
      resource_key = "hotels"
      http_method  = "GET"
      lambda_key   = "search-hotels"
    }
    get_hotel = {
      resource_key = "hotel_id"
      http_method  = "GET"
      lambda_key   = "get-hotel"
    }
    create_booking = {
      resource_key = "bookings"
      http_method  = "POST"
      lambda_key   = "create-booking"
    }
  }

  dynamodb_tables = {
    hotels = {
      hash_key = "hotelId"
      attributes = [
        {
          name = "hotelId"
          type = "S"
        }
      ]
      point_in_time_recovery = true
    }
    rooms = {
      hash_key = "roomId"
      attributes = [
        {
          name = "roomId"
          type = "S"
        },
        {
          name = "hotelId"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "HotelIdIndex"
          hash_key        = "hotelId"
          projection_type = "ALL"
        }
      ]
      point_in_time_recovery = true
    }
    bookings = {
      hash_key = "bookingId"
      attributes = [
        {
          name = "bookingId"
          type = "S"
        },
        {
          name = "userId"
          type = "S"
        },
        {
          name = "roomId"
          type = "S"
        }
      ]
      global_secondary_indexes = [
        {
          name            = "UserIdIndex"
          hash_key        = "userId"
          projection_type = "ALL"
        },
        {
          name            = "RoomIdIndex"
          hash_key        = "roomId"
          projection_type = "ALL"
        }
      ]
      point_in_time_recovery = true
    }
    idempotency = {
      hash_key = "idempotencyKey"
      attributes = [
        {
          name = "idempotencyKey"
          type = "S"
        }
      ]
      ttl_enabled        = true
      ttl_attribute_name = "ttl"
    }
  }
}

# ============================================================================
# COGNITO AUTHENTICATION
# ============================================================================

module "cognito" {
  source = "../../modules/cognito-auth"

  service_name   = var.service_name
  environment    = var.environment

  callback_urls = ["https://localhost:3000/callback"]
  logout_urls   = ["https://localhost:3000/logout"]

  depends_on = [module.hotel_service]
}

# ============================================================================
# SECRETS MANAGER
# ============================================================================

module "secrets" {
  source = "../../modules/secrets-manager"

  service_name = var.service_name
  environment  = var.environment

  secrets = {
    bedrock_api_key = jsonencode({
      model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
      region   = "us-east-1"
    })
  }
}

# ============================================================================
# EVENT-DRIVEN ARCHITECTURE
# ============================================================================

module "event_driven" {
  source = "../../modules/event-driven"

  service_name = var.service_name
  environment  = var.environment
}

# ============================================================================
# DYNAMODB BACKUP
# ============================================================================

module "dynamodb_backup" {
  source = "../../modules/dynamodb-backup"

  service_name = var.service_name
  environment  = var.environment

  table_names = [
    "${var.service_name}-hotels-${var.environment}",
    "${var.service_name}-rooms-${var.environment}",
    "${var.service_name}-bookings-${var.environment}"
  ]

  backup_retention_days = 30

  depends_on = [module.hotel_service]
}

# ============================================================================
# SES NOTIFICATIONS
# ============================================================================

module "ses_notifications" {
  source = "../../modules/ses-notifications"

  environment     = var.environment
  domain_name     = var.domain_name
  from_email      = "bookings"
  verified_emails = var.verified_emails
}

# ============================================================================
# GRANT PERMISSIONS
# ============================================================================

# Grant Lambda access to EventBridge
resource "aws_iam_role_policy" "lambda_eventbridge" {
  for_each = module.hotel_service.lambda_roles

  role = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = module.event_driven.event_bus_arn
      }
    ]
  })
}

# Grant Lambda access to Secrets Manager
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  for_each = module.hotel_service.lambda_roles

  role       = each.value.name
  policy_arn = module.secrets.secrets_access_policy_arn
}

# Grant Lambda access to send emails
resource "aws_iam_role_policy_attachment" "lambda_ses" {
  for_each = module.hotel_service.lambda_roles

  role       = each.value.name
  policy_arn = module.ses_notifications.ses_send_policy_arn
}


# ============================================================================
# EVENTBRIDGE RULE TARGET
# ============================================================================

# Additional target for booking notification Lambda
resource "aws_cloudwatch_event_target" "booking_notification" {
  rule           = "${var.service_name}-${var.environment}-booking-events"
  event_bus_name = module.event_driven.event_bus_name
  target_id      = "BookingNotificationLambda"
  arn            = module.hotel_service.lambda_functions["booking-notification"].arn

  depends_on = [module.event_driven]
}

# Grant EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.hotel_service.lambda_functions["booking-notification"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${module.event_driven.event_bus_name}/${var.service_name}-${var.environment}-booking-events"
}
