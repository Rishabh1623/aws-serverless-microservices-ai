#!/bin/bash

# ============================================================================
# Deploy Claude 3 Haiku Model Configuration Fix
# ============================================================================
# 
# This script updates the Lambda environment variable to use Claude 3 Haiku
# instead of Claude Sonnet 4 (which requires AWS Marketplace subscription).
#
# Changes:
# - BEDROCK_MODEL_ID: us.anthropic.claude-sonnet-4-20250514-v1:0 
#                  -> anthropic.claude-3-haiku-20240307-v1:0
# - IAM policy: Prioritize Claude 3 Haiku permissions
#
# ============================================================================

set -e  # Exit on error

echo "============================================================================"
echo "Deploying Claude 3 Haiku Model Configuration Fix"
echo "============================================================================"
echo ""

# Navigate to Terraform directory
cd terraform/agent-service/dev

echo "📋 Step 1: Terraform Plan"
echo "Checking what will change..."
terraform plan -out=tfplan

echo ""
echo "📦 Step 2: Apply Changes"
echo "Updating Lambda environment variable to use Claude 3 Haiku..."
terraform apply -auto-approve tfplan

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "============================================================================"
echo "Verification Steps:"
echo "============================================================================"
echo ""
echo "1. Check Lambda environment variable:"
echo "   aws lambda get-function-configuration \\"
echo "     --function-name agent-service-dev \\"
echo "     --query 'Environment.Variables.BEDROCK_MODEL_ID'"
echo ""
echo "2. Test the Lambda function:"
echo "   aws lambda invoke \\"
echo "     --function-name agent-service-dev \\"
echo "     --payload '{\"body\":\"{\\\"message\\\":\\\"Hello, can you help me find a hotel?\\\",\\\"userId\\\":\\\"test-user\\\"}\"}' \\"
echo "     response.json"
echo ""
echo "3. Check CloudWatch Logs:"
echo "   aws logs tail /aws/lambda/agent-service-dev --follow"
echo ""
echo "Expected Result:"
echo "- Lambda should initialize successfully"
echo "- No AccessDeniedException errors"
echo "- Model ID in logs: anthropic.claude-3-haiku-20240307-v1:0"
echo ""
echo "============================================================================"
