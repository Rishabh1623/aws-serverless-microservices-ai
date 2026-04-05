#!/bin/bash

# Fix Cart Service API Gateway Resource Hierarchy
# This script destroys and recreates the cart service to fix stale state

set -e

echo "=========================================="
echo "Cart Service API Gateway Fix"
echo "=========================================="
echo ""

cd ~/aws-serverless-microservices-ai/terraform/cart-service/dev

echo "Step 1: Destroying cart service..."
terraform destroy -auto-approve

echo ""
echo "Step 2: Reapplying cart service with clean state..."
terraform apply -auto-approve

echo ""
echo "Step 3: Verifying API Gateway resources..."
export API_ID=$(aws apigateway get-rest-apis --query "items[?name=='cart-service-dev'].id" --output text)
echo "API ID: $API_ID"
echo ""
echo "Current API Gateway paths:"
aws apigateway get-resources --rest-api-id $API_ID --query 'items[*].[path]' --output table

echo ""
echo "Expected paths:"
echo "  /"
echo "  /cart"
echo "  /cart/{userId}"
echo "  /items"
echo "  /promo"

echo ""
echo "Step 4: Testing API endpoints..."
API_URL=$(terraform output -raw api_gateway_url)
echo "API URL: $API_URL"

echo ""
echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test GET cart: curl $API_URL/cart/user-123"
echo "2. Test POST add item: curl -X POST $API_URL/items -d '{\"userId\":\"user-123\",\"hotelId\":\"hotel-1\",\"quantity\":1}'"
echo "3. Test DELETE remove: curl -X DELETE $API_URL/items -d '{\"userId\":\"user-123\",\"cartItemId\":\"item-1\"}'"
echo "4. Test POST promo: curl -X POST $API_URL/promo -d '{\"userId\":\"user-123\",\"promoCode\":\"SAVE10\"}'"
