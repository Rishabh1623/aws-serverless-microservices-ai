#!/bin/bash
# Deploy OpenTelemetry fix for Agent Service

set -e

echo "🔧 Deploying OpenTelemetry 1.30.0+ fix for Agent Service..."

# Navigate to agent-service directory
cd "$(dirname "$0")"

# Clean previous build
echo "Cleaning previous build..."
rm -rf build agent-service-lambda.zip

# Create build directory
BUILD_DIR="$(pwd)/build"
mkdir -p "$BUILD_DIR"

# Copy source code
echo "Copying source code..."
cp -r src/agent_handler/* "$BUILD_DIR/"

# Install dependencies with updated OpenTelemetry versions
echo "Installing dependencies (OpenTelemetry 1.30.0+)..."
pip3 install -r requirements.txt -t "$BUILD_DIR/" --platform manylinux2014_x86_64 --only-binary=:all: --upgrade

# Verify OpenTelemetry version
echo "Verifying OpenTelemetry version..."
python3 -c "import sys; sys.path.insert(0, '$BUILD_DIR'); import opentelemetry; print(f'OpenTelemetry API version: {opentelemetry.__version__}')" || echo "OpenTelemetry check skipped"

# Create zip file
echo "Creating deployment package..."
cd "$BUILD_DIR"
zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*" > /dev/null

cd ..
echo "✅ Lambda package created: agent-service-lambda.zip"
echo "Size: $(du -h agent-service-lambda.zip | cut -f1)"

# Deploy with Terraform
echo ""
echo "📦 Deploying to AWS Lambda..."
cd ../terraform/agent-service/dev

# Initialize Terraform (if needed)
terraform init -upgrade > /dev/null 2>&1 || true

# Apply changes
echo "Running terraform apply..."
terraform apply -auto-approve

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🧪 Testing the fix..."
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent")

echo "Sending test request to: $API_ENDPOINT"
curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, I need help finding a hotel",
    "userId": "test-user-fix",
    "sessionId": "test-session-fix"
  }' \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "✅ Fix deployment complete!"
echo "Check CloudWatch Logs for detailed Lambda execution logs"
