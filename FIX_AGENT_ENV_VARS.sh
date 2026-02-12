#!/bin/bash

# Fix Shopping Agent Environment Variables
# This script redeploys the Shopping Agent with correct API URLs

set -e

echo "=========================================="
echo "Fix Shopping Agent Environment Variables"
echo "=========================================="
echo ""

# Set API URLs from deployed services
export PRODUCT_API="https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev"
export CART_API="https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev"
export ORDER_API="https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev"
export PAYMENT_API="https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev"

echo "API URLs to be configured:"
echo "  PRODUCT_API: $PRODUCT_API"
echo "  CART_API: $CART_API"
echo "  ORDER_API: $ORDER_API"
echo "  PAYMENT_API: $PAYMENT_API"
echo ""

# Navigate to agent service terraform directory
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

echo "Redeploying Shopping Agent with correct environment variables..."
echo ""

# Apply Terraform with correct variables
terraform apply \
  -var="product_api_url=$PRODUCT_API" \
  -var="cart_api_url=$CART_API" \
  -var="order_api_url=$ORDER_API" \
  -var="payment_api_url=$PAYMENT_API" \
  -auto-approve

echo ""
echo "=========================================="
echo "Verifying Environment Variables"
echo "=========================================="
echo ""

# Verify the Lambda function's environment variables
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables' \
  --output json

echo ""
echo "=========================================="
echo "Testing Shopping Agent"
echo "=========================================="
echo ""

# Get the Agent API URL
AGENT_API=$(terraform output -raw api_gateway_url)
echo "Agent API: $AGENT_API"
echo ""

# Test the agent
echo "Sending test message: 'Show me products'"
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me products", "userId": "test-user"}' \
  | jq '.'

echo ""
echo "=========================================="
echo "✅ Shopping Agent Fixed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test the AI Assistant in the frontend"
echo "2. Try: 'Show me laptops under $1000'"
echo "3. Try: 'Add the Dell laptop'"
echo "4. Try: 'Create my order'"
echo ""
echo "Frontend URL: http://serverless-microservices-frontend-543927035352.s3-website-us-east-1.amazonaws.com"
echo ""
