# AI Agent Deployment Guide

## Overview
Deploy the AI Travel Assistant powered by AWS Bedrock (Claude 3 Sonnet).

## Prerequisites

### 1. Enable Bedrock Model Access
Before deploying, you must enable Claude 3 Sonnet in AWS Bedrock:

```bash
# Check if model access is enabled
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-3-sonnet-20240229-v1:0`]'

# If not enabled, go to AWS Console:
# 1. Navigate to Amazon Bedrock
# 2. Click "Model access" in left sidebar
# 3. Click "Manage model access"
# 4. Enable "Claude 3 Sonnet"
# 5. Click "Save changes"
# 6. Wait for status to show "Access granted" (takes 1-2 minutes)
```

### 2. Verify Other Services Are Deployed
The agent needs these services running:
- ✅ Hotel Service (already deployed)
- ⏳ Cart Service (optional, will deploy later)
- ⏳ Order Service (optional, will deploy later)
- ⏳ Payment Service (optional, will deploy later)

## Deployment Steps

### Step 1: Build Lambda Package

```bash
cd ~/aws-serverless-microservices-ai/agent-service
chmod +x build-lambda.sh
./build-lambda.sh
```

This creates `agent-service-lambda.zip` with all dependencies.

### Step 2: Deploy with Terraform

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform init
terraform plan
terraform apply
```

### Step 3: Get API Endpoint

```bash
terraform output api_endpoint
```

Save this URL - you'll need it for the frontend.

### Step 4: Test the Agent

```bash
# Test with curl
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I need a hotel in Miami for 3 nights",
    "userId": "test-user"
  }'
```

Expected response:
```json
{
  "response": "I'd love to help you find the perfect hotel in Miami! To give you the best recommendations: ...",
  "userId": "test-user",
  "timestamp": "..."
}
```

## Troubleshooting

### Error: "AccessDeniedException" from Bedrock
**Solution**: Enable Claude 3 Sonnet model access in Bedrock console (see Prerequisites #1)

### Error: "Lambda package not found"
**Solution**: Run `./build-lambda.sh` in agent-service directory

### Error: "Module 'strands' not found"
**Solution**: We're using the simplified version (app_simple.py) which doesn't need strands SDK

### High Latency (>10 seconds)
**Normal**: First request (cold start) can take 5-10 seconds. Subsequent requests are faster.

## Configuration

### Environment Variables (set in Terraform)
- `BEDROCK_MODEL_ID`: Claude model ID (default: claude-3-sonnet)
- `HOTEL_API_URL`: Hotel service endpoint
- `AWS_REGION`: AWS region (default: us-east-1)

### Lambda Settings
- **Memory**: 512 MB (AI processing needs more memory)
- **Timeout**: 60 seconds (Bedrock calls can take time)
- **Runtime**: Python 3.11

## Cost Estimation

### Bedrock Costs (Claude 3 Sonnet)
- Input: $0.003 per 1K tokens (~$0.01 per conversation)
- Output: $0.015 per 1K tokens (~$0.05 per conversation)
- **Estimated**: $5-20/month for 100-500 conversations

### Lambda Costs
- **Estimated**: $2-5/month for 1000 invocations

### Total Monthly Cost
- **Development**: ~$10-25/month
- **Production** (1000 users): ~$100-200/month

## Next Steps

After deployment:
1. Update frontend config with agent API endpoint
2. Test AI assistant in browser
3. Monitor CloudWatch logs for errors
4. Set up CloudWatch alarms for high costs

## Frontend Integration

Update `frontend/src/config.js`:
```javascript
AGENT_API: 'https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com'
```

The AI Assistant page is already built at `frontend/src/pages/AIAssistant.jsx`.
