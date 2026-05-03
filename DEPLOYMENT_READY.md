# 🚀 Agent Service - Ready for Deployment

## ✅ Configuration Verified - All Files Correct

I've reviewed all critical files and **everything is configured correctly**. You're ready to deploy!

---

## 📋 What Was Verified

### ✅ Terraform Configuration (`terraform/agent-service/dev/main.tf`)
- IAM policy includes BOTH required ARNs (foundation-model + inference-profile)
- Lambda runtime set to Python 3.10
- Model ID environment variable correct: `us.anthropic.claude-haiku-4-5-20251001-v1:0`
- Secrets Manager configuration updated
- Backend S3 state configured
- CloudWatch logs configured

### ✅ Application Code (`agent-service/src/agent_handler/app.py`)
- All three model ID defaults use correct inference profile
- Error handling with graceful degradation
- Proper logging configuration

### ✅ Dependencies (`agent-service/requirements.txt`)
- OpenTelemetry updated to 1.30.0+ (Python 3.10 compatible)
- Strands SDK included
- All required dependencies present

### ✅ Build Script (`agent-service/build-lambda.sh`)
- Dependencies installed BEFORE copying source code (critical fix)
- Platform specification for Lambda compatibility
- Force reinstall for clean build

### ✅ Git Status
- Latest changes already pushed to GitHub
- EC2 can pull latest code with `git pull origin main`

---

## 🎯 What You Need to Do

### Option 1: Automated Deployment (Recommended)

I've created a deployment script that handles everything:

```bash
# 1. SSH to EC2
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204

# 2. Navigate to project
cd ~/aws-serverless-microservices-ai

# 3. Pull latest changes (includes the deployment script)
git pull origin main

# 4. Make script executable
chmod +x deploy-agent-iam-fix.sh

# 5. Run the deployment script
./deploy-agent-iam-fix.sh
```

The script will:
- ✅ Pull latest code
- ✅ Build Lambda package
- ✅ Initialize Terraform
- ✅ Show you the plan (you can review before applying)
- ✅ Apply changes
- ✅ Test the endpoint
- ✅ Show Lambda logs
- ✅ Provide summary and next steps

---

### Option 2: Manual Step-by-Step (If You Prefer Control)

```bash
# 1. SSH to EC2
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204

# 2. Navigate to project
cd ~/aws-serverless-microservices-ai

# 3. Pull latest changes
git pull origin main

# 4. Build Lambda package
cd agent-service
bash build-lambda.sh

# 5. Verify package was created
ls -lh agent-service-lambda.zip

# 6. Navigate to Terraform directory
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# 7. Initialize Terraform
terraform init

# 8. Review what will change (IMPORTANT)
terraform plan

# 9. Apply changes (review plan first!)
terraform apply

# 10. Wait for IAM propagation
sleep 10

# 11. Test the endpoint
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'

# 12. Check logs
aws logs tail /aws/lambda/agent-service-dev --since 2m
```

---

## 📊 What Terraform Will Change

When you run `terraform plan`, you'll see:

### Expected Changes:

**1. IAM Policy Update** (Main fix):
```
# aws_iam_role_policy.bedrock_access will be updated in-place
~ resource "aws_iam_role_policy" "bedrock_access" {
    ~ policy = jsonencode({
        ~ Statement = [
            ~ {
                ~ Resource = [
                    + "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
                    + "arn:aws:bedrock:us-east-1:600105205879:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0",
                  ]
              }
          ]
      })
  }
```

**2. Lambda Function Update** (If package changed):
```
# aws_lambda_function.agent_package will be updated in-place
~ resource "aws_lambda_function" "agent_package" {
    ~ source_code_hash = "old_hash" -> "new_hash"
  }
```

### Summary:
- **Resources to add**: 0
- **Resources to change**: 1-2 (IAM policy + possibly Lambda)
- **Resources to destroy**: 0

---

## ✅ Success Indicators

### 1. Terraform Apply Success:
```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:
api_endpoint = "https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent"
lambda_function_name = "agent-service-dev"
```

