#!/bin/bash

# Test script to verify Terraform state locking works correctly

echo "🔒 Testing Terraform State Locking"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if DynamoDB table exists
echo "1️⃣  Checking if DynamoDB lock table exists..."
TABLE_STATUS=$(aws dynamodb describe-table --table-name terraform-state-lock --query 'Table.TableStatus' --output text 2>/dev/null)

if [ "$TABLE_STATUS" = "ACTIVE" ]; then
    echo -e "${GREEN}✓ DynamoDB table 'terraform-state-lock' is ACTIVE${NC}"
else
    echo -e "${RED}✗ DynamoDB table not found. Run 'terraform apply' in bootstrap/ first${NC}"
    exit 1
fi

# Check if S3 bucket exists
echo ""
echo "2️⃣  Checking if S3 state bucket exists..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-state-${ACCOUNT_ID}"

if aws s3 ls "s3://${BUCKET_NAME}" &>/dev/null; then
    echo -e "${GREEN}✓ S3 bucket '${BUCKET_NAME}' exists${NC}"
else
    echo -e "${RED}✗ S3 bucket not found. Run 'terraform apply' in bootstrap/ first${NC}"
    exit 1
fi

# Test concurrent locking
echo ""
echo "3️⃣  Testing concurrent lock acquisition..."
echo -e "${YELLOW}This will simulate two Terraform processes trying to run simultaneously${NC}"
echo ""

# Create a test directory
TEST_DIR="/tmp/terraform-lock-test"
mkdir -p "$TEST_DIR"

# Create a simple Terraform config
cat > "$TEST_DIR/main.tf" <<EOF
terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "test/lock-test.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "null_resource" "test" {
  triggers = {
    timestamp = timestamp()
  }
}
EOF

cd "$TEST_DIR"

# Initialize
echo "Initializing test Terraform config..."
terraform init -input=false &>/dev/null

# Start first apply in background (will wait for approval)
echo ""
echo "Starting first terraform apply (will wait for approval)..."
(
  echo "yes" | terraform apply -auto-approve &
  FIRST_PID=$!
  echo "First process PID: $FIRST_PID"
  sleep 2
) &

FIRST_PROCESS=$!
sleep 3

# Try second apply (should fail with lock error)
echo ""
echo "Attempting second terraform apply (should be blocked by lock)..."
terraform apply -auto-approve 2>&1 | grep -q "Error acquiring the state lock"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ State locking is working! Second apply was blocked.${NC}"
    LOCK_WORKING=true
else
    echo -e "${RED}✗ State locking may not be working properly${NC}"
    LOCK_WORKING=false
fi

# Check lock in DynamoDB
echo ""
echo "4️⃣  Checking lock entry in DynamoDB..."
LOCK_ENTRY=$(aws dynamodb scan --table-name terraform-state-lock --query 'Items[0]' --output json 2>/dev/null)

if [ -n "$LOCK_ENTRY" ] && [ "$LOCK_ENTRY" != "null" ]; then
    echo -e "${GREEN}✓ Lock entry found in DynamoDB:${NC}"
    echo "$LOCK_ENTRY" | jq '.'
else
    echo -e "${YELLOW}⚠ No active locks found (process may have completed)${NC}"
fi

# Cleanup
echo ""
echo "5️⃣  Cleaning up test resources..."
kill $FIRST_PROCESS 2>/dev/null
terraform destroy -auto-approve &>/dev/null
rm -rf "$TEST_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Summary
echo ""
echo "=================================="
echo "📊 Test Summary"
echo "=================================="
if [ "$LOCK_WORKING" = true ]; then
    echo -e "${GREEN}✅ State locking is configured correctly!${NC}"
    echo ""
    echo "What this means:"
    echo "  • Multiple terraform applies cannot run simultaneously"
    echo "  • State file is protected from corruption"
    echo "  • Lock information is stored in DynamoDB"
    echo "  • Locks are automatically released when operations complete"
else
    echo -e "${RED}❌ State locking test failed${NC}"
    echo "Please check your backend configuration"
fi
echo ""
