#!/bin/bash
# Bedrock Setup Verification Script
# Run this to verify IAM policies and test Bedrock access

echo "=========================================="
echo "AWS Bedrock Setup Verification"
echo "=========================================="
echo ""

# 1. Verify Lambda IAM Role Policies
echo "1. Checking Lambda IAM Role Policies..."
echo "----------------------------------------"
aws iam list-role-policies --role-name agent-service-dev-lambda-role
echo ""

# 2. Verify Bedrock Policy Details
echo "2. Checking Bedrock Policy Configuration..."
echo "----------------------------------------"
aws iam get-role-policy \
  --role-name agent-service-dev-lambda-role \
  --policy-name agent-service-dev-bedrock-policy \
  --query 'PolicyDocument.Statement[0]' \
  --output json
echo ""

# 3. Check Bedrock Model Access (from your account)
echo "3. Checking Bedrock Model Access..."
echo "----------------------------------------"
aws bedrock list-foundation-models \
  --by-provider anthropic \
  --query 'modelSummaries[?contains(modelId, `claude-3-haiku`)].{ModelId:modelId,Status:modelLifecycle.status}' \
  --output table
echo ""

# 4. Test Bedrock Invoke (this will show if payment validation is complete)
echo "4. Testing Bedrock Model Invocation..."
echo "----------------------------------------"
echo "Testing Claude 3 Haiku model access..."

# Create test payload
cat > /tmp/bedrock-test-payload.json <<EOF
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 100,
  "messages": [
    {
      "role": "user",
      "content": "Say 'Payment validation successful' if you can read this."
    }
  ]
}
EOF

# Test model invocation
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-haiku-20240307-v1:0 \
  --body file:///tmp/bedrock-test-payload.json \
  --region us-east-1 \
  /tmp/bedrock-response.json 2>&1

if [ $? -eq 0 ]; then
  echo "✅ SUCCESS: Bedrock model invocation works!"
  echo "Response:"
  cat /tmp/bedrock-response.json | jq -r '.content[0].text' 2>/dev/null || cat /tmp/bedrock-response.json
else
  echo "❌ FAILED: Bedrock model invocation failed"
  echo "This means payment validation is still in progress"
fi
echo ""

# 5. Check Lambda Function Configuration
echo "5. Checking Lambda Function Configuration..."
echo "----------------------------------------"
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query '{Runtime:Runtime,MemorySize:MemorySize,Timeout:Timeout,Environment:Environment.Variables}' \
  --output json
echo ""

# 6. Test Lambda Endpoint
echo "6. Testing Lambda Endpoint..."
echo "----------------------------------------"
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}' \
  -w "\nHTTP Status: %{http_code}\n"
echo ""

# 7. Check Recent Lambda Logs
echo "7. Checking Recent Lambda Logs (last 2 minutes)..."
echo "----------------------------------------"
aws logs tail /aws/lambda/agent-service-dev --since 2m --format short
echo ""

echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "1. If Bedrock test (step 4) SUCCEEDS: Lambda should work now - retry endpoint"
echo "2. If Bedrock test (step 4) FAILS with INVALID_PAYMENT_INSTRUMENT:"
echo "   - Wait 2-4 hours after first Bedrock Playground use"
echo "   - Payment validation is processing in AWS backend"
echo "   - Re-run this script after waiting"
echo "3. If still failing after 4 hours: Contact AWS Support"
echo ""
echo "AWS Support: https://console.aws.amazon.com/support/home"
echo ""

# Cleanup
rm -f /tmp/bedrock-test-payload.json /tmp/bedrock-response.json
