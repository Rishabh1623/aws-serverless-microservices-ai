#!/bin/bash
# Bedrock Diagnostics Collection Script
# Run this and send the output to AWS Support

OUTPUT_FILE="bedrock-diagnostics-$(date +%Y%m%d-%H%M%S).txt"

echo "=========================================="
echo "AWS Bedrock Diagnostics Report"
echo "Generated: $(date)"
echo "=========================================="
echo ""

{
    echo "=========================================="
    echo "1. ACCOUNT INFORMATION"
    echo "=========================================="
    echo "Account ID:"
    aws sts get-caller-identity --query 'Account' --output text
    echo ""
    echo "Region:"
    aws configure get region
    echo ""
    
    echo "=========================================="
    echo "2. BEDROCK MODEL ACCESS"
    echo "=========================================="
    echo "Available Claude Models:"
    aws bedrock list-foundation-models \
        --by-provider anthropic \
        --query 'modelSummaries[?contains(modelId, `claude`)].{ModelId:modelId,Status:modelLifecycle.status}' \
        --output table
    echo ""
    
    echo "=========================================="
    echo "3. LAMBDA FUNCTION CONFIGURATION"
    echo "=========================================="
    echo "Function: agent-service-dev"
    aws lambda get-function-configuration \
        --function-name agent-service-dev \
        --query '{Runtime:Runtime,Role:Role,Environment:Environment.Variables}' \
        --output json
    echo ""
    
    echo "=========================================="
    echo "4. IAM ROLE POLICIES"
    echo "=========================================="
    echo "Role: agent-service-dev-lambda-role"
    echo ""
    echo "Attached Policies:"
    aws iam list-role-policies \
        --role-name agent-service-dev-lambda-role \
        --output json
    echo ""
    
    echo "Bedrock Policy Details:"
    aws iam get-role-policy \
        --role-name agent-service-dev-lambda-role \
        --policy-name agent-service-dev-bedrock-policy \
        --output json
    echo ""
    
    echo "=========================================="
    echo "5. BEDROCK API TEST FROM CLI"
    echo "=========================================="
    echo "Testing direct Bedrock invocation..."
    
    # Create test payload
    cat > /tmp/bedrock-test.json <<'EOF'
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 50,
  "messages": [
    {
      "role": "user",
      "content": "Say hello"
    }
  ]
}
EOF
    
    # Test invocation
    aws bedrock-runtime invoke-model \
        --model-id anthropic.claude-3-haiku-20240307-v1:0 \
        --body file:///tmp/bedrock-test.json \
        --region us-east-1 \
        /tmp/bedrock-response.json 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS: CLI invocation works"
        echo "Response:"
        cat /tmp/bedrock-response.json
    else
        echo "❌ FAILED: CLI invocation failed with same error"
    fi
    echo ""
    
    echo "=========================================="
    echo "6. RECENT LAMBDA ERRORS"
    echo "=========================================="
    echo "Last 10 error logs from agent-service-dev:"
    aws logs filter-log-events \
        --log-group-name /aws/lambda/agent-service-dev \
        --filter-pattern "INVALID_PAYMENT_INSTRUMENT" \
        --max-items 10 \
        --query 'events[*].message' \
        --output text
    echo ""
    
    echo "=========================================="
    echo "7. PAYMENT METHOD STATUS"
    echo "=========================================="
    echo "Note: Payment method details must be verified in AWS Console"
    echo "Go to: https://console.aws.amazon.com/billing/home#/paymentmethods"
    echo ""
    echo "Billing Account Status:"
    aws organizations describe-account \
        --account-id $(aws sts get-caller-identity --query 'Account' --output text) \
        --output json 2>/dev/null || echo "Not in an organization or no permissions"
    echo ""
    
    echo "=========================================="
    echo "8. MARKETPLACE SUBSCRIPTIONS"
    echo "=========================================="
    echo "Active Marketplace Subscriptions:"
    aws marketplace-catalog list-entities \
        --catalog "AWSMarketplace" \
        --entity-type "Offer" \
        --output json 2>/dev/null || echo "No marketplace permissions or no subscriptions"
    echo ""
    
    echo "=========================================="
    echo "9. CLOUDTRAIL BEDROCK EVENTS (Last 24h)"
    echo "=========================================="
    echo "Recent Bedrock API calls:"
    aws cloudtrail lookup-events \
        --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::Bedrock::Model \
        --max-results 10 \
        --query 'Events[*].{Time:EventTime,Name:EventName,User:Username,Error:ErrorCode}' \
        --output table 2>/dev/null || echo "CloudTrail not enabled or no permissions"
    echo ""
    
    echo "=========================================="
    echo "10. RECOMMENDED ACTIONS"
    echo "=========================================="
    echo "Based on this diagnostic:"
    echo ""
    echo "1. If CLI test (section 5) SUCCEEDS:"
    echo "   → Issue is with Lambda IAM role or configuration"
    echo "   → Check Lambda execution role permissions"
    echo ""
    echo "2. If CLI test (section 5) FAILS with INVALID_PAYMENT_INSTRUMENT:"
    echo "   → Issue is with AWS account payment validation"
    echo "   → Contact AWS Support immediately"
    echo "   → Provide this diagnostic report"
    echo ""
    echo "3. Payment Method Verification:"
    echo "   → Go to: https://console.aws.amazon.com/billing/home#/paymentmethods"
    echo "   → Verify card is active and verified"
    echo "   → Check AutoPay is enabled"
    echo ""
    echo "4. AWS Support Contact:"
    echo "   → https://console.aws.amazon.com/support/home"
    echo "   → Use template in AWS_SUPPORT_TICKET_TEMPLATE.md"
    echo "   → Attach this diagnostic report"
    echo ""
    
    echo "=========================================="
    echo "DIAGNOSTIC REPORT COMPLETE"
    echo "=========================================="
    echo "Report saved to: $OUTPUT_FILE"
    echo ""
    echo "Next Steps:"
    echo "1. Review the output above"
    echo "2. Open AWS Support ticket using AWS_SUPPORT_TICKET_TEMPLATE.md"
    echo "3. Attach this diagnostic report to the ticket"
    echo ""
    
} | tee "$OUTPUT_FILE"

# Cleanup
rm -f /tmp/bedrock-test.json /tmp/bedrock-response.json

echo ""
echo "Diagnostic report saved to: $OUTPUT_FILE"
echo "Send this file to AWS Support with your ticket"
