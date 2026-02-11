#!/bin/bash
# Deploy Shopping Agent Service with Fixed Dependencies
# Run this on EC2 instance after pulling latest changes from GitHub

set -e

echo "=========================================="
echo "Shopping Agent Service - Deployment Fix"
echo "=========================================="
echo ""

# Navigate to project root
cd ~/aws-serverless-microservices-ai

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main
echo ""

# Navigate to agent service
cd agent-service

# Make build script executable
chmod +x build-lambda.sh

# Build Lambda package with Docker
echo "🔨 Building Lambda package with Python 3.11 dependencies..."
./build-lambda.sh
echo ""

# Move package to project root for Terraform
mv agent-service-lambda.zip ../
echo "📦 Moved package to project root"
echo ""

# Navigate to Terraform directory
cd ../terraform/agent-service/dev

# Deploy with Terraform
echo "🚀 Deploying to AWS Lambda..."
terraform apply -auto-approve
echo ""

# Get API endpoint
AGENT_API=$(terraform output -raw api_gateway_url)
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Agent API: $AGENT_API"
echo ""

# Save to endpoints file
echo "Shopping Agent: $AGENT_API" >> ~/api-endpoints.txt

# Wait for Lambda to be ready
echo "⏳ Waiting 10 seconds for Lambda to be ready..."
sleep 10
echo ""

# Test the agent
echo "🧪 Testing Shopping Agent..."
echo ""
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me available products",
    "userId": "testuser"
  }'
echo ""
echo ""

# Check logs
echo "📋 Recent Lambda logs:"
aws logs tail /aws/lambda/agent-service-dev --since 2m

echo ""
echo "=========================================="
echo "Deployment script completed!"
echo "=========================================="
