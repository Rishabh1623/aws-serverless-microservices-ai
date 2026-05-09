# Lambda Layer Deployment Instructions

## Overview
This deployment uses **Lambda Layers** to separate heavy dependencies (Strands SDK, Anthropic, Pydantic) from application code. This solves binary compatibility issues without requiring Docker.

## Architecture
- **Lambda Layer**: Contains Strands Agents SDK, Anthropic, Pydantic, OpenTelemetry (built once)
- **Lambda Function**: Contains only application code + lightweight dependencies (boto3, requests)

## Deployment Steps

### 1. Pull Latest Changes
```bash
cd ~/aws-serverless-microservices-ai
git pull origin main
```

### 2. Build Lambda Layer (One-Time)
```bash
cd ~/aws-serverless-microservices-ai/agent-service
chmod +x build-layer.sh
bash build-layer.sh
```

This creates `layer.zip` (~50-100MB) containing all heavy dependencies.

### 3. Build Lambda Package (Code Only)
```bash
cd ~/aws-serverless-microservices-ai/agent-service
chmod +x build-lambda-minimal.sh
bash build-lambda-minimal.sh
```

This creates `agent-service-lambda.zip` (~5-10MB) containing only your code.

### 4. Deploy with Terraform
```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform apply -auto-approve
```

Terraform will:
- Upload the layer.zip as a Lambda Layer
- Upload the agent-service-lambda.zip as the Lambda function
- Attach the layer to the function

### 5. Add Sample Hotels to DynamoDB
```bash
cd ~/aws-serverless-microservices-ai
chmod +x scripts/add-sample-hotels-aws.sh
bash scripts/add-sample-hotels-aws.sh
```

### 6. Test Deployment

**Test Hotel API:**
```bash
HOTEL_API=$(cd terraform/hotel-service/dev && terraform output -raw api_gateway_url)
curl "${HOTEL_API}/hotels?destination=Paris"
```

Expected: Returns 1 hotel (Le Grand Paris)

**Test Agent API:**
```bash
AGENT_API=$(cd terraform/agent-service/dev && terraform output -raw api_gateway_url)
curl -X POST "${AGENT_API}/agent" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","userId":"test","sessionId":"test"}'
```

Expected: Returns a friendly greeting from the AI agent

### 7. Check Logs (If Errors)
```bash
aws logs tail /aws/lambda/agent-service-dev --follow
```

## Benefits of Lambda Layers Approach

✅ **No Docker Required** - Build on any Linux system
✅ **No Binary Compatibility Issues** - Layer handles all compiled dependencies
✅ **Faster Deployments** - Layer uploaded once, code updates are small (~5MB vs ~100MB)
✅ **Easier Debugging** - Separate dependencies from code
✅ **Cost Efficient** - Smaller packages = faster cold starts

## Troubleshooting

### Layer Too Large
If layer.zip exceeds 250MB (uncompressed), split into multiple layers:
- Layer 1: Strands + Anthropic
- Layer 2: Pydantic + OpenTelemetry

### Import Errors
Check Lambda logs to see which package is missing, then add it to either:
- `build-layer.sh` (for heavy dependencies)
- `build-lambda-minimal.sh` (for lightweight dependencies)

### Bedrock Quota Exceeded
If you see "Too many tokens per day":
1. Go to AWS Service Quotas console
2. Search for "Claude 3 Haiku"
3. Request increase to 1,000,000 tokens/day
4. Or wait until tomorrow when quota resets

## Files Modified
- `terraform/agent-service/dev/main.tf` - Added Lambda Layer support
- `agent-service/build-layer.sh` - New script to build layer
- `agent-service/build-lambda-minimal.sh` - New script to build minimal package
- `scripts/add-sample-hotels-aws.sh` - Script to populate DynamoDB with test data
