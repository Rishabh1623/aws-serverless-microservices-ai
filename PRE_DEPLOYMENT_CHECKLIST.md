# Pre-Deployment Checklist - Agent Service IAM Fix

## ✅ Configuration Review Results

### 1. Terraform Configuration ✅ CORRECT

**File: `terraform/agent-service/dev/main.tf`**

✅ **IAM Policy** - Includes BOTH required ARNs:
```terraform
Resource = [
  "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
  "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
]
```

✅ **Lambda Runtime** - Python 3.10 (avoids OpenTelemetry bug)
```terraform
runtime = "python3.10"
```

✅ **Model ID Environment Variable** - Correct inference profile:
```terraform
BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
```

✅ **Secrets Manager** - Model ID updated:
```terraform
model_id = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
```

✅ **Backend Configuration** - S3 state backend configured:
```terraform
backend "s3" {
  bucket = "terraform-state-600105205879"
  key    = "agent-service/dev/terraform.tfstate"
  region = "us-east-1"
}
```

✅ **Provider Configuration** - AWS provider with default tags

✅ **CloudWatch Logs** - Log groups configured for Lambda and API Gateway

---

### 2. Application Code ✅ CORRECT

**File: `agent-service/src/agent_handler/app.py`**

✅ **Model ID Default** - All three locations use correct inference profile:
```python
'BEDROCK_MODEL_ID',
'us.anthropic.claude-haiku-4-5-20251001-v1:0'
```

✅ **Error Handling** - Graceful degradation with fallback URLs

✅ **Logging** - Proper logging configuration

---

### 3. Dependencies ✅ CORRECT

**File: `agent-service/requirements.txt`**

✅ **OpenTelemetry** - Updated to 1.30.0+ (Python 3.10 compatible):
```
opentelemetry-api>=1.30.0,<2.0.0
opentelemetry-sdk>=1.30.0,<2.0.0
opentelemetry-instrumentation-threading>=0.51b0,<1.0.0
```

✅ **Strands SDK** - Latest version:
```
strands-agents>=0.1.0
```

✅ **AWS SDK** - boto3 and botocore included

---

### 4. Build Script ✅ CORRECT

**File: `agent-service/build-lambda.sh`**

✅ **Dependency Installation Order** - Dependencies installed BEFORE copying source code (critical fix)

✅ **Platform Specification** - Uses `--platform manylinux2014_x86_64` for Lambda compatibility

✅ **Force Reinstall** - Uses `--force-reinstall --upgrade` to ensure clean build

---

## ⚠️ Required Actions Before Deployment

### Action 1: Build Lambda Package on EC2 ✅ REQUIRED

**Why**: Lambda package doesn't exist yet (needs to be built on EC2 with correct dependencies)

**Command**:
```bash
cd ~/aws-serverless-microservices-ai/agent-service
bash build-lambda.sh
```

**Expected Output**:
```
Building Agent Service Lambda package...
Installing dependencies...
Copying source code...
Creating deployment package...
✅ Lambda package created: agent-service-lambda.zip
Size: ~45M
```

**Verification**:
```bash
ls -lh agent-service-lambda.zip
# Should show file size around 40-50MB
```

---

### Action 2: Verify Git Changes Are Pulled ✅ REQUIRED

**Why**: Ensure EC2 has latest IAM policy changes

**Command**:
```bash
cd ~/aws-serverless-microservices-ai
git pull origin main
git log --oneline -3
```

**Expected Output**:
```
Already up to date.
33e5c23 Fix IAM policy to use inference-profile ARN
ce219cd Fix: Use US inference profile for Claude Haiku 4.5
```

---

## 🚀 Deployment Commands (Run on EC2)

### Complete Deployment Script

```bash
#!/bin/bash
# Agent Service IAM Fix Deployment
# Run this on EC2: ubuntu@35.154.6.204

set -e  # Exit on any error

echo "=========================================="
echo "Agent Service IAM Fix Deployment"
echo "=========================================="
echo ""

# Step 1: Navigate to project
echo "Step 1: Navigating to project directory..."
cd ~/aws-serverless-microservices-ai
pwd

# Step 2: Pull latest changes
echo ""
echo "Step 2: Pulling latest changes from git..."
git pull origin main
echo "✅ Git pull complete"

# Step 3: Verify changes
echo ""
echo "Step 3: Verifying recent commits..."
git log --oneline -3

# Step 4: Build Lambda package
echo ""
echo "Step 4: Building Lambda deployment package..."
cd agent-service
bash build-lambda.sh
echo "✅ Lambda package built"

# Step 5: Verify package exists
echo ""
echo "Step 5: Verifying Lambda package..."
ls -lh agent-service-lambda.zip
echo "✅ Package verified"

# Step 6: Navigate to Terraform directory
echo ""
echo "Step 6: Navigating to Terraform directory..."
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
pwd

# Step 7: Initialize Terraform
echo ""
echo "Step 7: Initializing Terraform..."
terraform init
echo "✅ Terraform initialized"

# Step 8: Review Terraform plan
echo ""
echo "Step 8: Reviewing Terraform plan..."
echo "=========================================="
terraform plan
echo "=========================================="
echo ""
read -p "Review the plan above. Continue with apply? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Deployment cancelled by user"
    exit 1
fi

# Step 9: Apply Terraform changes
echo ""
echo "Step 9: Applying Terraform changes..."
terraform apply -auto-approve
echo "✅ Terraform apply complete"

# Step 10: Wait for IAM propagation
echo ""
echo "Step 10: Waiting for IAM propagation (10 seconds)..."
sleep 10
echo "✅ IAM propagation complete"

# Step 11: Test the endpoint
echo ""
echo "Step 11: Testing agent endpoint..."
echo "=========================================="
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}' \
  | jq '.'
echo ""
echo "=========================================="

# Step 12: Check Lambda logs
echo ""
echo "Step 12: Checking Lambda logs (last 2 minutes)..."
echo "=========================================="
aws logs tail /aws/lambda/agent-service-dev --since 2m
echo "=========================================="

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Verify the API response above shows agent response (not error)"
echo "2. Check logs above for any errors"
echo "3. If successful, test with complex queries"
echo "4. Update frontend configuration"
echo ""
```

