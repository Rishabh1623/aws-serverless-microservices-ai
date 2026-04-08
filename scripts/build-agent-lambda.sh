#!/bin/bash
# Build Agent Service Lambda package with all dependencies

set -e

echo "=========================================="
echo "Building Agent Service Lambda Package"
echo "=========================================="

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENT_DIR="$PROJECT_ROOT/agent-service"
BUILD_DIR="$AGENT_DIR/build"
PACKAGE_DIR="$BUILD_DIR/package"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Install dependencies
echo "Installing Python dependencies..."
pip install -r "$AGENT_DIR/requirements.txt" -t "$PACKAGE_DIR" --platform manylinux2014_x86_64 --only-binary=:all: --python-version 3.11

# Copy source code
echo "Copying source code..."
cp -r "$AGENT_DIR/src/agent_handler"/* "$PACKAGE_DIR/"

# Create deployment package
echo "Creating deployment package..."
cd "$PACKAGE_DIR"
zip -r "$BUILD_DIR/agent-service-lambda.zip" . -x "*.pyc" "*__pycache__*" "*.dist-info/*" "tests/*"

# Show package info
PACKAGE_SIZE=$(du -h "$BUILD_DIR/agent-service-lambda.zip" | cut -f1)
echo ""
echo "=========================================="
echo "✅ Lambda package created successfully!"
echo "=========================================="
echo "Location: $BUILD_DIR/agent-service-lambda.zip"
echo "Size: $PACKAGE_SIZE"
echo ""
echo "Next steps:"
echo "1. Update Terraform to use this package"
echo "2. Run: cd terraform/agent-service/dev && terraform apply"
