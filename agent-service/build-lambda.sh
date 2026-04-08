#!/bin/bash
# Build Lambda deployment package with dependencies

set -e

echo "Building Agent Service Lambda package..."

# Create build directory
BUILD_DIR="$(pwd)/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source code
echo "Copying source code..."
cp -r src/agent_handler/* "$BUILD_DIR/"

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt -t "$BUILD_DIR/" --platform manylinux2014_x86_64 --only-binary=:all:

# Create zip file
echo "Creating deployment package..."
cd "$BUILD_DIR"
zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*"

echo "✅ Lambda package created: agent-service-lambda.zip"
echo "Size: $(du -h ../agent-service-lambda.zip | cut -f1)"
