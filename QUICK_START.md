# 🚀 Quick Start - Agent Service Deployment

## ✅ All Configuration Verified - Ready to Deploy!

---

## 🎯 Copy-Paste Commands (Recommended)

### Option 1: Automated Deployment Script

```bash
# SSH to EC2
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204

# Run these commands
cd ~/aws-serverless-microservices-ai
git pull origin main
chmod +x deploy-agent-iam-fix.sh
./deploy-agent-iam-fix.sh
```

**The script handles everything automatically!**

---

### Option 2: Manual Commands

```bash
# SSH to EC2
ssh -i ~/.ssh/your-key.pem ubuntu@35.154.6.204

# Pull latest code
cd ~/aws-serverless-microservices-ai
git pull origin main

# Build Lambda package
cd agent-service
bash build-lambda.sh

# Deploy with Terraform
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform init
terraform plan
terraform apply

# Test
sleep 10
curl -X POST https://bj623ttpd4.execute-api.us-east-1.amazonaws.com/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello!","userId":"test","sessionId":"test"}'

# Check logs
aws logs tail /aws/lambda/agent-service-dev --since 2m
```

---

## ✅ Success Looks Like

### Terraform Output:
```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

### API Response:
```json
{
  "response": "Hello! I'd be happy to help you...",
  "toolsUsed": [],
  "userId": "test"
}
```

### Lambda Logs:
```
[INFO] Processing message from user test
[INFO] Found credentials in environment variables
[INFO] Tools used: []
```

**No errors = Success! 🎉**

---

## 📚 Full Documentation

- **`DEPLOYMENT_READY.md`** - Complete deployment guide
- **`PRE_DEPLOYMENT_CHECKLIST.md`** - Detailed configuration verification
- **`AGENT_IAM_FIX_DEPLOYMENT.md`** - Step-by-step with explanations
- **`deploy-agent-iam-fix.sh`** - Automated deployment script

---

## ⏱️ Time Required

**~5-7 minutes total**

---

## 🆘 If Something Goes Wrong

### Build fails:
```bash
cd ~/aws-serverless-microservices-ai/agent-service
rm -rf build/
bash build-lambda.sh
```

### Still getting errors:
```bash
# Check IAM policy
aws iam get-role-policy \
  --role-name agent-service-dev-lambda-role \
  --policy-name agent-service-dev-bedrock-policy

# Wait longer
sleep 30

# Test again
```

---

## 🎯 What This Fixes

- ✅ IAM permissions for Claude Haiku 4.5
- ✅ Inference profile ARN support
- ✅ OpenTelemetry compatibility
- ✅ Python 3.10 runtime

---

**Choose Option 1 or Option 2 above and run on your EC2 instance!**

**All files are verified and ready. You just need to execute the commands. Good luck! 🚀**
