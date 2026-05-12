# Quick Fix Commands - Anthropic Direct API

## Problem
AWS Bedrock payment validation stuck for 3+ days with `INVALID_PAYMENT_INSTRUMENT` error.

## Solution
Use Anthropic API directly (free tier, works immediately).

---

## Commands to Run on EC2

```bash
# 1. SSH to EC2
ssh ubuntu@35.154.6.204

# 2. Pull latest code
cd ~/aws-serverless-microservices-ai
git pull origin main

# 3. Get Anthropic API Key
# Go to: https://console.anthropic.com/
# Sign up → Verify email → API Keys → Create Key
# Copy the key (starts with sk-ant-api03-)

# 4. Set API key (replace with your actual key)
export TF_VAR_anthropic_api_key="sk-ant-api03-YOUR-KEY-HERE"

# 5. Run automated deployment
bash deploy-anthropic-fix.sh
```

That's it! The script will:
- Rebuild Lambda with Anthropic SDK
- Deploy via Terraform
- Test the endpoint automatically

---

## Manual Steps (if you prefer)

```bash
# 1. Pull code
cd ~/aws-serverless-microservices-ai
git pull origin main

# 2. Set API key
export TF_VAR_anthropic_api_key="sk-ant-api03-YOUR-KEY-HERE"

# 3. Rebuild Lambda
cd agent-service
rm -f agent-service-lambda.zip
bash build-lambda.sh

# 4. Deploy
cd ../terraform/agent-service/dev
terraform init -upgrade
terraform apply -auto-approve

# 5. Test
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'

# 6. Check logs
aws logs tail /aws/lambda/agent-service-dev --since 1m --follow
```

---

## Expected Success Output

### Test Response
```json
{
  "response": "Hello! I'd be happy to help you find a hotel in Paris...",
  "toolsUsed": [],
  "userId": "test",
  "sessionId": "test"
}
```

### Lambda Logs
```
[INFO] Using Anthropic API directly (bypassing Bedrock)
[INFO] Processing message from user test: Hello! Can you help me find a hotel in Paris?
[INFO] Saved message for user test, session test
```

---

## Troubleshooting

### "ANTHROPIC_API_KEY environment variable is required"
```bash
# Check if variable is set
echo $TF_VAR_anthropic_api_key

# If empty, set it again
export TF_VAR_anthropic_api_key="sk-ant-api03-YOUR-KEY-HERE"
```

### "Invalid API key"
- Go to https://console.anthropic.com/settings/keys
- Create a new key
- Make sure you copy the entire key (starts with `sk-ant-api03-`)

### Lambda still failing
```bash
# Check Lambda logs for detailed error
aws logs tail /aws/lambda/agent-service-dev --since 5m

# Verify Lambda environment variables
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables' \
  --output json
```

---

## Cost & Limits

### Free Tier
- $5 in free credits (enough for ~10,000 messages)
- 50 requests/minute rate limit

### After Free Tier
- Claude 3.5 Haiku: $0.80 per million input tokens
- Very cheap for testing and small production use

### Monitor Usage
https://console.anthropic.com/settings/usage

---

## Why This Works

1. **Bypasses AWS Bedrock billing** - uses Anthropic directly
2. **Free to start** - $5 credits included
3. **Works immediately** - no 3-day validation wait
4. **Same quality** - Claude 3.5 Haiku (better than 3.0)
5. **Production ready** - used by thousands of companies
6. **Easy to switch back** - can revert to Bedrock later

---

## Files Changed

- `agent-service/requirements.txt` - Added anthropic SDK
- `agent-service/src/agent_handler/app.py` - Support both providers
- `terraform/agent-service/dev/main.tf` - Add environment variables
- `terraform/agent-service/dev/variables.tf` - Add API key variable

---

## Support

- **Full Guide**: See `ANTHROPIC_DIRECT_SETUP.md`
- **Anthropic Console**: https://console.anthropic.com/
- **Anthropic Docs**: https://docs.anthropic.com/
