# Agent Service IAM Fix - Deployment Guide

## 🎯 Objective
Deploy IAM policy updates to grant Lambda permission to invoke Claude Haiku 4.5 model via Bedrock.

## 📋 Current Status

### ✅ Completed
- OpenTelemetry issue resolved (Python 3.10 runtime)
- Model ID updated to Claude Haiku 4.5 inference profile
- IAM policy updated in Terraform code
- All changes committed to git

### ❌ Pending
- Deploy IAM policy to AWS (Terraform apply)
- Verify agent endpoint works

## 🔧 What Needs to Be Fixed

**Error**: `AccessDeniedException` - Lambda role lacks permission to invoke Bedrock model

**Root Cause**: IAM policy doesn't include permissions for the new Claude Haiku 4.5 inference profile

**Solution**: Deploy updated IAM policy that grants `bedrock:InvokeModelWithResponseStream` permission

---

## 📝 Step-by-Step Deployment (Best Practices)

### Step 1: Connect to EC2 Instance

```bash
# SSH to your EC2 deployment server
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204
```

**Why**: All Terraform deployments are managed from this EC2 instance

---

### Step 2: Navigate to Project Directory

```bash
cd ~/aws-serverless-microservices-ai
```

**Why**: This is the root of your project where git repository is located

---

### Step 3: Pull Latest Changes from Git

```bash
# Check current branch
git branch

# Pull latest changes
git pull origin main

# Verify the changes were pulled
git log --oneline -5
```

**Expected Output**: You should see recent commits related to IAM policy updates

**Why**: Ensures you have the latest Terraform configuration with IAM fixes

**Best Practice**: Always verify you're on the correct branch and changes are pulled successfully

---

### Step 4: Navigate to Agent Service Terraform Directory

```bash
cd terraform/agent-service/dev
```

**Why**: This directory contains the Terraform configuration for the dev environment

---

### Step 5: Review Terraform Plan (Best Practice)

```bash
# Initialize Terraform (ensures providers and modules are up to date)
terraform init

# Review what will change
terraform plan
```

**Expected Output**: You should see changes to:
- `aws_iam_role_policy.bedrock_access` - IAM policy update with new ARNs
- Possibly `aws_lambda_function.agent_package` - if source code hash changed

**Why**: 
- `terraform plan` shows exactly what will change BEFORE applying
- Prevents unexpected infrastructure changes
- Best practice: ALWAYS review plan before apply

**What to Look For**:
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

---

### Step 6: Apply Terraform Changes

```bash
# Apply changes with auto-approve (since we reviewed the plan)
terraform apply -auto-approve
```

**Expected Output**:
```
aws_iam_role_policy.bedrock_access: Modifying... [id=agent-service-dev-lambda-role:agent-service-dev-bedrock-policy]
aws_iam_role_policy.bedrock_access: Modifications complete after 2s

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

**Why**: 
- Updates the IAM policy attached to Lambda role
- Grants permission to invoke Claude Haiku 4.5 model
- `-auto-approve` skips confirmation (safe since we reviewed plan)

**Best Practice**: In production, remove `-auto-approve` and manually confirm changes

---

### Step 7: Wait for IAM Propagation

```bash
# Wait 10 seconds for IAM changes to propagate
sleep 10
```

**Why**: IAM policy changes can take a few seconds to propagate across AWS services

**Best Practice**: Always wait after IAM changes before testing

---

### Step 8: Test the Agent Endpoint

```bash
# Test with a simple hotel search query
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'
```

**Expected Output** (Success):
```json
{
  "response": "Hello! I'd be happy to help you find a hotel in Paris. To provide the best recommendations, could you tell me:\n\n1. What dates are you planning to visit?\n2. What's your budget range?\n3. What's the purpose of your trip (business, leisure, romantic)?\n4. Any specific preferences (location, amenities, etc.)?\n\nThis will help me find the perfect hotel for your Paris stay!",
  "toolsUsed": [],
  "userId": "test",
  "sessionId": "test",
  "userContext": {
    "conversationLength": 1,
    "preferences": {}
  }
}
```

**Expected Output** (Still Failing):
```json
{
  "error": "agent_error",
  "message": "I'm having trouble right now. Please try using the traditional hotel search.",
  "fallback_urls": {...}
}
```

**Why**: Verifies the agent can successfully invoke Bedrock model

---

### Step 9: Check Lambda Logs for Detailed Status

```bash
# View last 2 minutes of Lambda logs
aws logs tail /aws/lambda/agent-service-dev --since 2m --follow
```

**Expected Output** (Success):
```
[INFO] Processing message from user test: Hello! Can you help me find a hotel in Paris?
[INFO] Found credentials in environment variables.
[INFO] Creating Strands MetricsClient
[INFO] Tools used: []
```

**Expected Output** (Still Failing):
```
[ERROR] Error processing request: An error occurred (AccessDeniedException) when calling the ConverseStream operation...
```

**Why**: 
- Shows detailed error messages if something is still wrong
- Confirms successful Bedrock API calls
- Best practice for debugging Lambda issues

**Press Ctrl+C to exit log streaming**

---

### Step 10: Verify IAM Policy Was Applied (Optional)

```bash
# Get the Lambda role name
ROLE_NAME="agent-service-dev-lambda-role"

# List inline policies attached to the role
aws iam list-role-policies --role-name $ROLE_NAME

