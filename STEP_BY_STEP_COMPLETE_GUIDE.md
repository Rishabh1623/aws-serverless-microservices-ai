# 🚀 Complete Step-by-Step Guide

**ONE FILE TO COMPLETE THE ENTIRE PROJECT**

Follow this guide from start to finish. Every command, every step, in order.

**Time Required:** 8-10 hours  
**Cost:** $1-5 for 3-day demo  
**Result:** Fully deployed AWS serverless microservices + Demo video

---

## 🎯 CURRENT STATUS

### ✅ Completed (Steps 1-7, 9-12, 14-16):
- EC2 instance launched and configured
- All tools installed (Terraform, AWS CLI, Python, Node.js, Docker)
- AWS credentials configured
- Project cloned from GitHub
- Shared infrastructure deployed (S3 + DynamoDB for Terraform state)
- **Cart Service** deployed and working ✅
- **Payment Service** deployed and working ✅
- **Order Service** deployed and working ✅
- **MCP Observability Server** deployed and working ✅
- **Troubleshooting Agent Service** deployed and working ✅
- **Frontend** deployed to S3 and accessible ✅
- **Product Service** deployed and working ✅

### ⚠️ Pending (Steps 8, 13, 17-18):
- **Product Service** - ✅ DEPLOYED (API: https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev)
- **Shopping Agent Service** - ⚠️ NEEDS REDEPLOYMENT (has placeholder environment variables)
- **Frontend Update** - Needs Product API URL and Agent fix
- **Demo Recording** - Final step after everything works

### 🔧 Known Issues Fixed:
- ✅ Agent import errors (strands_agents → strands)
- ✅ Agent API method (agent.process() → agent())
- ✅ Docker build caching issues
- ✅ S3 bucket permissions for frontend
- ✅ Lambda permissions for Cart Service
- ✅ Product Service Terraform created and deployed
- ⚠️ Shopping Agent environment variables (placeholder "yes" values need fixing)

### 📍 Where You Are Now:
**The Shopping Agent has placeholder environment variables ("yes" instead of real API URLs).**

This is why the AI Assistant says services aren't responding. You need to:
1. Redeploy Shopping Agent with correct API URLs (Step 13)
2. Update frontend with Product API URL (Step 17)
3. Test end-to-end flow
4. Record demo (Step 18)

---

## 📋 Table of Contents

