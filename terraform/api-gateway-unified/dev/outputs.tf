# ============================================================================
# OUTPUTS
# ============================================================================

output "api_gateway_url" {
  description = "Unified API Gateway URL"
  value       = "${aws_api_gateway_stage.unified.invoke_url}"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.unified.id
}

output "workflow_endpoints" {
  description = "Workflow trigger endpoints"
  value = {
    hotel_booking      = "${aws_api_gateway_stage.unified.invoke_url}/workflows/hotel-booking"
    order_processing   = "${aws_api_gateway_stage.unified.invoke_url}/workflows/order-processing"
    payment_processing = "${aws_api_gateway_stage.unified.invoke_url}/workflows/payment-processing"
  }
}

output "existing_service_endpoints" {
  description = "Existing microservice endpoints (for reference)"
  value = {
    hotel_service   = "https://${data.aws_api_gateway_rest_api.hotel_service.id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    order_service   = "https://${data.aws_api_gateway_rest_api.order_service.id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    payment_service = "https://${data.aws_api_gateway_rest_api.payment_service.id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    agent_service   = "https://${data.aws_api_gateway_rest_api.agent_service.id}.execute-api.${var.aws_region}.amazonaws.com"
  }
}
