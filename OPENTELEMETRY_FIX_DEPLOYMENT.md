# OpenTelemetry 1.30.0 Fix Deployment Guide

## Overview

This guide walks through deploying the OpenTelemetry 1.30.0+ fix for the Agent Service Lambda function. The fix resolves the `StopIteration` error that occurs when importing the Strands Agents SDK on Python 3.11.

## What Was Fixed

**Problem:** Lambda crashes on startup with `StopIteration` error from OpenTelemetry's `_load_runtime_context()` function

**Root Cause:** OpenTelemetry < 1.30.0 is incompatible with Python 3.11's PEP 479 enforcement

**Solution:** Updated OpenTelemetry dependencies to >= 1.30.0

## Changes Made

### File: `agent-service/requirements.txt`

```diff
- # OpenTelemetry - Fix version compatibility for Python 3.11
- opentelemetry-api>=1.20.0,<2.0.0
- opentelemetry-sdk>=1.20.0,<2.0.0
+ # OpenTelemetry - Fixed for Python 3.11 compatibility (PEP 479)
+ opentelemetry-api>=1.30.0,<2.0.0
+ opentelemetry-sdk>=1.30.0,<2.0.0
+ opentelemetry-instrumentation-threading>=0.51b0,<1.0.0
```

## Deployment Steps

### Step 1: Commit Changes (On Your Local Machine or EC2)

```bash
cd ~/aws-serverless-microservices-ai
git add agent-service/requirements.txt
git commit -m "fix: Update OpenTelemetry to 1.30.0+ for Python 3.11 compatibility"
git push origin main  # or your branch name
```

### Step 2: Pull Changes on EC2 (If committed from local)

```bash
# SSH to EC2
ssh ubuntu@35.154.6.204

# Navigate to project
cd ~/aws-serverless-microservices-ai

# Pull latest changes
git pull origin main
```

### Step 3: Build Lambda Package with Updated Dependencies

```bash
cd ~/aws-serverless-microservices-ai/agent-service

# Clean previous build
rm -rf build agent-service-lambda.zip

# Create build directory
mkdir -p build

# Copy source code
cp -r src/agent_handler/* build/

# Install dependencies with updated OpenTelemetry 1.30.0+
pip3 install -r requirements.txt -t build/ --platform manylinux2014_x86_64 --only-binary=:all: --upgrade

# Verify OpenTelemetry version (optional)
python3 -c "import sys; sys.path.insert(0, 'build'); import opentelemetry.sdk; print(f'OpenTelemetry SDK version: {opentelemetry.sdk.__version__}')"

# Create deployment package
cd build
zip -r ../agent-service-lambda.zip . -x "*.pyc" "*__pycache__*" "*.dist-info/*"
cd ..

# Check package size
ls -lh agent-service-lambda.zip
```

**Expected Output:**
```
OpenTelemetry SDK version: 1.30.0 (or higher)
agent-service-lambda.zip: ~15-20 MB
```

### Step 4: Deploy with Terraform

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# Initialize Terraform (if needed)
terraform init

# Plan deployment (review changes)
terraform plan

# Apply deployment
terraform apply
```

**Terraform will:**
- Detect the new Lambda package (via source_code_hash)
- Update the Lambda function with OpenTelemetry 1.30.0+
- Trigger a new deployment

### Step 5: Verify the Fix

#### Test 1: Check Lambda Initialization

```bash
# Get API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)
echo "API Endpoint: $API_ENDPOINT"

# Send test request
curl -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, I need help finding a hotel in Paris",
    "userId": "test-user-fix",
    "sessionId": "test-session-fix"
  }'
```

**Expected Response:**
```json
{
  "response": "I'd be happy to help you find a hotel in Paris! ...",
  "userId": "test-user-fix",
  "sessionId": "test-session-fix",
  "tools_used": ["recommend_hotels"]
}
```

**NOT:**
```json
{"message": "Internal Server Error"}
```

#### Test 2: Check CloudWatch Logs

```bash
# View recent Lambda logs
aws logs tail /aws/lambda/agent-service-dev --follow --since 5m
```

**Expected:** No `StopIteration` errors, successful Lambda initialization

**Before Fix (Error):**
```
[ERROR] StopIteration
Traceback (most recent call last):
  File "/var/task/opentelemetry/context/__init__.py", line 60, in _load_runtime_context
    return next(...)