---

## 📋 Manual Step-by-Step Commands

If you prefer to run commands manually (recommended for first deployment):

```bash
# 1. SSH to EC2
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204

# 2. Navigate to project
cd ~/aws-serverless-microservices-ai

# 3. Pull latest changes
git pull origin main

# 4. Verify commits
git log --oneline -3

# 5. Build Lambda package
cd agent-service
bash build-lambda.sh

# 6. Verify package
ls -lh agent-service-lambda.zip

# 7. Navigate to Terraform
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# 8. Initialize Terraform
terraform init

# 9. Review plan (IMPORTANT - review before applying)
terraform plan

# 10. Apply changes
terraform apply

# 11. Wait for IAM propagation
sleep 10

# 12. Test endpoint
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'

# 13. Check logs
aws logs tail /aws/lambda/agent-service-dev --since 2m
```

---

## 🔍 What Terraform Will Change

When you run `terraform plan`, you should see:

### Expected Changes:

1. **IAM Policy Update** (1 resource changed):
   ```
   # aws_iam_role_policy.bedrock_access will be updated in-place
   ~ resource "aws_iam_role_policy" "bedrock_access" {
       ~ policy = jsonencode(
           ~ {
               ~ Statement = [
                   ~ {
                       ~ Resource = [
                           + "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
                           + "arn:aws:bedrock:us-east-1:600105205879:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0",
                         ]
                     }
                 ]
             }
         )
     }
   ```

2. **Lambda Function Update** (if package hash changed):
   ```
   # aws_lambda_function.agent_package will be updated in-place
   ~ resource "aws_lambda_function" "agent_package" {
       ~ source_code_hash = "old_hash" -> "new_hash"
     }
   ```

### What Should NOT Change:

- ❌ No resources should be destroyed
- ❌ No new resources should be created (unless first deployment)
- ❌ DynamoDB table should not change
- ❌ API Gateway should not change
- ❌ CloudWatch log groups should not change

---

## ✅ Success Criteria

### Terraform Apply Success:
```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:
api_endpoint = "https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent"
lambda_function_name = "agent-service-dev"
```

### API Test Success:
```json
{
  "response": "Hello! I'd be happy to help you find a hotel in Paris...",
  "toolsUsed": [],
  "userId": "test",
  "sessionId": "test",
  "userContext": {
    "conversationLength": 1,
    "preferences": {}
  }
}
```

### Lambda Logs Success:
```
[INFO] Processing message from user test: Hello! Can you help me find a hotel in Paris?
[INFO] Found credentials in environment variables.
[INFO] Creating Strands MetricsClient
[INFO] Tools used: []
```

---

## ❌ Failure Scenarios & Solutions

### Scenario 1: Lambda Package Not Found

**Error**:
```
Error: Lambda package not found. Run: cd agent-service && bash build-lambda.sh
```

**Solution**:
```bash
cd ~/aws-serverless-microservices-ai/agent-service
bash build-lambda.sh
```

---

### Scenario 2: Terraform State Lock

**Error**:
```
Error: Error acquiring the state lock
```

**Solution**:
```bash
# Check if another terraform process is running
ps aux | grep terraform

# If no process found, force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

---

### Scenario 3: Still Getting AccessDeniedException

**Error in logs**:
```
AccessDeniedException: User is not authorized to perform: bedrock:InvokeModelWithResponseStream
```

**Solution**:
```bash
# 1. Verify IAM policy was applied
aws iam get-role-policy \
  --role-name agent-service-dev-lambda-role \
  --policy-name agent-service-dev-bedrock-policy

# 2. Wait longer for IAM propagation
sleep 30

# 3. Test again
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"test","userId":"test","sessionId":"test"}'
```

---

### Scenario 4: Model Not Found

**Error**:
```
ValidationException: The provided model identifier is invalid
```

**Solution**:
```bash
# Verify model is available in your region
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude-haiku-4-5`)]'

# Check inference profiles
aws bedrock list-inference-profiles \
  --region us-east-1 \
  --query 'inferenceProfileSummaries[?contains(inferenceProfileId, `claude-haiku-4-5`)]'
```

---

## 📊 Monitoring After Deployment

### CloudWatch Metrics to Watch:

```bash
# Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=agent-service-dev \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Lambda errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=agent-service-dev \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Lambda duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=agent-service-dev \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average,Maximum
```

---

## 🎯 Summary

### What's Being Fixed:
- ✅ IAM policy updated to include inference-profile ARN
- ✅ Model ID updated to Claude Haiku 4.5
- ✅ Lambda runtime set to Python 3.10
- ✅ OpenTelemetry updated to 1.30.0+

### What You Need to Do:
1. ✅ SSH to EC2 (35.154.6.204)
2. ✅ Pull latest git changes
3. ✅ Build Lambda package
4. ✅ Run terraform init
5. ✅ Review terraform plan
6. ✅ Run terraform apply
7. ✅ Test the endpoint
8. ✅ Verify logs

### Estimated Time:
- Build Lambda package: 2-3 minutes
- Terraform apply: 1-2 minutes
- Total: ~5 minutes

---

**Ready to deploy? Run the manual commands on your EC2 instance!**
