#!/bin/bash

# Deploy Hotel Booking Durable Function
# This script handles the complete deployment process

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LAMBDA_DIR="$PROJECT_ROOT/hotel-service/src/booking_orchestrator"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/hotel-service-durable"

echo "=========================================="
echo "Deploying Hotel Booking Durable Function"
echo "=========================================="

# Step 1: Install Lambda dependencies
echo ""
echo "Step 1: Installing Lambda dependencies..."
cd "$LAMBDA_DIR"

# Create a clean package directory
if [ -d "package" ]; then
    rm -rf package
fi
mkdir -p package

# Install dependencies to package directory
pip install -r requirements.txt -t package/

# Copy Lambda code to package
cp app.py package/

echo "✓ Dependencies installed"

# Step 2: Validate Terraform configuration
echo ""
echo "Step 2: Validating Terraform configuration..."
cd "$TERRAFORM_DIR"

terraform init -upgrade
terraform validate

echo "✓ Terraform configuration valid"

# Step 3: Plan deployment
echo ""
echo "Step 3: Planning deployment..."
terraform plan -out=tfplan

echo ""
echo "=========================================="
echo "Review the plan above."
echo "=========================================="
read -p "Do you want to apply this plan? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Step 4: Apply deployment
echo ""
echo "Step 4: Applying deployment..."
terraform apply tfplan
rm -f tfplan

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="

# Get outputs
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "N/A")
FUNCTION_NAME=$(terraform output -raw function_name 2>/dev/null || echo "N/A")

echo ""
echo "Deployment Details:"
echo "  Function Name: $FUNCTION_NAME"
echo "  API Endpoint:  $API_ENDPOINT"
echo ""
echo "Test the endpoint:"
echo "  curl -X POST $API_ENDPOINT \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"userId\":\"user123\",\"hotelId\":\"hotel-001\",\"roomId\":\"room-001\",\"checkIn\":\"2024-06-15\",\"checkOut\":\"2024-06-20\",\"guests\":2,\"guestDetails\":{\"name\":\"John Doe\",\"email\":\"john@example.com\"}}'"
echo ""
echo "Monitor logs:"
echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
