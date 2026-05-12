#!/bin/bash

# Deploy Bedrock Resilience Fix
# This script rebuilds the Lambda package with resilience logic and deploys it

set -e  # Exit on error

echo "=========================================="
echo "Deploying Bedrock Resilience Fix"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "build-lambda.sh" ]; then
    echo "❌ ERROR: Must run from agent-service directory"
    echo "Usage: cd agent-service && bash deploy-resilience-fix.sh"
    exit 1
fi

# Step 1: Rebuild Lambda package
echo "📦 Step 1: Rebuilding Lambda package..."
echo ""
bash build-lambda.sh

if [ $? -ne 0 ]; then
    echo "❌ Lambda build failed"
    exit 1
fi

echo ""
echo "✅ Lambda package built successfully"
echo ""

# Step 2: Deploy with Terraform
echo "🚀 Step 2: Deploying with Terraform..."
echo ""

cd ../terraform/agent-service/dev

# Initialize Terraform (in case backend changed)
terraform init -reconfigure

# Plan changes
echo ""
echo "📋 Terraform Plan:"
echo ""
terraform plan

# Ask for confirmation
echo ""
read -p "Deploy these changes? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

# Apply changes
echo ""
echo "🚀 Applying Terraform changes..."
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📊 Next Steps:"
echo ""
echo "1. Test the Lambda function:"
echo "   curl -X POST https://zwp2qpu3q7.execute-api.us-east-1.amazonaws.com/agent \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"message\":\"Find hotels in Paris\",\"userId\":\"test\"}'"
echo ""
echo "2. Monitor CloudWatch logs:"
echo "   aws logs tail /aws/lambda/agent-service-dev --follow"
echo ""
echo "3. Check for retry attempts and region fallback in logs"
echo ""
echo "🎯 Expected Behavior:"
echo "   - If quota still 0: Will retry 3x in us-east-1, then 3x in us-west-2"
echo "   - If quota enabled: Will succeed immediately"
echo "   - If all fail: Returns 503 with graceful error message"
echo ""
