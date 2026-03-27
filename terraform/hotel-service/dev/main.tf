# ============================================================================
# DATA SOURCES - Lambda Deployment Packages
# ============================================================================
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

# ============================================================================
# HOTEL SERVICE MODULE
# ============================================================================

module "hotel_service" {
  source = "../../modules/lambda-service"
  
  service_name = var.service_name
  environment  = var.environment
  
  lambda_functions = {
    search-hotels = {
      filename              = data.archive_file.search_hotels.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        HOTEL_TABLE  = "${var.service_name}-hotels-${var.environment}"
        ROOM_TABLE   = "${var.service_name}-rooms-${var.environment}"
        ENVIRONMENT  = var.environment
      }
    }
    get-hotel = {
      filename              = data.archive_file.get_hotel.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        HOTEL_TABLE  = "${var.service_name}-hotels-${var.environment}"
        ROOM_TABLE   = "${var.service_name}-rooms-${var.environment}"
        ENVIRONMENT  = var.environment
      }
    }
    create-booking = {
      filename              = data.archive_file.create_booking.output_path
      handler               = "app.lambda_handler"
      runtime               = var.lambda_runtime
      memory_size           = var.lambda_memory_size
      timeout               = var.lambda_timeout
      environment_variables = {
        BOOKING_TABLE = "${var.service_name}-bookings-${var.environment}"
        ROOM_TABLE    = "${var.service_name}-rooms-${var.environment}"
        ENVIRONMENT   = var.environment
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
    }
  }
}
