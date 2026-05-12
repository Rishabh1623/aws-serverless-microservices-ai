# Migration to New AWS Account - Complete Guide

## Quick Summary

**Old Account**: 600105205879 (Bedrock payment issue)  
**New Account**: [Your new account ID]  
**Goal**: Migrate entire project to new account with working Bedrock

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] New AWS account created
- [ ] Payment method added to new account
- [ ] AWS CLI access keys for new account
- [ ] Bedrock model access enabled in new account
- [ ] Bedrock tested in console (Claude responds)
- [ ] SSH key pair for new EC2

---

## Step-by-Step Migration

### 1. Enable Bedrock in New Account (5 minutes)

```bash
# In new AWS Console:
1. Go to: https://console.aws.amazon.com/bedrock/
2. Click "Model access" in left sidebar
3. Click "Manage model access"
4. Find "Anthropic" → Check "Claude 3 Haiku"
5. Click "Save changes"
6. Wait 2-3 minutes (usually instant)
7. Status should show "Access granted" ✅
```

### 2. Test Bedrock in Console (2 minutes)

```bash
# In new AWS Console:
1. Go to Bedrock → Playgrounds → Chat
2. Select "Claude 3 Haiku"
3. Type: "Hello, can you respond?"
4. If Claude responds → Payment is working! ✅
5. If error → Check payment method in billing console
```

### 3. Create New EC2 Instance (10 minutes)

```bash
# In new AWS Console:
1. EC2 → Launch Instance
2. Name: aws-deployment-server
3. AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
4. Instance type: t3.medium (or t2.medium)
5. Key pair: Create new or select existing
6. Network: Default VPC
7. Security group: 
   - Allow SSH (22) from your IP
   - Allow HTTPS (443) from anywhere (for API Gateway)
8. Storage: 30 GB gp3
9. Launch instance
10. Note the public IP address
```

### 4. Set Up New EC2 (15 minutes)

```bash
# SSH to new EC2
ssh -i your-key.pem ubuntu@NEW_EC2_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Install Python and tools
sudo apt install python3 python3-pip python3-venv git jq -y

# Configure AWS credentials
aws configure
# Enter:
# - Access Key ID: [Your new account key]
# - Secret Access Key: [Your new account secret]
# - Region: us-east-1
# - Output: json

# Verify
aws sts get-caller-identity
# Should show NEW account ID

# Clone repository
cd ~
git clone https://github.com/Rishabh1623/aws-serverless-microservices-ai.git
cd aws-serverless-microservices-ai
```

### 5. Deploy to New Account (30 minutes)

```bash
# On new EC2
cd ~/aws-serverless-microservices-ai

# Make scripts executable
chmod +x update-terraform-backend.sh
chmod +x deploy-new-account.sh

# Run automated deployment
bash deploy-new-account.sh
```

This script will:
1. Update Terraform backend for new account
2. Create S3 bucket for Terraform state
3. Deploy all services in correct order
4. Add sample hotel data
5. Test the agent service

### 6. Verify Deployment (5 minutes)

```bash
# Test Agent Service
curl -X POST https://YOUR-NEW-API-URL/agent \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello! Can you help me find a hotel in Paris?","userId":"test","sessionId":"test"}'

# Should return:
# {
#   "response": "Hello! I'd be happy to help you find a hotel in Paris...",
#   "toolsUsed": [],
#   "userId": "test",
#   "sessionId": "test"
# }

# Check logs
aws logs tail /aws/lambda/agent-service-dev --since 1m

# Should see:
# [INFO] Processing message from user test
# [INFO] Creating Strands MetricsClient
# NO ERRORS about INVALID_PAYMENT_INSTRUMENT ✅
```

---

## Clean Up Old Account (Optional)

### Destroy Old Resources (Saves Money)

```bash
# SSH to OLD EC2 (if still running)
ssh ubuntu@35.154.6.204

cd ~/aws-serverless-microservices-ai

# Destroy all services
cd terraform/agent-service/dev && terraform destroy -auto-approve
cd ../../hotel-service/dev && terraform destroy -auto-approve
cd ../../cart-service/dev && terraform destroy -auto-approve
cd ../../order-service/dev && terraform destroy -auto-approve
cd ../../payment-service/dev && terraform destroy -auto-approve

# Exit
exit
```

### Terminate Old EC2

```bash
# In OLD AWS Console:
1. Go to EC2 → Instances
2. Select instance (35.154.6.204)
3. Instance State → Terminate
4. Confirm termination
```

---

## Troubleshooting

### Issue: "Bedrock model access denied"

**Solution:**
```bash
# In new AWS Console:
1. Go to Bedrock → Model access
2. Verify Claude 3 Haiku shows "Access granted"
3. If not, request access again
4. Test in Bedrock Playground first
```

### Issue: "Terraform state bucket not found"

**Solution:**
```bash
# Create bucket manually
NEW_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://terraform-state-${NEW_ACCOUNT_ID} --region us-east-1
aws s3api put-bucket-versioning \
  --bucket terraform-state-${NEW_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled
```

### Issue: "Lambda build fails"

**Solution:**
```bash
cd ~/aws-serverless-microservices-ai/agent-service
rm -rf build agent-service-lambda.zip
bash build-lambda.sh
```

### Issue: "INVALID_PAYMENT_INSTRUMENT in new account too"

**Solution:**
```bash
# This means payment validation is still processing
# 1. Verify payment method in billing console
# 2. Test Bedrock in console - if it works, wait 2-4 hours
# 3. If console doesn't work, add different payment method
# 4. Contact AWS Support immediately (don't wait 3 days!)
```

---

## Cost Comparison

### Old Account (Monthly)
- EC2 t3.medium: ~$30
- Lambda invocations: ~$5
- DynamoDB: ~$5
- API Gateway: ~$3
- **Total: ~$43/month**

### New Account (Monthly)
- Same infrastructure
- **Total: ~$43/month**
- **Plus**: Working Bedrock access ✅

---

## Important Notes

1. **Update Frontend**: After deployment, update frontend with new API URLs
2. **DNS/Domain**: If you have custom domain, update DNS records
3. **Monitoring**: Set up CloudWatch alarms in new account
4. **Backup**: Old account data is in DynamoDB - export if needed
5. **Git**: All code is in GitHub - no data loss

---

## Success Criteria

✅ New EC2 instance running  
✅ All services deployed  
✅ Agent service responds without errors  
✅ No INVALID_PAYMENT_INSTRUMENT errors  
✅ Bedrock working from Lambda  
✅ Sample hotels loaded  
✅ All API endpoints accessible  

---

## Timeline

- **Preparation**: 10 minutes (enable Bedrock, create EC2)
- **Setup**: 15 minutes (install tools, clone repo)
- **Deployment**: 30 minutes (automated script)
- **Verification**: 5 minutes (test endpoints)
- **Total**: ~60 minutes

---

## Support

If you encounter issues:

1. **Check logs**: `aws logs tail /aws/lambda/agent-service-dev --since 5m`
2. **Verify Bedrock**: Test in console first
3. **Check IAM**: Ensure Lambda has Bedrock permissions
4. **AWS Support**: If payment issues persist, contact immediately

---

## Next Steps After Migration

1. Test all API endpoints thoroughly
2. Update frontend configuration
3. Set up CloudWatch alarms
4. Configure backup strategy
5. Document new account details
6. Update team with new URLs
7. Close old AWS account (after verification)
