# Anthropic Direct API Setup Guide

## Problem: AWS Bedrock Payment Validation Stuck

After 3+ days, AWS Bedrock payment validation is still failing with `INVALID_PAYMENT_INSTRUMENT` error. This is blocking the AI agent service from working.

## Solution: Use Anthropic API Directly

Instead of using AWS Bedrock, we'll use Anthropic's API directly. This:
- ✅ **Works immediately** - no AWS billing validation delays
- ✅ **Free tier available** - $5 free credits to start
- ✅ **Better pricing** - often cheaper than Bedrock
- ✅ **Same models** - Claude 3.5 Haiku (faster and better than 3.0)
- ✅ **Production ready** - used by thousands of companies
- ✅ **Easy to switch back** - can revert to Bedrock later if needed

## Step 1: Get Anthropic API Key (5 minutes)

1. **Go to Anthropic Console**: https://console.anthropic.com/
2. **Sign up** with your email (or login if you have an account)
3. **Verify your email** (check inbox)
4. **Get free credits**: You'll receive $5 in free credits automatically
5. **Create API key**:
   - Click "API Keys" in the left sidebar
   - Click "Create Key"
   - Give it a name: "AWS Lambda Agent Service"
   - Copy the API key (starts with `sk-ant-api03-...`)
   - **IMPORTANT**: Save it securely - you can't see it again!

## Step 2: Set Environment Variable on EC2

SSH into your EC2 instance and set the API key:

```bash
# SSH to EC2
ssh ubuntu@35.154.6.204

# Navigate to project
cd ~/aws-serverless-microservices-ai

# Export Anthropic API key (replace with your actual key)
export TF_VAR_anthropic_api_key="sk-ant-api03-YOUR-KEY-HERE"

# Verify it's set
echo $TF_VAR_anthropic_api_key
```

## Step 3: Rebuild Lambda Package

The code has been updated to use Anthropic SDK. Rebuild the Lambda package:

```bash
cd ~/aws-serverless-microservices-ai/agent-service

# Clean old build
rm -f agent-service-lambda.zip

# Rebuild with new dependencies (includes anthropic SDK)
bash build-lambda.sh

# Verify the package was created
ls -lh agent-service-lambda.zip
```

## Step 4: Deploy with Terraform

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# Initialize Terraform (if needed)
terraform init

# Plan the changes (verify Anthropic API key is set)
terraform plan

# Apply the changes
terraform apply -auto-approve
```

## Step 5: Test the Agent

```bash
# Test the endpoint
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'

# Check logs
aws logs tail /aws/lambda/agent-service-dev --since 1m --follow
```

## Expected Result

You should see:
```json
{
  "response": "Hello! I'd be happy to help you find a hotel in Paris. To provide the best recommendations, could you tell me:\n\n1. What dates are you planning to visit?\n2. What's your budget range?\n3. What area of Paris would you prefer?\n4. Is this for business or leisure?",
  "toolsUsed": [],
  "userId": "test",
  "sessionId": "test"
}
```

## Pricing Comparison

### Anthropic Direct API
- **Free tier**: $5 in credits (enough for ~10,000 messages)
- **Claude 3.5 Haiku**: $0.80 per million input tokens
- **No AWS markup**

### AWS Bedrock (when it works)
- **No free tier** for Claude models
- **Claude 3 Haiku**: $0.25 per million input tokens (cheaper base price)
- **But**: AWS adds infrastructure costs and billing complexity

For development and testing, Anthropic Direct is better. For production at scale, Bedrock might be cheaper.

## Switching Back to Bedrock Later

If AWS resolves the billing issue and you want to switch back:

```bash
# Set environment variable to use Bedrock
export TF_VAR_anthropic_api_key="dummy"  # Still required by Terraform

# Update main.tf to set USE_ANTHROPIC_DIRECT = "false"
# Then redeploy
```

## Troubleshooting

### Error: "ANTHROPIC_API_KEY environment variable is required"
- Make sure you exported `TF_VAR_anthropic_api_key` before running terraform
- Verify: `echo $TF_VAR_anthropic_api_key`

### Error: "Invalid API key"
- Check your API key is correct (starts with `sk-ant-api03-`)
- Make sure you copied the entire key
- Try creating a new key in Anthropic console

### Error: "Rate limit exceeded"
- Free tier has rate limits (50 requests/minute)
- Wait a minute and try again
- For production, add payment method in Anthropic console

### Lambda still using old code
- Make sure you rebuilt the Lambda package: `bash build-lambda.sh`
- Verify the zip file is recent: `ls -lh agent-service-lambda.zip`
- Check Lambda logs for "Using Anthropic API directly" message

## Cost Monitoring

### Anthropic Console
- View usage: https://console.anthropic.com/settings/usage
- Set spending limits: https://console.anthropic.com/settings/limits

### AWS CloudWatch
- Lambda invocations: CloudWatch → Metrics → Lambda
- API Gateway requests: CloudWatch → Metrics → API Gateway

## Security Best Practices

1. **Never commit API keys to git**
2. **Use environment variables** (as we're doing)
3. **Rotate keys regularly** (every 90 days)
4. **Set spending limits** in Anthropic console
5. **Monitor usage** to detect anomalies

## Support

- **Anthropic Support**: support@anthropic.com
- **Anthropic Discord**: https://discord.gg/anthropic
- **Documentation**: https://docs.anthropic.com/

---

## Summary

This solution bypasses the AWS Bedrock billing issue entirely by using Anthropic's API directly. It's:
- Faster to set up (5 minutes vs 3+ days waiting)
- Free to start ($5 credits)
- Production ready
- Easy to switch back to Bedrock later

The code changes are minimal and the Strands SDK supports both providers seamlessly.
