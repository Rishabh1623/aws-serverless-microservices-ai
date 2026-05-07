#!/bin/bash
# Quick deployment script to switch from Bedrock to Anthropic Direct API
# This bypasses the AWS Bedrock payment validation issue

set -e  # Exit on error

echo "=========================================="
echo "Anthropic Direct API Deployment"
echo "=========================================="
echo ""

# Check if API key is set
if [ -z "$TF_VAR_anthropic_api_key" ]; then
    echo "❌ ERROR: Anthropic API key not set"
    echo ""
    echo "Please set your Anthropic API key:"
    echo "  export TF_VAR_anthropic_api_key='sk-ant-api03-YOUR-KEY-HERE'"
    echo ""
    echo "Get your API key from: https://console.anthropic.com/"
    echo ""
    exit 1
fi

echo "✅ Anthropic API key is set"
echo ""

# Step 1: Rebuild Lambda package
echo "Step 1: Rebuilding Lambda package with Anthropic SDK..."
echo "--------------------------------------------------------"
cd agent-service
rm -f agent-service-lambda.zip
bash build-lambda.sh

if [ ! -f "agent-service-lambda.zip" ]; then
    echo "❌ ERROR: Lambda package build failed"
    exit 1
fi

echo "✅ Lambda package built successfully"
echo ""

# Step 2: Deploy with Terraform
echo "Step 2: Deploying with Terraform..."
echo "--------------------------------------------------------"
cd ../terraform/agent-service/dev

terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan

echo ""
echo "✅ Deployment complete!"
echo ""

# Step 3: Test the endpoint
echo "Step 3: Testing the endpoint..."
echo "--------------------------------------------------------"
sleep 5  # Wait for Lambda to be ready

curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}' \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "✅ Agent service is now using Anthropic Direct API"
echo "✅ This bypasses AWS Bedrock billing issues"
echo ""
echo "Check logs:"
echo "  aws logs tail /aws/lambda/agent-service-dev --since 1m --follow"
echo ""
echo "Monitor usage:"
echo "  https://console.anthropic.com/settings/usage"
echo ""
