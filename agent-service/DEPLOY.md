# Shopping Agent Service - Deployment Guide

## Prerequisites
- Docker installed on EC2 instance
- AWS CLI configured
- Terraform initialized in `terraform/agent-service/dev/`

## Step 1: Build Lambda Package

```bash
cd ~/aws-serverless-microservices-ai/agent-service

# Make build script executable
chmod +x build-lambda.sh

# Build the Lambda package using Docker
./build-lambda.sh
```

This will create `agent-service-lambda.zip` (~40MB) with all Python 3.11 dependencies.

## Step 2: Deploy with Terraform

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# Deploy the updated Lambda function
terraform apply -auto-approve

# Get the API endpoint
AGENT_API=$(terraform output -raw api_gateway_url)
echo "Agent API: $AGENT_API"
```

## Step 3: Test the Agent

```bash
# Test the shopping agent
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me laptops under $1000",
    "userId": "testuser"
  }'
```

## Expected Response

```json
{
  "response": "I found several laptops under $1000...",
  "toolsUsed": ["search_products"],
  "userId": "testuser",
  "sessionId": null
}
```

## Troubleshooting

### Check Lambda Logs
```bash
aws logs tail /aws/lambda/agent-service-dev --follow
```

### Verify Package Contents
```bash
unzip -l agent-service-lambda.zip | grep strands_agents
```

### Test Individual Tools
```bash
# Test product search
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{"message": "Search for products", "userId": "test"}'
```

## Import Fix Applied

Changed import from:
```python
from strands.agent import Agent  # ❌ Wrong
```

To:
```python
from strands_agents import Agent  # ✅ Correct
```

The package `strands-agents` (PyPI name with hyphen) uses `strands_agents` (Python import with underscore).
