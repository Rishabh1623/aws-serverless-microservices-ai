output "api_endpoint" {
  description = "Hotel Service API endpoint"
  value       = module.hotel_service.api_endpoint
}

output "hotel_table_name" {
  description = "DynamoDB Hotels table name"
  value       = module.hotel_service.dynamodb_tables["hotels"].name
}

output "booking_table_name" {
  description = "DynamoDB Bookings table name"
  value       = module.hotel_service.dynamodb_tables["bookings"].name
}