StopIteration
```

**After Fix (Success):**
```
[INFO] Lambda initialized successfully
[INFO] Strands Agent initialized with Bedrock model: anthropic.claude-3-sonnet-20240229-v1:0
[INFO] Processing user message: Hello, I need help finding a hotel in Paris
```

#### Test 3: Check X-Ray Traces

```bash
# Open AWS X-Ray Console
# https://console.aws.amazon.com/xray/home?region=us-east-1#/traces

# Look for traces from agent-service-dev
# Verify:
# - Lambda initialization succeeds
# - Bedrock API calls are made
# - No OpenTelemetry errors
```

## Troubleshooting

### Issue: "Lambda package not found"

**Solution:**
```bash
cd ~/aws-serverless-microservices-ai/agent-service
bash build-lambda.sh
```

### Issue: "pip3: command not found"

**Solution:**
```bash
# Install pip3
sudo apt update
sudo apt install python3-pip -y
```

### Issue: Lambda still returns "Internal Server Error"

**Solution:**
1. Check CloudWatch Logs for detailed error:
   ```bash
   aws logs tail /aws/lambda/agent-service-dev --follow
   ```

2. Verify OpenTelemetry version in deployed package:
   ```bash
   # Download Lambda package
   aws lambda get-function --function-name agent-service-dev --query 'Code.Location' --output text | xargs curl -o /tmp/lambda.zip
   
   # Extract and check
   unzip -q /tmp/lambda.zip -d /tmp/lambda
   python3 -c "import sys; sys.path.insert(0, '/tmp/lambda'); import opentelemetry.sdk; print(opentelemetry.sdk.__version__)"
   ```

3. Verify Bedrock model access is enabled in AWS Console

### Issue: "Bedrock model not accessible"

**Solution:**
1. Go to AWS Bedrock Console: https://console.aws.amazon.com/bedrock/
2. Navigate to "Model access" in the left sidebar
3. Click "Manage model access"
4. Enable "Claude 3 Sonnet"
5. Wait for status to change to "Access granted" (takes 1-2 minutes)

## Success Criteria

✅ Lambda initializes without `StopIteration` errors
✅ API returns HTTP 200 with valid agent responses
✅ CloudWatch Logs show successful Strands SDK initialization
✅ X-Ray traces show successful Lambda execution and Bedrock calls
✅ Agent can process user messages and invoke tools

## Rollback (If Needed)

If the fix causes issues, rollback to previous version:

```bash
cd ~/aws-serverless-microservices-ai

# Revert requirements.txt
git revert HEAD

# Rebuild and redeploy
cd agent-service
bash build-lambda.sh

cd ../terraform/agent-service/dev
terraform apply
```

## Next Steps

After successful deployment:

1. **Test Agent Capabilities:**
   - Hotel search and recommendations
   - Intelligent upselling
   - Conversation history
   - Multi-turn conversations

2. **Monitor Performance:**
   - CloudWatch metrics (duration, errors, throttles)
   - X-Ray traces (latency, Bedrock calls)
   - DynamoDB conversation storage

3. **Enable Bedrock Model Access** (if not already done):
   - Required for agent to generate responses
   - See "Troubleshooting" section above

4. **Integrate with Frontend:**
   - Update `frontend/src/pages/AIAssistant.jsx` to use the agent API
   - Test end-to-end user experience

## References

- **Spec Files:** `.kiro/specs/strands-agent-opentelemetry-fix/`
- **Requirements:** `bugfix.md`
- **Design:** `design.md`
- **Tasks:** `tasks.md`
- **OpenTelemetry 1.30.0 Release Notes:** https://github.com/open-telemetry/opentelemetry-python/releases/tag/v1.30.0
- **Python PEP 479:** https://peps.python.org/pep-0479/
- **AWS Strands Agents SDK:** https://github.com/strands-agents/sdk-python
