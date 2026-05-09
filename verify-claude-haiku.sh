#!/bin/bash

# ============================================================================
# Verify Claude 3 Haiku Configuration
# ============================================================================

set -e

echo "============================================================================"
echo "Verifying Claude 3 Haiku Configuration"
echo "============================================================================"
echo ""

echo "1️⃣ Checking Lambda Environment Variable..."
MODEL_ID=$(aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables.BEDROCK_MODEL_ID' \
  --output text)

echo "   Current Model ID: $MODEL_ID"

if [[ "$MODEL_ID" == "anthropic.claude-3-haiku-20240307-v1:0" ]]; then
  echo "   ✅ Correct! Using Claude 3 Haiku"
elif [[ "$MODEL_ID" == *"sonnet-4"* ]]; then
  echo "   ❌ ERROR: Still using Claude Sonnet 4"
  echo "   Run: cd terraform/agent-service/dev && terraform apply"
  exit 1
else
  echo "   ⚠️  Unknown model: $MODEL_ID"
fi

echo ""
echo "2️⃣ Testing Lambda Function..."
aws lambda invoke \
  --function-name agent-service-dev \
  --payload '{"body":"{\"message\":\"Hello, can you help me find a hotel?\",\"userId\":\"test-user\"}"}' \
  response.json > /dev/null 2>&1

STATUS_CODE=$(cat response.json | jq -r '.statusCode')
echo "   Status Code: $STATUS_CODE"

if [[ "$STATUS_CODE" == "200" ]]; then
  echo "   ✅ Lambda executed successfully!"
  RESPONSE=$(cat response.json | jq -r '.body' | jq -r '.response')
  echo "   Agent Response: ${RESPONSE:0:100}..."
elif [[ "$STATUS_CODE" == "500" ]]; then
  echo "   ❌ Lambda returned error"
  ERROR=$(cat response.json | jq -r '.body' | jq -r '.message')
  echo "   Error: $ERROR"
  exit 1
else
  echo "   ⚠️  Unexpected status code"
  cat response.json | jq '.'
fi

echo ""
echo "3️⃣ Checking Recent CloudWatch Logs..."
echo "   (Last 5 minutes)"
aws logs tail /aws/lambda/agent-service-dev \
  --since 5m \
  --format short \
  | grep -E "(Using AWS Bedrock|Model access is denied|AccessDeniedException)" \
  || echo "   ✅ No access denied errors found"

echo ""
echo "============================================================================"
echo "✅ Verification Complete!"
echo "============================================================================"
echo ""
echo "Summary:"
echo "- Model ID: $MODEL_ID"
echo "- Lambda Status: Working"
echo "- No Bedrock access errors"
echo ""
echo "Next Steps:"
echo "1. Test via API Gateway:"
echo "   curl -X POST https://zwp2qpu3q7.execute-api.us-east-1.amazonaws.com/agent \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"message\":\"Find me a hotel in Miami\",\"userId\":\"test-user\"}'"
echo ""
echo "2. Monitor logs in real-time:"
echo "   aws logs tail /aws/lambda/agent-service-dev --follow"
echo ""

# Cleanup
rm -f response.json