### 2. API Test Success:
```json
{
  "response": "Hello! I'd be happy to help you find a hotel in Paris. To provide the best recommendations, could you tell me:\n\n1. What dates are you planning to visit?\n2. What's your budget range?\n3. What's the purpose of your trip?",
  "toolsUsed": [],
  "userId": "test",
  "sessionId": "test",
  "userContext": {
    "conversationLength": 1,
    "preferences": {}
  }
}
```

### 3. Lambda Logs Success:
```
[INFO] Processing message from user test: Hello! Can you help me find a hotel in Paris?
[INFO] Found credentials in environment variables.
[INFO] Creating Strands MetricsClient
[INFO] Tools used: []
```

**No AccessDeniedException errors!**

---

## ❌ If Something Goes Wrong

### Issue: Lambda Package Build Fails

**Solution**:
```bash
cd ~/aws-serverless-microservices-ai/agent-service
rm -rf build/
bash build-lambda.sh
```

### Issue: Terraform State Lock

**Solution**:
```bash
# Check for running terraform processes
ps aux | grep terraform

# If none found, force unlock
terraform force-unlock <LOCK_ID>
```

### Issue: Still Getting AccessDeniedException

**Solution**:
```bash
# Verify IAM policy was applied
aws iam get-role-policy \
  --role-name agent-service-dev-lambda-role \
  --policy-name agent-service-dev-bedrock-policy

# Wait longer for IAM propagation
sleep 30

# Test again
```

---

## 📚 Documentation Created

I've created three comprehensive documents for you:

1. **`PRE_DEPLOYMENT_CHECKLIST.md`** - Detailed verification of all configurations
2. **`deploy-agent-iam-fix.sh`** - Automated deployment script
3. **`DEPLOYMENT_READY.md`** (this file) - Quick start guide

---

## 🎯 Quick Start (Copy-Paste)

**For automated deployment:**
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204
cd ~/aws-serverless-microservices-ai
git pull origin main
chmod +x deploy-agent-iam-fix.sh
./deploy-agent-iam-fix.sh
```

**For manual deployment:**
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204
cd ~/aws-serverless-microservices-ai
git pull origin main
cd agent-service && bash build-lambda.sh
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform init
terraform plan
terraform apply
sleep 10
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello!","userId":"test","sessionId":"test"}'
aws logs tail /aws/lambda/agent-service-dev --since 2m
```

---

## ⏱️ Estimated Time

- Build Lambda package: 2-3 minutes
- Terraform init: 30 seconds
- Terraform plan: 30 seconds
- Terraform apply: 1-2 minutes
- Testing: 1 minute

**Total: ~5-7 minutes**

---

## 🎉 After Successful Deployment

1. **Test with complex queries**:
   ```bash
   curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
     -H "Content-Type: application/json" \
     -d '{"message":"I need a luxury hotel in Paris for 3 nights starting May 15th, budget $500/night","userId":"test","sessionId":"test"}'
   ```

2. **Update frontend** (if needed):
   - Update `.env` file with agent endpoint
   - Test AI Assistant page

3. **Monitor CloudWatch**:
   - Check Lambda metrics (invocations, errors, duration)
   - Review CloudWatch logs for any issues

4. **Deploy to production** (when ready):
   ```bash
   cd ~/aws-serverless-microservices-ai/terraform/agent-service/prod
   terraform plan
   terraform apply
   ```

---

## 🔐 Security Notes

- IAM policy follows least-privilege principle
- Only Bedrock invoke permissions granted
- No wildcard permissions
- Secrets stored in AWS Secrets Manager
- CloudWatch logs enabled for auditing

---

## 💰 Cost Impact

This deployment has **minimal cost impact**:
- IAM policy changes: Free
- Lambda code update: Free (no additional charges)
- Bedrock usage: Pay-per-use (~$0.25 per 1M input tokens)

---

## ✅ Final Checklist

Before running deployment:
- [ ] SSH access to EC2 (35.154.6.204) working
- [ ] AWS credentials configured on EC2
- [ ] Git repository accessible
- [ ] Terraform installed on EC2
- [ ] AWS CLI installed on EC2

All prerequisites should already be met since you've deployed before.

---

**You're ready to deploy! Choose Option 1 (automated script) or Option 2 (manual commands) and run them on your EC2 instance.**

**Good luck! 🚀**
