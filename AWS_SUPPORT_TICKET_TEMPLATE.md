# AWS Support Ticket Template - Bedrock Payment Validation Issue

## How to Contact AWS Support

### Option 1: AWS Support Center (Recommended)
1. Go to: https://console.aws.amazon.com/support/home
2. Click **"Create case"**
3. Select **"Account and billing support"** (this is FREE even without a support plan)
4. Fill in the details below

### Option 2: AWS Bedrock Team Direct
- Email: aws-bedrock-support@amazon.com
- Subject: "URGENT: Bedrock Payment Validation Stuck for 3+ Days - Account ID: 600105205879"

---

## Support Ticket Details

### Subject
```
URGENT: Bedrock INVALID_PAYMENT_INSTRUMENT Error for 3+ Days - Account 600105205879
```

### Category
- **Service**: Amazon Bedrock
- **Category**: Account and Billing
- **Severity**: Business-critical (if you have support plan) or Normal

### Description
```
Hello AWS Support Team,

I am experiencing a critical issue with Amazon Bedrock payment validation that has been blocking my application for over 3 days.

ISSUE SUMMARY:
- AWS Account ID: 600105205879
- Region: us-east-1
- Error: "INVALID_PAYMENT_INSTRUMENT: A valid payment instrument must be provided"
- Duration: 3+ days (since first Bedrock Playground use)

WHAT I'VE VERIFIED:
✅ Payment method (Visa card in INR) is added and verified in AWS Console
✅ AutoPay is enabled
✅ Claude 3 Haiku works successfully in Bedrock Playground (console)
✅ IAM permissions are correctly configured for Lambda
✅ Model access is granted (can invoke from console)

WHAT'S FAILING:
❌ Programmatic API access from Lambda fails with INVALID_PAYMENT_INSTRUMENT
❌ Error persists for 3+ days despite valid payment method

TECHNICAL DETAILS:
- Model: anthropic.claude-3-haiku-20240307-v1:0
- Lambda Function: agent-service-dev
- Lambda IAM Role: agent-service-dev-lambda-role
- API Call: bedrock-runtime:ConverseStream
- Error Message: "Model access is denied due to INVALID_PAYMENT_INSTRUMENT"

WHAT I NEED:
1. Immediate validation of my payment method for programmatic Bedrock access
2. Confirmation that my Visa card in INR is acceptable for Bedrock
3. Estimated time for payment validation to complete
4. Any additional steps required to enable programmatic access

BUSINESS IMPACT:
This is blocking my production AI agent service deployment. I have successfully tested in the console, but Lambda API calls continue to fail.

LOGS:
```
[ERROR] An error occurred (AccessDeniedException) when calling the ConverseStream operation: 
Model access is denied due to INVALID_PAYMENT_INSTRUMENT:A valid payment instrument must be provided.
Your AWS Marketplace subscription for this model cannot be completed at this time.
└ Bedrock region: us-east-1
└ Model id: anthropic.claude-3-haiku-20240307-v1:0
```

Please expedite this issue as it has been blocking development for 3+ days.

Thank you,
[Your Name]
```

---

## Additional Information to Provide if Asked

### 1. Account Details
- **Account ID**: 600105205879
- **Region**: us-east-1
- **Payment Currency**: INR (Indian Rupees)
- **Payment Method**: Visa card
- **AutoPay**: Enabled

### 2. Timeline
- **Day 0**: Added payment method to AWS account
- **Day 0**: Successfully invoked Claude 3 Haiku in Bedrock Playground
- **Day 0-3**: Lambda API calls fail with INVALID_PAYMENT_INSTRUMENT
- **Day 3+**: Still failing, no automatic resolution

### 3. What Works
- ✅ Bedrock Playground (console) - Claude responds successfully
- ✅ IAM permissions verified
- ✅ Model access granted
- ✅ Payment method added and verified

### 4. What Doesn't Work
- ❌ Lambda programmatic API calls
- ❌ bedrock-runtime:InvokeModel from Lambda
- ❌ bedrock-runtime:ConverseStream from Lambda

### 5. IAM Policy (if they ask)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
        "arn:aws:bedrock:us-east-1:600105205879:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
      ]
    }
  ]
}
```

---

## Expected Response Time

- **Account and Billing Support**: 12-24 hours (FREE)
- **Business Support**: 12 hours
- **Enterprise Support**: 1 hour (critical issues)

---

## Follow-Up Actions

### If AWS Says "Wait 24-48 Hours"
Reply with:
```
I have already waited 3+ days. This is beyond the normal validation period.
Can you please manually review and expedite my account validation?
```

### If AWS Says "Payment Method Not Supported"
Ask:
```
1. Is INR (Indian Rupees) supported for Bedrock?
2. What payment methods are accepted?
3. Why does console access work but API access doesn't?
```

### If AWS Says "Try Different Payment Method"
Ask:
```
Can you confirm which payment methods are supported for Bedrock in India?
I can add a different card if needed, but I need to know what will work.
```

---

## Alternative: Try AWS Marketplace Subscription

Some users report that explicitly subscribing via AWS Marketplace helps:

1. Go to: https://aws.amazon.com/marketplace/pp/prodview-yjvxvqxvqvqxq
2. Search for "Amazon Bedrock"
3. Click "Continue to Subscribe"
4. Accept terms and subscribe

This might trigger the payment validation to complete.

---

## Escalation Path

If support doesn't respond within 24 hours:

1. **Post on AWS Forums**: https://repost.aws/tags/TA4IvCeWI1TE-6qHz3b6Ql_g/amazon-bedrock
2. **Tweet @AWSSupport**: Public tweets often get faster responses
3. **AWS Developer Slack**: If you have access
4. **Contact AWS Account Manager**: If you have one assigned

---

## Important Notes

1. **Be polite but firm** - emphasize the 3+ day wait
2. **Provide all technical details** - makes it easier for support to help
3. **Ask for escalation** - if first-level support can't help
4. **Request callback** - if available in your region
5. **Document everything** - keep ticket numbers and responses

---

## What AWS Support Can Do

- Manually validate your payment method
- Expedite the validation process
- Provide alternative payment options
- Grant temporary access while validation completes
- Explain exact requirements for your region

---

## Backup Plan

If AWS Support takes too long, you can:
1. Use the Anthropic Direct API solution I provided (works immediately)
2. Switch back to Bedrock once AWS resolves the issue
3. The code supports both - just change environment variable

But I understand you want Bedrock working properly.
