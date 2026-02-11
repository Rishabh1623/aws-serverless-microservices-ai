#!/bin/bash
# Build Lambda deployment package for Shopping Agent Service
# Uses Docker to ensure Python 3.11 compatibility with AWS Lambda

set -e

echo "🔨 Building Lambda deployment package for Shopping Agent..."

# Clean up previous builds
rm -f agent-service-lambda.zip

# Build Docker image with the package
docker build -t agent-lambda-builder:latest -f Dockerfile.lambda .

# Extract the zip file from the image
docker create --name temp-builder agent-lambda-builder:latest
docker cp temp-builder:/agent-service-lambda.zip ./agent-service-lambda.zip
docker rm temp-builder

# Show package size
echo ""
echo "✅ Lambda package built successfully!"
ls -lh agent-service-lambda.zip
echo ""
echo "📦 Package ready for deployment: agent-service-lambda.zip"
