#!/bin/bash
# Complete deployment script for new AWS account

set -e

echo "=========================================="
echo "AWS Serverless Microservices Deployment"
echo "New Account Setup"
echo "=========================================="
echo ""

# Get account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# Step 1: Update backend configuration
echo "Step 1: Updating Terraform backend configuration..."
bash update-terraform-backend.sh

# Step 2: Bootstrap (create S3 bucket if not exists)
echo ""
echo "Step 2: Verifying Terraform state bucket..."
if aws s3 ls s3://terraform-state-${ACCOUNT_ID} 2>/dev/null; then
    echo "✅ Terraform state bucket exists"
else
    echo "Creating Terraform state bucket..."
    aws s3 mb s3://terraform-state-${ACCOUNT_ID} --region ${REGION}
    aws s3api put-bucket-versioning \
        --bucket terraform-state-${ACCOUNT_ID} \
        --versioning-configuration Status=Enabled
    echo "✅ Terraform state bucket created"
fi

# Step 3: Deploy services in order
echo ""
echo "Step 3: Deploying services..."
echo ""

# Deploy Hotel Service
echo "Deploying Hotel Service..."
cd terraform/hotel-service/dev
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
HOTEL_API_URL=$(terraform output -raw api_gateway_url)
echo "✅ Hotel Service deployed: $HOTEL_API_URL"
cd ../../..

# Deploy Cart Service
echo ""
echo "Deploying Cart Service..."
cd terraform/cart-service/dev
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
CART_API_URL=$(terraform output -raw api_gateway_url)
echo "✅ Cart Service deployed: $CART_API_URL"
cd ../../..

# Deploy Payment Service
echo ""
echo "Deploying Payment Service..."
cd terraform/payment-service/dev
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
PAYMENT_API_URL=$(terraform output -raw api_gateway_url)
echo "✅ Payment Service deployed: $PAYMENT_API_URL"
cd ../../..

# Deploy Order Service
echo ""
echo "Deploying Order Service..."
cd terraform/order-service/dev
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
ORDER_API_URL=$(terraform output -raw api_gateway_url)
echo "✅ Order Service deployed: $ORDER_API_URL"
cd ../../..

# Build and Deploy Agent Service
echo ""
echo "Deploying Agent Service..."
cd agent-service
rm -f agent-service-lambda.zip
bash build-lambda.sh
cd ../terraform/agent-service/dev
terraform init -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
AGENT_API_URL=$(terraform output -raw api_gateway_url)
echo "✅ Agent Service deployed: $AGENT_API_URL"
cd ../../..

# Step 4: Add sample hotels
echo ""
echo "Step 4: Adding sample hotels..."
bash scripts/add-sample-hotels.sh

# Step 5: Test all services
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "API Endpoints:"
echo "  Hotel Service:   $HOTEL_API_URL"
echo "  Cart Service:    $CART_API_URL"
echo "  Payment Service: $PAYMENT_API_URL"
echo "  Order Service:   $ORDER_API_URL"
echo "  Agent Service:   $AGENT_API_URL"
echo ""
echo "Testing Agent Service..."
curl -X POST ${AGENT_API_URL}/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'
echo ""
echo ""
echo "✅ All services deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Test all endpoints"
echo "2. Configure frontend with new API URLs"
echo "3. Set up monitoring and alarms"
