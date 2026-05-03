#!/bin/bash
# Agent Service IAM Fix Deployment Script
# Run this on EC2: ubuntu@35.154.6.204
#
# This script:
# 1. Pulls latest code from git
# 2. Builds Lambda deployment package
# 3. Deploys IAM policy updates via Terraform
# 4. Tests the agent endpoint
# 5. Verifies Lambda logs

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Agent Service IAM Fix Deployment"
echo "==========================================${NC}"
echo ""

# Step 1: Navigate to project
echo -e "${YELLOW}Step 1: Navigating to project directory...${NC}"
cd ~/aws-serverless-microservices-ai
echo "Current directory: $(pwd)"
echo -e "${GREEN}✅ Step 1 complete${NC}"

# Step 2: Pull latest changes
echo ""
echo -e "${YELLOW}Step 2: Pulling latest changes from git...${NC}"
git pull origin main
echo -e "${GREEN}✅ Git pull complete${NC}"

# Step 3: Verify changes
echo ""
echo -e "${YELLOW}Step 3: Verifying recent commits...${NC}"
git log --oneline -3
echo -e "${GREEN}✅ Step 3 complete${NC}"

# Step 4: Build Lambda package
echo ""
echo -e "${YELLOW}Step 4: Building Lambda deployment package...${NC}"
cd agent-service

# Check if build script exists
if [ ! -f "build-lambda.sh" ]; then
    echo -e "${RED}❌ Error: build-lambda.sh not found${NC}"
    exit 1
fi

bash build-lambda.sh
echo -e "${GREEN}✅ Lambda package built${NC}"

# Step 5: Verify package exists
echo ""
echo -e "${YELLOW}Step 5: Verifying Lambda package...${NC}"
if [ ! -f "agent-service-lambda.zip" ]; then
    echo -e "${RED}❌ Error: Lambda package not created${NC}"
    exit 1
fi

ls -lh agent-service-lambda.zip
PACKAGE_SIZE=$(du -h agent-service-lambda.zip | cut -f1)
echo "Package size: $PACKAGE_SIZE"
echo -e "${GREEN}✅ Package verified${NC}"

# Step 6: Navigate to Terraform directory
echo ""
echo -e "${YELLOW}Step 6: Navigating to Terraform directory...${NC}"
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
echo "Current directory: $(pwd)"
echo -e "${GREEN}✅ Step 6 complete${NC}"

# Step 7: Initialize Terraform
echo ""
echo -e "${YELLOW}Step 7: Initializing Terraform...${NC}"
terraform init
echo -e "${GREEN}✅ Terraform initialized${NC}"

# Step 8: Review Terraform plan
echo ""
echo -e "${YELLOW}Step 8: Reviewing Terraform plan...${NC}"
echo -e "${BLUE}==========================================${NC}"
terraform plan
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Review the plan above.${NC}"
read -p "Continue with apply? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${RED}❌ Deployment cancelled by user${NC}"
    exit 1
fi

# Step 9: Apply Terraform changes
echo ""
echo -e "${YELLOW}Step 9: Applying Terraform changes...${NC}"
terraform apply -auto-approve
echo -e "${GREEN}✅ Terraform apply complete${NC}"

# Step 10: Wait for IAM propagation
echo ""
echo -e "${YELLOW}Step 10: Waiting for IAM propagation (10 seconds)...${NC}"
for i in {10..1}; do
    echo -ne "  Waiting... $i seconds remaining\r"
    sleep 1
done
echo ""
echo -e "${GREEN}✅ IAM propagation complete${NC}"

# Step 11: Test the endpoint
echo ""
echo -e "${YELLOW}Step 11: Testing agent endpoint...${NC}"
echo -e "${BLUE}==========================================${NC}"
RESPONSE=$(curl -s -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}')

# Check if jq is available
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq '.'
else
    echo "$RESPONSE"
fi

echo -e "${BLUE}==========================================${NC}"

# Check if response contains error
if echo "$RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}⚠️  Warning: API response contains error${NC}"
else
    echo -e "${GREEN}✅ API response looks good${NC}"
fi

# Step 12: Check Lambda logs
echo ""
echo -e "${YELLOW}Step 12: Checking Lambda logs (last 2 minutes)...${NC}"
echo -e "${BLUE}==========================================${NC}"
aws logs tail /aws/lambda/agent-service-dev --since 2m
echo -e "${BLUE}==========================================${NC}"

# Final summary
echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Summary:"
echo "  - Lambda package: $PACKAGE_SIZE"
echo "  - Terraform: Applied successfully"
echo "  - API endpoint: Tested"
echo "  - Lambda logs: Checked"
echo ""
echo "Next steps:"
echo "  1. Review the API response above"
echo "  2. Check logs for any errors"
echo "  3. If successful, test with complex queries:"
echo ""
echo "     curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"message\":\"I need a luxury hotel in Paris for 3 nights\",\"userId\":\"test\",\"sessionId\":\"test\"}'"
echo ""
echo "  4. Update frontend configuration"
echo "  5. Monitor CloudWatch metrics"
echo ""
echo -e "${GREEN}Deployment script completed successfully!${NC}"
