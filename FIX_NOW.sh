#!/bin/bash
# Quick fix script - run this on EC2

set -e

cd ~/aws-serverless-microservices-ai/agent-service

echo "=== Cleaning up ==="
rm -rf build agent-service-lambda.zip

echo "=== Creating build directory ==="
mkdir -p build

echo "=== Installing dependencies FIRST ==="
pip3 install --force-reinstall --upgrade -r requirements.txt -t build/ --platform manylinux2014_x86_64 --only-binary=:all:

echo "=== Copying source code AFTER ==="
cp -r src/agent_handler/* build/

echo "=== Verifying OpenTelemetry version ==="
cat build/opentelemetry_sdk-*.dist-info/METADATA | grep "^Version:"

echo "=== Creating zip ==="
cd build && zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*" && cd ..

echo "=== Deploying to Lambda ==="
aws lambda update-function-code --function-name agent-service-dev --zip-file fileb://agent-service-lambda.zip

echo "=== Waiting 20 seconds for deployment ==="
sleep 20

echo "=== Testing ==="
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
curl -X POST $(terraform output -raw api_endpoint) -H "Content-Type: application/json" -d '{"message":"test","userId":"test","sessionId":"test"}'

echo ""
echo "=== Check logs ==="
aws logs tail /aws/lambda/agent-service-dev --since 1m