1. ✅ [Prerequisites Check](#step-1-prerequisites-check) - COMPLETED
2. ✅ [Launch EC2 Instance](#step-2-launch-ec2-instance) - COMPLETED
3. ✅ [Connect to EC2](#step-3-connect-to-ec2) - COMPLETED
4. ✅ [Install Tools](#step-4-install-tools) - COMPLETED
5. ✅ [Configure AWS](#step-5-configure-aws) - COMPLETED
6. ✅ [Clone Project](#step-6-clone-project) - COMPLETED
7. ✅ [Deploy Shared Infrastructure](#step-7-deploy-shared-infrastructure) - COMPLETED
8. ✅ [Deploy Product Service](#step-8-deploy-product-service) - COMPLETED (API deployed)
9. ✅ [Deploy Cart Service](#step-9-deploy-cart-service) - COMPLETED
10. ✅ [Deploy Payment Service](#step-10-deploy-payment-service) - COMPLETED
11. ✅ [Deploy Order Service](#step-11-deploy-order-service) - COMPLETED
12. ✅ [Deploy MCP Server](#step-12-deploy-mcp-server) - COMPLETED
13. ⚠️ [Deploy Shopping Agent](#step-13-deploy-shopping-agent) - NEEDS REDEPLOYMENT (fix env vars)
14. ✅ [Deploy Troubleshooting Agent](#step-14-deploy-troubleshooting-agent) - COMPLETED
15. ✅ [Verify Deployment](#step-15-verify-deployment) - COMPLETED
16. ✅ [Setup Frontend](#step-16-setup-frontend) - COMPLETED (Deployed to S3)
17. ⚠️ [Update Frontend with Product API](#step-17-update-frontend-with-product-api) - PENDING
18. ⚠️ [Record Demo](#step-18-record-demo) - PENDING
19. [Cleanup (Optional)](#step-19-cleanup-optional)

---

## STEP 1: Prerequisites Check

### What You Need:

- [ ] AWS Account (with admin access)
- [ ] AWS Access Key ID and Secret Access Key
- [ ] Credit card on file (for AWS charges)
- [ ] GitHub account (optional, for CI/CD)
- [ ] Local machine with internet

### Get AWS Credentials:

1. Go to AWS Console → IAM → Users → Your User
2. Click "Security credentials"
3. Click "Create access key"
4. Download and save:
   - Access Key ID: `AKIA...`
   - Secret Access Key: `...`

**✅ Checkpoint:** You have AWS Access Key ID and Secret Access Key

---

## STEP 2: Launch EC2 Instance

### Option A: AWS Console (Easier)

1. Go to **EC2 Dashboard** → **Launch Instance**
2. **Name:** `serverless-deployment-server`
3. **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
4. **Instance type:** t3.medium (2 vCPU, 4GB RAM)
5. **Key pair:** 
   - Click "Create new key pair"
   - Name: `deployment-key`
   - Type: RSA
   - Format: .pem
   - **Download and save the .pem file!**
6. **Network settings:**
   - Allow SSH from: My IP
7. **Storage:** 30GB gp3
8. **Launch instance**
9. Wait 2-3 minutes for instance to start

### Option B: AWS CLI (Faster)

```bash
# From your local machine
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --key-name deployment-key \
  --security-group-ids sg-xxxxx \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=serverless-deployment-server}]'
```

### Get Instance Public IP:

```bash
# AWS Console: EC2 → Instances → Select your instance → Copy "Public IPv4 address"
# Or via CLI:
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=serverless-deployment-server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

**Save this IP address!** Example: `54.123.45.67`

**✅ Checkpoint:** EC2 instance is running, you have the public IP

---

## STEP 3: Connect to EC2

### Set Key Permissions:

```bash
# On your local machine
chmod 400 deployment-key.pem
```

### Connect via SSH:

```bash
# Replace with your actual IP
ssh -i deployment-key.pem ubuntu@54.123.45.67
```

**You should see:**
```
Welcome to Ubuntu 22.04.x LTS
ubuntu@ip-172-31-x-x:~$
```

**✅ Checkpoint:** You're connected to EC2 (you see `ubuntu@ip-...` prompt)

---

## STEP 4: Install Tools

**Run these commands on EC2 (copy-paste entire blocks):**

### Update System:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip vim htop tree
```

### Install Terraform:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform -y

# Verify
terraform --version
```

**Expected output:** `Terraform v1.7.x`

### Install AWS CLI v2:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Verify
aws --version
```

**Expected output:** `aws-cli/2.x.x`

### Install Python 3.11:

```bash
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev python3-pip -y

# Verify
python3.11 --version
```

**Expected output:** `Python 3.11.x`

### Install Additional Tools:

```bash
sudo apt install jq zip -y

# Verify all tools
echo "=== Tool Versions ==="
terraform --version
aws --version
python3.11 --version
jq --version
zip --version
```

**✅ Checkpoint:** All tools installed successfully

---

## STEP 5: Configure AWS

### Configure AWS Credentials:

```bash
aws configure
```

**Enter when prompted:**
- AWS Access Key ID: `AKIA...` (from Step 1)
- AWS Secret Access Key: `...` (from Step 1)
- Default region name: `us-east-1`
- Default output format: `json`

### Verify AWS Access:

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Export AWS Account ID:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Make permanent
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc
```

**✅ Checkpoint:** AWS CLI configured, account ID exported

---

## STEP 6: Clone Project

### Clone from GitHub:

```bash
cd ~
git clone https://github.com/Rishabh1623/aws-serverless-microservices-ai.git
cd aws-serverless-microservices-ai

# Verify
ls -la
```

**You should see:**
```
agent-service/
cart-service/
order-service/
payment-service/
product-service/
troubleshooting-agent-service/
mcp-servers/
terraform/
frontend/
README.md
...
```

### Update Terraform Backend:

```bash
# Replace ACCOUNT_ID with your actual account ID in all Terraform files
find terraform -name "main.tf" -type f -exec sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" {} \;

# Verify (should return nothing)
grep -r "ACCOUNT_ID" terraform/
```

**✅ Checkpoint:** Project cloned, Terraform files updated

---

## STEP 7: Deploy Shared Infrastructure

**This creates S3 bucket and DynamoDB table for Terraform state.**

```bash
cd ~/aws-serverless-microservices-ai/terraform/shared

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply
```

**Expected output:**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

**✅ Checkpoint:** Shared infrastructure deployed (S3 + DynamoDB)

---

## STEP 7.5: Setup API Gateway CloudWatch Logs (ONE-TIME)

**This is a ONE-TIME AWS account configuration. Required for API Gateway logging.**

### Create IAM Role for API Gateway:

```bash
cd ~/aws-serverless-microservices-ai

# Create trust policy
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name APIGatewayCloudWatchLogsRole \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --description "Allows API Gateway to push logs to CloudWatch Logs"

# Attach the managed policy
aws iam attach-role-policy \
  --role-name APIGatewayCloudWatchLogsRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name APIGatewayCloudWatchLogsRole --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Set the CloudWatch role ARN in API Gateway account settings
aws apigateway update-account \
  --patch-operations op=replace,path=/cloudwatchRoleArn,value=$ROLE_ARN
```

### Verify Setup:

```bash
aws apigateway get-account --query 'cloudwatchRoleArn'
```

**Expected output:**
```
"arn:aws:iam::543927035352:role/APIGatewayCloudWatchLogsRole"
```

**✅ Checkpoint:** API Gateway can now write to CloudWatch Logs

---

## STEP 8: Deploy Product Service

**STATUS: ✅ COMPLETED**

**What Was Done:**
- Created Terraform configuration from scratch (didn't exist in repo)
- Deployed Product Service successfully
- API URL: https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev
- Returns empty products array (DynamoDB table is empty, which is expected)

**Note:** If you need to redeploy, use the commands below.

```bash
cd ~/aws-serverless-microservices-ai/terraform/product-service/dev

# Initialize Terraform
terraform init

# Deploy Product Service
terraform apply -auto-approve
```

**Wait 3-5 minutes for deployment.**

### Save API Endpoint:

```bash
PRODUCT_API=$(terraform output -raw api_gateway_url)
echo "Product API: $PRODUCT_API"

# Save to file
echo "PRODUCT_API=$PRODUCT_API" >> ~/api-endpoints.txt

# Also export for later use
export PRODUCT_API
```

### Test Product Service:

```bash
# Test list products
curl "$PRODUCT_API/products"

# Expected: {"products": [], "count": 0, "category": null}
```

**✅ Checkpoint:** Product service deployed and working

### What's Next:
Now that Product Service is deployed, you need to:
1. Redeploy Shopping Agent with correct API URLs (Step 13)
2. Update frontend with Product API URL (Step 17)

---

## STEP 9: Deploy Cart Service

**STATUS: ✅ COMPLETED**

**What Was Done:**
- Deployed Cart Service successfully
- Fixed Lambda permissions manually (added permissions for all 3 Lambda functions)
- Tested all endpoints (GET, POST, DELETE)
- API URL: https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev

**Note:** If you need to redeploy, use the commands below.

```bash
cd ~/aws-serverless-microservices-ai/terraform/cart-service/dev

terraform init
terraform apply -auto-approve
```

### Save API Endpoint:

```bash
CART_API=$(terraform output -raw api_gateway_url)
echo "Cart API: $CART_API"
echo "CART_API=$CART_API" >> ~/api-endpoints.txt
```

### Test Cart Service:

```bash
curl "$CART_API/cart/user123"
```

**Expected:** JSON response with cart data

**✅ Checkpoint:** Cart service deployed and working

---

## STEP 10: Deploy Payment Service

```bash
cd ~/aws-serverless-microservices-ai/terraform/payment-service/dev

terraform init
terraform apply
```

**Type `yes` when prompted.**

### Save API Endpoint:

```bash
PAYMENT_API=$(terraform output -raw api_gateway_url)
echo "Payment API: $PAYMENT_API"
echo "PAYMENT_API=$PAYMENT_API" >> ~/api-endpoints.txt
```

**✅ Checkpoint:** Payment service deployed

---

## STEP 11: Deploy Order Service

```bash
cd ~/aws-serverless-microservices-ai/terraform/order-service/dev

terraform init
terraform apply
```

**Type `yes` when prompted.**

### Save API Endpoint:

```bash
ORDER_API=$(terraform output -raw api_gateway_url)
echo "Order API: $ORDER_API"
echo "ORDER_API=$ORDER_API" >> ~/api-endpoints.txt
```

**✅ Checkpoint:** Order service deployed

---

## STEP 12: Deploy MCP Server

```bash
cd ~/aws-serverless-microservices-ai/terraform/mcp-servers

terraform init
terraform apply -var="environment=dev"
```

**Type `yes` when prompted.**

### Save MCP URL:

```bash
MCP_URL=$(terraform output -raw aws_observability_mcp_url)
echo "MCP Server URL: $MCP_URL"
echo "MCP_URL=$MCP_URL" >> ~/api-endpoints.txt
```

**✅ Checkpoint:** MCP server deployed

---

## STEP 13: Deploy Shopping Agent

**STATUS: ⚠️ NEEDS REDEPLOYMENT - Environment variables have placeholder values**

**Issues Fixed:**
1. ✅ Import errors: Changed `from strands_agents import tool` to `from strands import tool`
2. ✅ Agent API: Changed `agent.process()` to `agent()` call
3. ✅ Docker build: Used `--no-cache` to pick up source changes
4. ✅ Git conflicts: Stashed local changes to pull updates

**Current Issue:**
- Agent Lambda has placeholder environment variables (all set to "yes")
- This causes the agent to say services aren't responding
- Need to redeploy with correct API URLs

**Current Status:**
- Agent is deployed and responding intelligently
- API URL: https://tvrhm1ftqe.execute-api.us-east-1.amazonaws.com
- But cannot call backend services due to invalid URLs

### Redeploy with Correct API URLs:

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

# Set all API URLs from deployed services
export PRODUCT_API="https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev"
export CART_API="https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev"
export ORDER_API="https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev"
export PAYMENT_API="https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev"

# Redeploy with correct environment variables
terraform apply \
  -var="product_api_url=$PRODUCT_API" \
  -var="cart_api_url=$CART_API" \
  -var="order_api_url=$ORDER_API" \
  -var="payment_api_url=$PAYMENT_API" \
  -auto-approve
```

### Verify Environment Variables:

```bash
# Check Lambda function's environment variables
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables' \
  --output json
```

**Expected output:**
```json
{
  "PRODUCT_API_URL": "https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev",
  "CART_API_URL": "https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev",
  "ORDER_API_URL": "https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev",
  "PAYMENT_API_URL": "https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev",
  "BEDROCK_MODEL_ID": "anthropic.claude-3-sonnet-20240229-v1:0",
  "LOG_LEVEL": "INFO"
}
```

### Save Agent API:

```bash
AGENT_API=$(terraform output -raw api_gateway_url)
echo "Shopping Agent API: $AGENT_API"
echo "AGENT_API=$AGENT_API" >> ~/api-endpoints.txt
```

### Test Shopping Agent:

```bash
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me products", "userId": "user123"}'
```

**Expected:** JSON response from AI agent with intelligent conversation

**✅ Checkpoint:** Shopping agent deployed and working

---

## STEP 14: Deploy Troubleshooting Agent

```bash
cd ~/aws-serverless-microservices-ai/terraform/troubleshooting-agent-service/dev

terraform init
terraform apply \
  -var="aws_observability_mcp_url=$MCP_URL"
```

**Type `yes` when prompted.**

### Save Troubleshooting API:

```bash
TROUBLESHOOT_API=$(terraform output -raw api_gateway_url)
echo "Troubleshooting Agent API: $TROUBLESHOOT_API"
echo "TROUBLESHOOT_API=$TROUBLESHOOT_API" >> ~/api-endpoints.txt
```

### Test Troubleshooting Agent:

```bash
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{"question": "Check system health", "timeRange": "1h"}'
```

**Expected:** JSON response with system health analysis

**✅ Checkpoint:** Troubleshooting agent deployed and working

---

## STEP 15: Verify Deployment

### Check All Endpoints:

```bash
cat ~/api-endpoints.txt
```

**You should see 7 URLs:**
```
PRODUCT_API=https://...
CART_API=https://...
PAYMENT_API=https://...
ORDER_API=https://...
MCP_URL=https://...
AGENT_API=https://...
TROUBLESHOOT_API=https://...
```

### Check All Lambda Functions:

```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `dev`)].FunctionName'
```

**Expected:** List of 7+ Lambda functions

### Check CloudWatch Alarms:

```bash
aws cloudwatch describe-alarms --state-value ALARM
```

**Expected:** No alarms in ALARM state (or empty list)

**✅ Checkpoint:** All 7 microservices deployed successfully!

---

## STEP 16: Setup Frontend

**STATUS: ✅ COMPLETED (Deployed to AWS S3)**

**What Was Done:**
- Installed Node.js on EC2
- Built React frontend with Vite
- Deployed to S3 bucket as static website
- Frontend URL: http://serverless-microservices-frontend-543927035352.s3-website-us-east-1.amazonaws.com

**Current Issue:**
- Product API is set to placeholder URL, so product search doesn't work
- Need to update .env with real Product API URL after deploying Product Service (Step 8)

### Frontend is Already Deployed

If you need to rebuild/redeploy, use these commands:

```bash
cd ~/aws-serverless-microservices-ai/frontend

# Update .env with real API URLs
cat > .env << EOF
VITE_PRODUCT_API=$PRODUCT_API
VITE_CART_API=$CART_API
VITE_ORDER_API=$ORDER_API
VITE_PAYMENT_API=$PAYMENT_API
VITE_AGENT_API=$AGENT_API
VITE_TROUBLESHOOT_API=$TROUBLESHOOT_API
EOF

# Rebuild
npm run build

# Redeploy to S3
BUCKET_NAME="serverless-microservices-frontend-${AWS_ACCOUNT_ID}"
aws s3 sync dist/ s3://${BUCKET_NAME}/ --delete
```

**Open browser:** http://serverless-microservices-frontend-543927035352.s3-website-us-east-1.amazonaws.com

**You should see:**
- Home page with architecture
- Working AI Shopping Assistant
- Cart functionality
- Admin Dashboard
- Orders page

**✅ Checkpoint:** Frontend deployed and accessible!

---

## STEP 17: Update Frontend with Product API

**STATUS: ⚠️ PENDING - Do this after deploying Product Service (Step 8)**

After you deploy the Product Service in Step 8, you need to update the frontend to use the real Product API URL.

### Update and Redeploy Frontend:

```bash
cd ~/aws-serverless-microservices-ai/frontend

# Make sure PRODUCT_API is set (from Step 8)
echo "Product API: $PRODUCT_API"

# Update .env file with real Product API
cat > .env << EOF
VITE_PRODUCT_API=$PRODUCT_API
VITE_CART_API=https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev
VITE_ORDER_API=https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev
VITE_PAYMENT_API=https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev
VITE_AGENT_API=https://tvrhm1ftqe.execute-api.us-east-1.amazonaws.com
VITE_TROUBLESHOOT_API=https://b05ax9z4m4.execute-api.us-east-1.amazonaws.com
EOF

# Rebuild frontend
npm run build

# Redeploy to S3
BUCKET_NAME="serverless-microservices-frontend-${AWS_ACCOUNT_ID}"
aws s3 sync dist/ s3://${BUCKET_NAME}/ \
  --delete \
  --cache-control "public, max-age=31536000" \
  --exclude "index.html"

# Upload index.html with no-cache
aws s3 cp dist/index.html s3://${BUCKET_NAME}/index.html \
  --cache-control "no-cache"

echo ""
echo "✅ Frontend updated with Product API!"
echo "URL: http://${BUCKET_NAME}.s3-website-us-east-1.amazonaws.com"
```

### Test Complete End-to-End Flow:

1. Open frontend URL in browser
2. Go to "AI Assistant" page
3. Type: "Show me laptops under $1000"
4. Agent should now search products successfully
5. Type: "Add the Dell laptop"
6. Type: "Create my order"
7. Complete checkout flow

**✅ Checkpoint:** Complete end-to-end e-commerce flow working!

---

## STEP 17.5: Add Sample Products (Optional)

**STATUS: Optional - Makes demo more realistic**

The Product Service DynamoDB table is empty by default. Add sample products for testing:

```bash
cd ~/aws-serverless-microservices-ai

# Make script executable
chmod +x ADD_SAMPLE_PRODUCTS.sh

# Run script
./ADD_SAMPLE_PRODUCTS.sh
```

This adds 3 sample laptops:
- Dell Inspiron 15 - $699
- HP Pavilion - $849
- Apple MacBook Air M2 - $1199

**✅ Checkpoint:** Sample products available for AI Assistant to search!

---

## STEP 18: Record Demo

**STATUS: ⚠️ PENDING**

### Prepare for Recording:

1. **Close unnecessary tabs**
2. **Zoom browser to 110%** (Ctrl/Cmd + +)
3. **Full screen** (F11)
4. **Start recording software** (OBS, Loom, etc.)

### Recording Script (5 minutes):

#### Scene 1: Home (30 seconds)
- Show architecture diagram
- Highlight 7 microservices
- Mention AWS Bedrock + MCP

#### Scene 2: Products (30 seconds)
- Browse product catalog
- Search for products
- Add item to cart

#### Scene 3: AI Shopping Assistant (2 minutes) ⭐
- Click "AI Assistant"
- Type: "I want to buy a laptop under $1000"
- Type: "Add the Dell laptop"
- Type: "Yes, create my order"
- **Show tools used** (search_products, add_to_cart, create_order)

#### Scene 4: Admin Dashboard (1.5 minutes) ⭐
- Click "Admin"
- Type: "Check system health"
- Type: "Why is the cart service failing?"
- **Show MCP tools used**

#### Scene 5: Closing (30 seconds)
- Show order history
- Mention production features
- Show cost ($1-5 for demo)

**✅ Checkpoint:** Demo video recorded!

---

## STEP 18: Cleanup (Optional)

### To Save Costs, Destroy Everything:

```bash
# Destroy in reverse order

# Troubleshooting Agent
cd ~/aws-serverless-microservices-ai/terraform/troubleshooting-agent-service/dev
terraform destroy

# Shopping Agent
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev
terraform destroy

# MCP Server
cd ~/aws-serverless-microservices-ai/terraform/mcp-servers
terraform destroy

# Order Service
cd ~/aws-serverless-microservices-ai/terraform/order-service/dev
terraform destroy

# Payment Service
cd ~/aws-serverless-microservices-ai/terraform/payment-service/dev
terraform destroy

# Cart Service
cd ~/aws-serverless-microservices-ai/terraform/cart-service/dev
terraform destroy

# Product Service
cd ~/aws-serverless-microservices-ai/terraform/product-service/dev
terraform destroy

# Shared Infrastructure (LAST!)
cd ~/aws-serverless-microservices-ai/terraform/shared
terraform destroy
```

### Stop EC2 Instance:

```bash
# From your local machine
aws ec2 stop-instances --instance-ids i-xxxxx
```

**✅ Checkpoint:** All resources cleaned up, no more charges!

---

## 🎉 CONGRATULATIONS!

You have successfully:
- ✅ Deployed 7 microservices to AWS
- ✅ Setup AI Shopping Assistant (AWS Bedrock)
- ✅ Setup DevOps Troubleshooting Agent (MCP)
- ✅ Created production-grade infrastructure
- ✅ Recorded a demo video

---

## 📊 Final Checklist

- [ ] All 7 services deployed
- [ ] All API endpoints working
- [ ] Frontend connected to backend
- [ ] Demo video recorded
- [ ] Project on GitHub
- [ ] Resources cleaned up (optional)

---

## 🚨 Troubleshooting

### Terraform Error: "State lock"
```bash
# Force unlock (use the Lock ID from error message)
terraform force-unlock LOCK_ID
```

### Lambda Error: "Out of memory"
```bash
# Increase memory in terraform/*/main.tf
memory_size = 1024  # Change to 1536 or 2048
terraform apply
```

### API Gateway 403 Error
```bash
# Check CORS settings in API Gateway console
# Or redeploy the service
terraform apply
```

### Can't Connect to EC2
```bash
# Update security group to allow your IP
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp --port 22 \
  --cidr $(curl -s ifconfig.me)/32
```

---

## 💰 Cost Summary

**3-Day Demo:**
- EC2 (t3.medium): $2.40
- Lambda: $0.20
- DynamoDB: $0.50
- API Gateway: $0.10
- Bedrock: $0.50
- **Total: ~$3.70**

**Monthly (if kept running):**
- ~$110/month

**Tip:** Destroy resources after demo to avoid charges!

---

## 📞 Need Help?

1. Check error messages carefully
2. Review CloudWatch Logs
3. Verify AWS credentials
4. Check security groups
5. Ensure correct region (us-east-1)

---

**You did it! 🚀**

This is a production-grade, portfolio-worthy project. Share it proudly!
