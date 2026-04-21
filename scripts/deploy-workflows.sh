#!/bin/bash

# Deploy AWS Step Functions Workflows
# This script deploys all three workflow orchestrators

set -e

echo "=========================================="
echo "AWS Step Functions Workflow Deployment"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to deploy a workflow
deploy_workflow() {
    local workflow_name=$1
    local workflow_path=$2
    
    echo -e "${BLUE}Deploying ${workflow_name}...${NC}"
    cd "$workflow_path"
    
    terraform init
    terraform plan
    
    read -p "Apply changes? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        terraform apply -auto-approve
        echo -e "${GREEN}✅ ${workflow_name} deployed successfully!${NC}"
        echo ""
        terraform output
        echo ""
    else
        echo -e "${YELLOW}⏭️  Skipped ${workflow_name}${NC}"
    fi
    
    cd - > /dev/null
    echo ""
}

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"
echo ""

# Deploy workflows
echo "=========================================="
echo "1. Hotel Booking Workflow"
echo "=========================================="
deploy_workflow "Hotel Booking Workflow" "terraform/workflows/hotel-booking"

echo "=========================================="
echo "2. Order Processing Workflow"
echo "=========================================="
deploy_workflow "Order Processing Workflow" "terraform/workflows/order-processing"

echo "=========================================="
echo "3. Payment Processing Workflow"
echo "=========================================="
deploy_workflow "Payment Processing Workflow" "terraform/workflows/payment-processing"

echo ""
echo -e "${GREEN}=========================================="
echo "✅ All workflows deployed!"
echo "==========================================${NC}"
echo ""
echo "View workflows in AWS Console:"
echo "https://console.aws.amazon.com/states/home?region=us-east-1"
echo ""
echo "Next steps:"
echo "1. Test each workflow with sample data"
echo "2. Set up CloudWatch alarms"
echo "3. Integrate with API Gateway"
echo "4. Update frontend to use workflows"
