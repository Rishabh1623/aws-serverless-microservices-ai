# Quick Deploy: Agent Service OpenTelemetry Fix

## 🚀 Quick Start (Copy & Paste on EC2)

```bash
# SSH to EC2
ssh ubuntu@35.154.6.204

# Navigate to project and pull changes
cd ~/aws-serverless-microservices-ai
git pull origin main

# Build Lambda package with OpenTelemetry 1.30.0+
cd agent-service
rm -rf build agent-service-lambda.zip
mkdir -p build
cp -r src/agent_handler/* build/
pip3 install -r requirements.txt -t build/ --platform manylinux2014_x86_64 --only-binary=:all: --upgrade
cd build && zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*" && cd ..

# Deploy with Terraform
cd ../terraform/agent-service/dev
terraform apply -auto-approve

# Test the fix
API_ENDPOINT=$(terraform output -raw api_endpoint)
curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, I need a hotel in Paris","userId":"test","sessionId":"test"}'
```

## ✅ Success Indicators

**Before Fix:**
```json
{"message": "Internal Server Error"}
```

**After Fix:**
```json
{
  "response": "I'd be happy to help you find a hotel in Paris! ...",
  "userId": "test",
  "sessionId": "test"
}
```

## 📋 What Changed

- `opentelemetry-api`: 1.20.0 → 1.30.0+
- `opentelemetry-sdk`: 1.20.0 → 1.30.0+
- Added: `opentelemetry-instrumentation-threading>=0.51b0`

## 🔍 Verify Deployment

```bash
# Check CloudWatch Logs
aws logs tail /aws/lambda/agent-service-dev --follow --since 5m

# Expected: No StopIteration errors
# Expected: "Lambda initialized successfully"
```

## 📚 Full Documentation

- **Deployment Guide:** `OPENTELEMETRY_FIX_DEPLOYMENT.md`
- **Summary:** `OPENTELEMETRY_FIX_SUMMARY.md`
- **Spec:** `.kiro/specs/strands-agent-opentelemetry-fix/`

## 🆘 Troubleshooting

**Issue:** pip3 not found
```bash
sudo apt update && sudo apt install python3-pip -y
```

**Issue:** Still getting errors
```bash
# Check logs
aws logs tail /aws/lambda/agent-service-dev --follow

# Verify Bedrock access
# Go to: https://console.aws.amazon.com/bedrock/
# Enable "Claude 3 Sonnet" model access
```

---

**Time to deploy:** ~5 minutes
**Downtime:** None (rolling deployment)
