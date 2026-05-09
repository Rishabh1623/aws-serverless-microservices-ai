# Claude 3 Haiku Model Configuration Fix

## Problem Summary

The Lambda function is failing with `AccessDeniedException` because it's trying to use **Claude Sonnet 4** (`us.anthropic.claude-sonnet-4-20250514-v1:0`), which requires an AWS Marketplace subscription that is not available in the account.

### Error from CloudWatch Logs:
```
Model access is denied due to IAM user or service role is not authorized to perform 
the required AWS Marketplace actions (aws-marketplace:ViewSubscriptions, 
aws-marketplace:Subscribe) to enable access to this model.
└ Model id: us.anthropic.claude-sonnet-4-20250514-v1:0
```

## Root Cause

The Lambda **code** was already updated to use Claude 3 Haiku (Build #6), but the **Terraform environment variable** `BEDROCK_MODEL_ID` was still set to Claude Sonnet 4. Environment variables override code defaults, so the Lambda was still trying to use Sonnet 4.

### Files Involved:
- ✅ `agent-service/src/agent_handler/app.py` - Already uses Claude 3 Haiku as default
- ❌ `terraform/agent-service/dev/main.tf` - Line 106 had wrong model ID

## Solution Implemented

### 1. Updated Terraform Configuration

**File:** `terraform/agent-service/dev/main.tf`

**Changed Line 106:**
```terraform
# BEFORE:
BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0"  # Claude Sonnet 4

# AFTER:
BEDROCK_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"  # Claude 3 Haiku (fast & enabled)
```

### 2. Updated IAM Policy

**File:** `terraform/agent-service/dev/main.tf`

Reordered IAM permissions to prioritize Claude 3 Haiku:
```terraform
Resource = [
  # Primary: Claude 3 Haiku (already enabled)
  "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-*",
  "arn:aws:bedrock:*:${account_id}:inference-profile/anthropic.claude-3-haiku-*",
  
  # Fallback: Other Claude Haiku models
  "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-*",
  
  # Future: Claude Sonnet 4 (if marketplace subscription added)
  "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-*",
]
```

## Deployment Steps

### On Your Local Machine:

1. **Commit and push the changes:**
   ```bash
   git add terraform/agent-service/dev/main.tf
   git commit -m "fix: Update Lambda to use Claude 3 Haiku instead of Sonnet 4"
   git push origin main
   ```

### On EC2 Instance (IP: 172.31.84.67):

2. **Pull the latest changes:**
   ```bash
   cd ~/aws-serverless-microservices-ai
   git pull origin main
   ```

3. **Navigate to Terraform directory:**
   ```bash
   cd terraform/agent-service/dev
   ```

4. **Apply Terraform changes:**
   ```bash
   terraform plan
   terraform apply -auto-approve
   ```

   This will update the Lambda environment variable without redeploying the code.

## Verification

### 1. Check Lambda Environment Variable:
```bash
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables.BEDROCK_MODEL_ID'
```

**Expected Output:**
```
"anthropic.claude-3-haiku-20240307-v1:0"
```

### 2. Test Lambda Function:
```bash
aws lambda invoke \
  --function-name agent-service-dev \
  --payload '{"body":"{\"message\":\"Hello, can you help me find a hotel?\",\"userId\":\"test-user\"}"}' \
  response.json

cat response.json
```

**Expected Result:**
- `statusCode: 200`
- No `AccessDeniedException` errors
- Agent responds successfully

### 3. Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/agent-service-dev --follow
```

**Expected Log Entries:**
```
[INFO] Using AWS Bedrock with model: anthropic.claude-3-haiku-20240307-v1:0
[INFO] Creating Strands MetricsClient
[INFO] Processing message from user test-user: Hello, can you help me find a hotel?
```

**No errors about:**
- ❌ `AccessDeniedException`
- ❌ `aws-marketplace:ViewSubscriptions`
- ❌ `Model access is denied`

## Why Claude 3 Haiku?

| Feature | Claude Sonnet 4 | Claude 3 Haiku |
|---------|----------------|----------------|
| **Availability** | ❌ Requires AWS Marketplace subscription | ✅ Already enabled in account |
| **Speed** | Slower | ⚡ Fast (optimized for low latency) |
| **Cost** | Higher | 💰 Lower cost |
| **Use Case** | Complex reasoning | Quick responses, high throughput |
| **Status** | Not accessible | ✅ Ready to use |

For a travel booking assistant, **Claude 3 Haiku is ideal** because:
- Fast response times for better UX
- Cost-effective for high-volume requests
- Sufficient intelligence for hotel recommendations and booking
- Already enabled - no marketplace subscription needed

## Technical Details

### Model ID Format:
- **Foundation Model:** `anthropic.claude-3-haiku-20240307-v1:0`
- **Cross-Region Inference Profile:** `us.anthropic.claude-haiku-4-5-20251001-v1:0`

### How Strands SDK Uses Bedrock:
```python
# Strands Agent defaults to AWS Bedrock when no client is specified
agent = Agent(
    system_prompt=SYSTEM_PROMPT,
    tools=get_tools(),
    model="anthropic.claude-3-haiku-20240307-v1:0"  # Uses boto3 IAM credentials
)
```

### IAM Authentication:
- No API keys needed
- Uses Lambda execution role credentials
- Permissions granted via IAM policy in Terraform

## Timeline

1. ✅ **Build #6** - Updated code to use Claude 3 Haiku
2. ✅ **CodeBuild** - Successfully built Lambda package with correct dependencies
3. ❌ **Runtime Error** - Lambda still tried to use Sonnet 4 (env var override)
4. ✅ **This Fix** - Updated Terraform env var to match code default
5. 🎯 **Next** - Deploy and verify Lambda works with Claude 3 Haiku

## Related Files

- `agent-service/src/agent_handler/app.py` - Lambda handler with Bedrock integration
- `agent-service/buildspec.yml` - CodeBuild specification (working correctly)
- `terraform/cicd/agent-build/main.tf` - CodeBuild infrastructure (deployed)
- `terraform/agent-service/dev/main.tf` - Lambda infrastructure (just updated)

## Interview Talking Points

This fix demonstrates:
1. **Environment Configuration Management** - Understanding how env vars override code defaults
2. **AWS Bedrock Model Selection** - Choosing appropriate models based on availability and use case
3. **IAM Policy Design** - Structuring permissions for multiple model options
4. **Debugging Production Issues** - Reading CloudWatch logs to identify root cause
5. **Infrastructure as Code** - Using Terraform to manage Lambda configuration

The key insight: **Always verify that infrastructure configuration (Terraform) matches application code expectations**, especially for external service integrations like Bedrock models.
