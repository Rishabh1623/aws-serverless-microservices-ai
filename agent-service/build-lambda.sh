#!/bin/bash
# Build Lambda deployment package for Shopping Agent Service
# Uses Docker to ensure Python 3.11 compatibility with AWS Lambda

set -e

echo "🔨 Building Lambda deployment package for Shopping Agent..."

# Clean up previous builds
rm -f agent-service-lambda.zip

# Build Docker image
docker build -t agent-lambda-builder:latest -f Dockerfile.lambda . 2>&1 | grep -v "FROM scratch"

# Run container to create the zip, then copy it out
CONTAINER_ID=$(docker run -d agent-lambda-builder:latest tail -f /dev/null)
docker cp $CONTAINER_ID:/agent-service-lambda.zip ./agent-service-lambda.zip
docker stop $CONTAINER_ID > /dev/null
docker rm $CONTAINER_ID > /dev/null

# Show package size
echo ""
echo "✅ Lambda package built successfully!"
ls -lh agent-service-lambda.zip
echo ""
echo "📦 Package ready for deployment: agent-service-lambda.zip"
