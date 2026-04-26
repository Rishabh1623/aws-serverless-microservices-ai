#!/bin/bash
# Deploy Agent Service with Claude 3.5 Sonnet (Latest Model)

set -e

echo "=========================================="
echo "Deploying Agent Service with Claude 3.5"
echo "=========================================="

cd ~/aws-serverless-microservices-ai/agent-service

echo ""
echo "Step 1: Clean build artifacts..."
rm -rf build agent-service-lambda.zip

echo ""
echo "Step 2: Build Lambda package with Docker..."
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  public.ecr.aws/lambda/python:3.10 \
  bash -c "
    pip install --no-cache-dir -r requirements.txt -t /workspace/build/ && \
    cp src/agent_handler/*.py /workspace/build/ && \
    cp -r src/agent_handler/tools /workspace/build/
  "

echo ""
echo "Step 3: Create deployment package..."
cd build && zip -r ../agent-service-lambda.zip . -q && cd ..
echo "✅ Package size: $(du -h agent-service-lambda.zip | cut -f1)"

echo ""
echo "Step 4: Deploy with Terraform..."
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform apply -auto-approve

echo ""
echo "Step 5: Wait for Lambda to be ready..."
sleep 20

echo ""
echo "Step 6: Test with a real message..."
curl -X POST $(terraform output -raw api_endpoint) \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris for next week?","userId":"test-user","sessionId":"test-session-001"}'

echo ""
echo ""
echo "Step 7: Check CloudWatch logs..."
sleep 5
aws logs tail /aws/lambda/agent-service-dev --since 2m --format short

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Model: Claude 3.5 Sonnet (anthropic.claude-3-5-sonnet-20241022-v2:0)"
echo "API Endpoint: $(cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev && terraform output -raw api_endpoint)"
echo ""
echo "IMPORTANT: Make sure Claude 3.5 Sonnet is enabled in your AWS Bedrock console:"
echo "https://console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess"
