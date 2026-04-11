#!/bin/bash

# Deploy services with orchestrators - handles existing API Gateway resources
# Usage: ./scripts/deploy-with-orchestrators.sh [service-name]
# Example: ./scripts/deploy-with-orchestrators.sh order-service

set -e

SERVICE=$1
ENVIRONMENT=${2:-dev}

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service-name> [environment]"
    echo "Example: $0 order-service dev"
    echo ""
    echo "Available services:"
    echo "  - hotel-service"
    echo "  - order-service"
    echo "  - payment-service"
    exit 1
fi

echo "=========================================="
echo "Deploying $SERVICE with orchestrator"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

cd "terraform/$SERVICE/$ENVIRONMENT"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Get API Gateway ID
echo "Checking for existing API Gateway..."
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$SERVICE-$ENVIRONMENT'].id" --output text)

if [ -z "$API_ID" ]; then
    echo "No existing API Gateway found. Running fresh deployment..."
    terraform apply
    exit 0
fi

echo "Found existing API Gateway: $API_ID"

# Import existing API Gateway resources based on service
case $SERVICE in
    "order-service")
        echo "Importing order service API Gateway resources..."
        
        # Get resource IDs
        ORDERS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[?path=='/orders'].id" --output text)
        
        if [ ! -z "$ORDERS_ID" ]; then
            echo "Importing /orders resource..."
            terraform import 'module.order_service.aws_api_gateway_resource.root["orders"]' $API_ID/$ORDERS_ID 2>/dev/null || echo "Already imported or doesn't exist"
        fi
        ;;
        
    "payment-service")
        echo "Importing payment service API Gateway resources..."
        
        # Get resource IDs
        PAYMENTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[?path=='/payments'].id" --output text)
        WEBHOOK_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[?path=='/webhook'].id" --output text)
        
        if [ ! -z "$PAYMENTS_ID" ]; then
            echo "Importing /payments resource..."
            terraform import 'module.payment_service.aws_api_gateway_resource.root["payments"]' $API_ID/$PAYMENTS_ID 2>/dev/null || echo "Already imported or doesn't exist"
        fi
        
        if [ ! -z "$WEBHOOK_ID" ]; then
            echo "Importing /webhook resource..."
            terraform import 'module.payment_service.aws_api_gateway_resource.root["webhook"]' $API_ID/$WEBHOOK_ID 2>/dev/null || echo "Already imported or doesn't exist"
        fi
        ;;
        
    "hotel-service")
        echo "Hotel service already deployed. Skipping..."
        ;;
        
    *)
        echo "Unknown service: $SERVICE"
        exit 1
        ;;
esac

# Run terraform apply
echo ""
echo "Running terraform apply..."
terraform apply

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="
echo ""
echo "API Endpoint: https://$API_ID.execute-api.us-east-1.amazonaws.com/$ENVIRONMENT"
echo ""
echo "Test the orchestrator:"
case $SERVICE in
    "order-service")
        echo "curl -X PUT https://$API_ID.execute-api.us-east-1.amazonaws.com/$ENVIRONMENT/orders \\"
        echo "  -H 'Content-Type: application/json' \\"
        echo "  -d '{\"userId\":\"user123\",\"items\":[{\"productId\":\"p1\",\"quantity\":2}]}'"
        ;;
    "payment-service")
        echo "curl -X PUT https://$API_ID.execute-api.us-east-1.amazonaws.com/$ENVIRONMENT/payments \\"
        echo "  -H 'Content-Type: application/json' \\"
        echo "  -d '{\"orderId\":\"order123\",\"amount\":100.00,\"currency\":\"USD\"}'"
        ;;
esac
echo ""
