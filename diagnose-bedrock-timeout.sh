#!/bin/bash

# ============================================================================
# Diagnose Bedrock Timeout Issue
# ============================================================================

set -e

echo "============================================================================"
echo "Bedrock Timeout Diagnostics"
echo "============================================================================"
echo ""

echo "1️⃣ Check Lambda Configuration"
echo "-----------------------------------"
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query '{Timeout:Timeout,Memory:MemorySize,Runtime:Runtime,Region:Environment.Variables.BEDROCK_REGION,ModelID:Environment.Variables.BEDROCK_MODEL_ID}' \
  --output table

echo ""
echo "2️⃣ Test Direct Bedrock Access (from Lambda's perspective)"
echo "-----------------------------------"
echo "Testing if Bedrock is accessible in us-east-1..."

# Test Bedrock invoke-model directly
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-haiku-20240307-v1:0 \
  --region us-east-1 \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Say hello in 5 words"}]}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/bedrock-direct-test.json

echo "✅ Bedrock direct call succeeded!"
cat /tmp/bedrock-direct-test.json | jq '.content[0].text'

echo ""
echo "3️⃣ Check IAM Permissions"
echo "-----------------------------------"
ROLE_NAME=$(aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Role' \
  --output text | awk -F'/' '{print $NF}')

echo "Lambda Role: $ROLE_NAME"

aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query 'AttachedPolicies[*].PolicyName' \
  --output table

echo ""
echo "4️⃣ Check VPC Configuration"
echo "-----------------------------------"
VPC_CONFIG=$(aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'VpcConfig' \
  --output json)

if [ "$VPC_CONFIG" == "null" ] || [ "$VPC_CONFIG" == "{}" ]; then
  echo "✅ Lambda is NOT in VPC (good - no network restrictions)"
else
  echo "⚠️  Lambda IS in VPC - this could cause Bedrock timeout!"
  echo "$VPC_CONFIG" | jq '.'
  echo ""
  echo "SOLUTION: Lambda in VPC needs:"
  echo "  1. VPC Endpoint for Bedrock, OR"
  echo "  2. NAT Gateway for internet access"
fi

echo ""
echo "5️⃣ Test Lambda with Minimal Code"
echo "-----------------------------------"
echo "Recommendation: Deploy minimal version without tools to isolate issue"
echo ""
echo "Next steps:"
echo "1. If Bedrock direct call works → Issue is in Strands SDK or tools initialization"
echo "2. If Lambda is in VPC → Add VPC endpoint or remove VPC config"
echo "3. Deploy app_minimal.py to test without tools"
echo ""
echo "============================================================================"