# Get the specific policy document
aws iam get-role-policy --role-name $ROLE_NAME --policy-name agent-service-dev-bedrock-policy
```

**Expected Output**: Should show policy with both ARNs:
```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
        "arn:aws:bedrock:us-east-1:600105205879:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
      ]
    }
  ]
}
```

**Why**: Confirms IAM policy was correctly applied with both ARNs

---

## 🎯 Success Criteria

✅ **Deployment Successful** if:
1. `terraform apply` completes without errors
2. API endpoint returns HTTP 200 with agent response
3. Lambda logs show "Processing message" and "Tools used"
4. No AccessDeniedException errors in logs

❌ **Deployment Failed** if:
1. `terraform apply` shows errors
2. API endpoint returns error message
3. Lambda logs show AccessDeniedException
4. IAM policy doesn't include both ARNs

---

## 🔍 Troubleshooting

### Issue 1: Terraform Apply Fails

**Symptoms**: Error during `terraform apply`

**Solutions**:
```bash
# Re-initialize Terraform
terraform init -upgrade

# Try apply again
terraform apply
```

### Issue 2: Still Getting AccessDeniedException

**Symptoms**: Lambda logs show AccessDeniedException after deployment

**Solutions**:
1. Verify IAM policy was applied (Step 10)
2. Check if model ID in code matches IAM policy ARN
3. Wait longer for IAM propagation (try `sleep 30`)
4. Check if Lambda role has the policy attached:
   ```bash
   aws iam list-attached-role-policies --role-name agent-service-dev-lambda-role
   aws iam list-role-policies --role-name agent-service-dev-lambda-role
   ```

### Issue 3: Model Not Found Error

**Symptoms**: Error about model not being available

**Solutions**:
1. Verify model ID is correct: `us.anthropic.claude-haiku-4-5-20251001-v1:0`
2. Check Bedrock console to confirm model is available in us-east-1
3. Try invoking model directly from Bedrock console

### Issue 4: Lambda Timeout

**Symptoms**: Lambda times out before responding

**Solutions**:
1. Check Lambda timeout setting (currently 60 seconds)
2. Review Lambda logs for slow operations
3. Consider increasing timeout if needed

---

## 📊 What Changed in This Deployment

### IAM Policy Update

**Before**:
```json
{
  "Resource": [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
  ]
}
```

**After**:
```json
{
  "Resource": [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
    "arn:aws:bedrock:us-east-1:600105205879:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
  ]
}
```

**Why Both ARNs**:
- Foundation model ARN: Base model permission
- Inference profile ARN: Required for Claude 4+ models (new AWS requirement)

### Model ID Update

**Before**: `anthropic.claude-3-haiku-20240307-v1:0` (Claude 3 Haiku - Legacy)

**After**: `us.anthropic.claude-haiku-4-5-20251001-v1:0` (Claude Haiku 4.5 - Latest)

**Why**: Claude 3 models are marked as "Legacy" by AWS, Claude 4.5 is the current version

---

## 🚀 Next Steps After Successful Deployment

1. **Test with Complex Queries**:
   ```bash
   curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
     -H "Content-Type: application/json" \
     -d '{"message":"I need a luxury hotel in Paris for 3 nights starting May 15th, budget $500/night","userId":"test","sessionId":"test"}'
   ```

2. **Integrate with Frontend**:
   - Update frontend `.env` file with agent endpoint
   - Test AI Assistant page in frontend
   - Verify conversation history works

3. **Monitor Performance**:
   ```bash
   # Watch CloudWatch metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Duration \
     --dimensions Name=FunctionName,Value=agent-service-dev \
     --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 60 \
     --statistics Average,Maximum
   ```

4. **Deploy to Production** (when ready):
   ```bash
   cd ~/aws-serverless-microservices-ai/terraform/agent-service/prod
   terraform plan
   terraform apply
   ```

---

## 📚 Additional Resources

- **AWS Bedrock Inference Profiles**: https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles.html
- **IAM Policy Best Practices**: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- **Lambda Troubleshooting**: https://docs.aws.amazon.com/lambda/latest/dg/lambda-troubleshooting.html
- **Strands Agents SDK**: https://github.com/awslabs/strands

---

## 🔐 Security Notes

- IAM policy follows least-privilege principle (only Bedrock invoke permissions)
- Model ARNs are specific to Claude Haiku 4.5 (no wildcard permissions)
- Lambda role has no unnecessary permissions
- API Gateway has CORS configured (restrict in production)
- Secrets stored in AWS Secrets Manager (not environment variables)

---

## 💰 Cost Considerations

- **Bedrock Claude Haiku 4.5**: ~$0.25 per 1M input tokens, ~$1.25 per 1M output tokens
- **Lambda**: 512MB memory, ~$0.0000083 per second
- **API Gateway**: ~$1.00 per million requests
- **DynamoDB**: Pay-per-request pricing
- **CloudWatch Logs**: 7-day retention (minimal cost)

**Estimated Cost**: ~$5-20/month for moderate usage (100-1000 requests/day)

---

## ✅ Deployment Checklist

- [ ] SSH to EC2 instance (35.154.6.204)
- [ ] Navigate to project directory
- [ ] Pull latest changes from git
- [ ] Navigate to terraform/agent-service/dev
- [ ] Run `terraform init`
- [ ] Run `terraform plan` and review changes
- [ ] Run `terraform apply -auto-approve`
- [ ] Wait 10 seconds for IAM propagation
- [ ] Test agent endpoint with curl
- [ ] Check Lambda logs for success/errors
- [ ] Verify IAM policy was applied (optional)
- [ ] Test with complex queries
- [ ] Update frontend configuration
- [ ] Monitor CloudWatch metrics

---

**Last Updated**: 2026-05-03
**Status**: Ready for deployment
**Estimated Time**: 5-10 minutes
