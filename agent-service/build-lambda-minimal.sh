#!/bin/bash
# Build minimal Lambda package (code only, no heavy dependencies)
# Heavy dependencies are provided via Lambda Layer

set -e

echo "📦 Building minimal Lambda package..."

BUILD_DIR="$(pwd)/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Install ONLY lightweight dependencies
echo "Installing lightweight dependencies..."
pip3 install boto3 requests python-json-logger -t "$BUILD_DIR/" --upgrade

# Copy source code
echo "Copying source code..."
cp -r src/agent_handler/* "$BUILD_DIR/"

# Create zip file
echo "Creating deployment package..."
cd "$BUILD_DIR"
zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*"

cd ..
echo "✅ Lambda package created: agent-service-lambda.zip"
echo "📊 Size: $(du -h agent-service-lambda.zip | cut -f1)"
