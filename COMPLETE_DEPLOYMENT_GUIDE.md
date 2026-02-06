# 🚀 Complete Deployment Guide - Production-Grade Serverless Microservices

## 📋 **Overview**

This comprehensive guide covers deploying a **production-grade serverless microservices platform** with:
- ✅ **4 Core Microservices** (Product, Cart, Payment, Order)
- ✅ **2 AI Agent Services** (Shopping Assistant, DevOps Troubleshooting)
- ✅ **6 Independent CI/CD Pipelines** (AWS DevOps)
- ✅ **Production Features** (Cognito, Secrets Manager, Monitoring, Resilience)
- ✅ **MCP Protocol Integration** (Model Context Protocol for AI tools)

**Architecture Pattern:** AWS re:Invent Pattern 1 (Domain-Driven Microservices)

**What You'll Learn:**
- 🎓 How to deploy true microservices (not distributed monoliths)
- 🎓 How to integrate AI agents with Strands SDK and Bedrock
- 🎓 How to implement MCP servers for operational AI
- 🎓 How to set up production-grade security and monitoring
- 🎓 How to troubleshoot common deployment issues

**Time Required:** 7-10 hours (spread over 7 weeks for learning)

**Cost:** ~$110/month (can be reduced to ~$73/month with optimizations)

---

## 🏗️ **Complete Architecture**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CUSTOMER & DEVOPS LAYER                           │
│  👤 End Users (Shopping)          👨‍💼 DevOps Engineers (Operations)     │
└─────────────────────────────────────────────────────────────────────────┘
                    │                                    │
        ┌───────────┴──────────┐          ┌─────────────┴──────────────┐
        │                      │          │                            │
   Traditional API      Natural Language  │    Troubleshooting         │
        │                      │          │    Questions               │
        ↓                      ↓          ↓                            ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY LAYER                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ Product  │ │  Cart    │ │  Order   │ │ Payment  │ │ Shopping     │ │
│  │ /products│ │  /cart   │ │  /orders │ │ /payments│ │ Agent        │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ │ /agent       │ │
│                                                        │              │ │
│                                                        │ Troubleshoot │ │
│                                                        │ Agent        │ │
│                                                        │ /troubleshoot│ │
│                                                        └──────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ↓                           ↓                           ↓
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  MICROSERVICES       │  │  AI SHOPPING AGENT   │  │  AI TROUBLESHOOTING  │
│  (Pattern 1)         │  │  (Strands + Bedrock) │  │  AGENT (MCP)         │
│                      │  │                      │  │                      │
│  ┌────────────────┐ │  │  ┌────────────────┐ │  │  ┌────────────────┐ │
│  │ Product Service│ │  │  │ Agent Lambda   │ │  │  │ Agent Lambda   │ │
│  │ • list         │ │  │  │ + Claude 3     │ │  │  │ + MCP Clients  │ │
│  │ • get          │ │  │  │ + Tools:       │ │  │  │                │ │
│  │ ↓ DynamoDB     │ │  │  │   - search()   │ │  │  │ MCP Servers:   │ │
│  └────────────────┘ │  │  │   - add_cart() │ │  │  │ • Logs         │ │
│                      │  │  │   - checkout() │ │  │  │ • Metrics      │ │
│  ┌────────────────┐ │  │  └────────────────┘ │  │  │ • AWS Services │ │
│  │ Cart Service   │◄─┼──┼─────────┘          │  │  └────────────────┘ │
│  │ • add          │ │  │                     │  │         │           │
│  │ • remove       │ │  │                     │  │         ↓           │
│  │ • get          │ │  │                     │  │  CloudWatch         │
│  │ ↓ DynamoDB     │ │  │                     │  │  AWS APIs           │
│  └────────────────┘ │  │                     │  │                     │
│                      │  │                     │  │                     │
│  ┌────────────────┐ │  │                     │  │                     │
│  │ Payment Service│◄─┼──┼─────────────────────┼──┘                    │
│  │ • process      │ │  │                     │                        │
│  │ • get          │ │  │                     │                        │
│  │ ↓ DynamoDB     │ │  │                     │                        │
│  │ ↓ Secrets Mgr  │ │  │                     │                        │
│  └────────────────┘ │  │                     │                        │
│                      │  │                     │                        │
│  ┌────────────────┐ │  │                     │                        │
│  │ Order Service  │◄─┼──┼─────────────────────┘                       │
│  │ • create       │ │  │                                               │
│  │ • get          │ │  │                                               │
│  │ • list         │ │  │                                               │
│  │ ↓ DynamoDB     │ │  │                                               │
│  └────────────────┘ │  │                                               │
└──────────────────────┘  └───────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    SECURITY & MONITORING LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ AWS Cognito  │  │ Secrets Mgr  │  │ CloudWatch   │  │ Resilience │ │
│  │ (Auth/JWT)   │  │ (API Keys)   │  │ (Dashboards) │  │ Patterns   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    CI/CD LAYER (6 Independent Pipelines)                 │
│  GitHub → CodePipeline → CodeBuild → Test → Approve → Deploy            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 **Service Dependencies & Deployment Order**

### **Dependency Graph**

```
┌─────────────────────────────────────────────────────────────┐
│  DEPLOYMENT ORDER (Follow this sequence!)                   │
└─────────────────────────────────────────────────────────────┘

1. Shared Infrastructure (S3 + DynamoDB for Terraform state)
   ↓
2. Product Service (Independent - no dependencies)
   ↓
3. Payment Service (Independent - no dependencies)
   ↓
4. Cart Service (Depends on: Product Service API)
   ↓
5. Order Service (Depends on: Cart, Product, Payment APIs)
   ↓
6. Shopping Agent Service (Depends on: All 4 core services)
   ↓
7. Troubleshooting Agent Service (Depends on: CloudWatch, AWS APIs)
```

**Why This Order?**
- **Product & Payment first:** No dependencies, can deploy in parallel
- **Cart second:** Needs Product API to validate items
- **Order third:** Orchestrates Cart, Product, Payment
- **Shopping Agent fourth:** Calls all core service APIs
- **Troubleshooting Agent last:** Monitors all services

**🎓 Learning Point:** This is **dependency management** in microservices. Each service must have its dependencies available before deployment.

---

## 🔧 **Prerequisites & Setup**

### **Required Tools**

Before starting, ensure you have these tools installed:

```bash
# ============================================================================
# CHECK TERRAFORM VERSION
# ============================================================================
terraform --version
# Required: v1.5.0 or higher
# Why: We use latest Terraform features (optional attributes, validation)
# Install: https://www.terraform.io/downloads

# ============================================================================
# CHECK AWS CLI VERSION
# ============================================================================
aws --version
# Required: v2.x or higher
# Why: AWS CLI v2 has better performance and features
# Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# ============================================================================
# CHECK PYTHON VERSION
# ============================================================================
python3 --version
# Required: Python 3.11 (matches Lambda runtime)
# Why: Must match AWS Lambda runtime for compatibility
# Install: https://www.python.org/downloads/

# ============================================================================
# CHECK GIT VERSION
# ============================================================================
git --version
# Required: v2.x or higher
# Why: Needed for version control and CI/CD integration
# Install: https://git-scm.com/downloads

# ============================================================================
# CHECK JQ (JSON PROCESSOR)
# ============================================================================
jq --version
# Required: v1.6 or higher
# Why: Parse JSON output from AWS CLI and Terraform
# Install: https://stedolan.github.io/jq/download/
```

### **AWS Account Setup**

```bash
# ============================================================================
# CONFIGURE AWS CREDENTIALS
# ============================================================================
# Why: AWS CLI needs credentials to interact with your AWS account
# What: Sets up access keys, region, and output format

aws configure
# Prompts:
# AWS Access Key ID: AKIA... (from IAM user)
# AWS Secret Access Key: ... (from IAM user)
# Default region name: us-east-1 (or your preferred region)
# Default output format: json

# ============================================================================
# VERIFY AWS CONFIGURATION
# ============================================================================
# Why: Confirms credentials are valid and working
# What: Calls AWS STS to get your identity

aws sts get-caller-identity
# Expected output:
# {
#     "UserId": "AIDA...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }

# ============================================================================
# EXPORT AWS ACCOUNT ID
# ============================================================================
# Why: Many Terraform configurations need your AWS account ID
# What: Stores account ID in environment variable for easy access

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Make it permanent (add to ~/.bashrc or ~/.zshrc)
echo "export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)" >> ~/.bashrc
source ~/.bashrc

# ============================================================================
# VERIFY AWS PERMISSIONS
# ============================================================================
# Why: Ensure your IAM user has necessary permissions
# What: Tests access to key AWS services

# Test Lambda access
aws lambda list-functions --max-items 1
# Should return: List of functions or empty (not AccessDenied)

# Test DynamoDB access
aws dynamodb list-tables
# Should return: List of tables or empty (not AccessDenied)

# Test S3 access
aws s3 ls
# Should return: List of buckets or empty (not AccessDenied)

# If you get "AccessDenied" errors:
# 1. Go to AWS Console → IAM → Users → Your User
# 2. Attach policy: AdministratorAccess (for learning)
# 3. Or attach specific policies: AWSLambdaFullAccess, AmazonDynamoDBFullAccess, etc.
```

### **GitHub Setup**

```bash
# ============================================================================
# CREATE GITHUB PERSONAL ACCESS TOKEN
# ============================================================================
# Why: CodePipeline needs permission to access your GitHub repository
# What: Creates a token with repo access

# Steps:
# 1. Go to GitHub → Settings → Developer settings → Personal access tokens
# 2. Click "Generate new token (classic)"
# 3. Name: "AWS CodePipeline Access"
# 4. Select scopes:
#    ✅ repo (Full control of private repositories)
#    ✅ admin:repo_hook (Full control of repository hooks)
# 5. Click "Generate token"
# 6. Copy token (shown only once!)

# ============================================================================
# EXPORT GITHUB TOKEN
# ============================================================================
# Why: Terraform needs this to configure CodePipeline
# What: Stores token in environment variable

export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# Replace with your actual token

# Verify token is set
echo $GITHUB_TOKEN | cut -c1-10
# Should show: ghp_xxxxxx

# Security: Never commit this token to Git!
# Add to .gitignore: .env, *.token

# Make it permanent (optional, but convenient)
echo "export GITHUB_TOKEN='your_token_here'" >> ~/.bashrc
source ~/.bashrc
```

### **Project Setup**

```bash
# ============================================================================
# CLONE OR CREATE PROJECT
# ============================================================================
# Why: Get the project code on your local machine
# What: Clones repository or initializes new project

# Option 1: Clone existing repository
git clone https://github.com/YOUR_USERNAME/serverless-microservices.git
cd serverless-microservices

# Option 2: Initialize new project
mkdir serverless-microservices
cd serverless-microservices
git init

# ============================================================================
# VERIFY PROJECT STRUCTURE
# ============================================================================
# Why: Ensure all required files and directories exist
# What: Lists project structure

tree -L 2
# Expected structure:
# .
# ├── cart-service/
# ├── order-service/
# ├── payment-service/
# ├── product-service/
# ├── agent-service/
# ├── troubleshooting-agent-service/
# ├── shared/
# ├── terraform/
# ├── README.md
# └── .gitignore

# ============================================================================
# INSTALL PYTHON DEPENDENCIES (FOR LOCAL TESTING)
# ============================================================================
# Why: Test Lambda functions locally before deployment
# What: Installs required Python packages

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install boto3 pytest requests strands-agents

# Verify installation
python -c "import boto3; print(boto3.__version__)"
python -c "import strands_agents; print('Strands Agents SDK installed')"
```

### **Cost Estimation & Budgets**

```bash
# ============================================================================
# SET UP AWS BUDGET ALERTS
# ============================================================================
# Why: Prevent unexpected AWS bills
# What: Creates budget with email alerts

aws budgets create-budget \
  --account-id $AWS_ACCOUNT_ID \
  --budget '{
    "BudgetName": "Monthly-Microservices-Budget",
    "BudgetLimit": {
      "Amount": "150",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{
        "SubscriptionType": "EMAIL",
        "Address": "your@email.com"
      }]
    }
  ]'

# What this does:
# - Sets monthly budget of $150
# - Sends email alert at 80% ($120)
# - Helps prevent cost overruns

# ============================================================================
# ESTIMATED MONTHLY COSTS
# ============================================================================
# Infrastructure:
# ├─ EC2 (t3.medium): $30/month (can use t3.micro: $7.50/month)
# ├─ Product Service: $3/month
# ├─ Cart Service: $3/month
# ├─ Payment Service: $3/month
# ├─ Order Service: $3/month
# ├─ Shopping Agent: $25/month (Bedrock usage)
# ├─ Troubleshooting Agent: $10/month (Bedrock + MCP)
# ├─ CodePipeline (6): $6/month
# ├─ CodeBuild: $10/month
# ├─ S3: $2/month
# ├─ DynamoDB: $6/month
# ├─ CloudWatch: $5/month
# └─ Secrets Manager: $2/month
#
# TOTAL: ~$110/month
#
# Cost Optimization:
# - Use t3.micro EC2: Save $22/month
# - Use Claude Haiku: Save $15/month
# - Delete dev environments when not in use: Save $15/month
# - Minimum cost: ~$73/month
```

---

## Step-by-Step Deployment

### Step 1: Deploy Shared Infrastructure

```bash
cd terraform/shared
terraform init
terraform apply

# Update all backend configurations with your account ID
find terraform -name "main.tf" -type f -exec sed -i '' "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" {} \;
```

### Step 2: Deploy Product Service

```bash
# Deploy dev environment
cd terraform/product-service/dev
terraform init
terraform apply

# Save API endpoint
PRODUCT_API=$(terraform output -raw api_gateway_url)
echo "Product API: $PRODUCT_API"

# Test
curl "$PRODUCT_API/products"

# Deploy prod environment
cd ../prod
terraform init
terraform apply

# Deploy pipeline
cd ../pipeline
terraform init
terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"
```

### Step 3: Deploy Payment Service

```bash
# Deploy dev environment
cd terraform/payment-service/dev
terraform init
terraform apply

# Save API endpoint
PAYMENT_API=$(terraform output -raw api_gateway_url)
echo "Payment API: $PAYMENT_API"

# Deploy prod environment
cd ../prod
terraform init
terraform apply

# Deploy pipeline
cd ../pipeline
terraform init
terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"
```

### Step 4: Deploy Cart Service

```bash
# Deploy dev environment
cd terraform/cart-service/dev
terraform init
terraform apply

# Save API endpoint
CART_API=$(terraform output -raw api_gateway_url)
echo "Cart API: $CART_API"

# Test
curl -X POST "$CART_API/cart/add" \
  -H "Content-Type: application/json" \
  -d '{"userId":"user1","productId":"prod1","quantity":2}'

# Deploy prod environment
cd ../prod
terraform init
terraform apply

# Deploy pipeline
cd ../pipeline
terraform init
terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"
```

### Step 5: Deploy Order Service

```bash
# Deploy dev environment
cd terraform/order-service/dev
terraform init
terraform apply

# Save API endpoint
ORDER_API=$(terraform output -raw api_gateway_url)
echo "Order API: $ORDER_API"

# Deploy prod environment
cd ../prod
terraform init
terraform apply

# Deploy pipeline
cd ../pipeline
terraform init
terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"
```

### Step 6: Deploy Shopping Agent Service (AI-Powered)

```bash
# ============================================================================
# BUILD AGENT SERVICE PACKAGE
# ============================================================================
# Why: Lambda needs deployment package with code + dependencies
# What: Creates ZIP file with Python code and libraries

cd agent-service

# Install dependencies to package directory
pip install -r requirements.txt -t package/

# Copy source code
cp -r src/agent_handler package/

# Create deployment package
cd package
zip -r ../agent-service.zip .
cd ..

echo "Package created: agent-service.zip"
ls -lh agent-service.zip

# ============================================================================
# DEPLOY DEV ENVIRONMENT
# ============================================================================
# Why: Test AI agent in isolated dev environment first
# What: Creates Lambda, API Gateway, IAM roles for agent

cd ../terraform/agent-service/dev
terraform init

# Apply with service endpoints
terraform apply \
  -var="product_api_url=$PRODUCT_API" \
  -var="cart_api_url=$CART_API" \
  -var="order_api_url=$ORDER_API" \
  -var="payment_api_url=$PAYMENT_API"

# Save agent API endpoint
AGENT_API=$(terraform output -raw api_gateway_url)
echo "Agent API: $AGENT_API"

# ============================================================================
# TEST SHOPPING AGENT
# ============================================================================
# Why: Verify AI agent can understand natural language and call tools
# What: Sends conversational requests to agent

# Test 1: Product search
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to buy a laptop under $1000",
    "userId": "user123"
  }'

# Expected: Agent searches products, filters by price, returns recommendations

# Test 2: Add to cart
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Add the Dell XPS 13 to my cart",
    "userId": "user123",
    "conversationId": "conv-123"
  }'

# Expected: Agent adds product to cart, confirms action

# Test 3: Checkout
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to checkout and pay with credit card",
    "userId": "user123",
    "conversationId": "conv-123"
  }'

# Expected: Agent creates order, processes payment, returns order details

# ============================================================================
# MONITOR AGENT PERFORMANCE
# ============================================================================
# Why: Track AI agent usage, costs, and errors
# What: Views CloudWatch logs and metrics

# View agent logs
aws logs tail /aws/lambda/agent-service-dev --follow

# Check Bedrock usage (cost monitoring)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name InvocationCount \
  --dimensions Name=ModelId,Value=anthropic.claude-3-sonnet-20240229-v1:0 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum

# ============================================================================
# DEPLOY PROD ENVIRONMENT
# ============================================================================
# Why: Production deployment with enhanced monitoring and DLQ
# What: Creates prod Lambda with alarms, DLQ, SNS alerts

cd ../prod
terraform init

terraform apply \
  -var="product_api_url=$PRODUCT_API_PROD" \
  -var="cart_api_url=$CART_API_PROD" \
  -var="order_api_url=$ORDER_API_PROD" \
  -var="payment_api_url=$PAYMENT_API_PROD" \
  -var="alert_email=your@email.com"

# ============================================================================
# DEPLOY CI/CD PIPELINE
# ============================================================================
# Why: Automate testing and deployment of agent updates
# What: Creates CodePipeline with GitHub integration

cd ../pipeline
terraform init

terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"

# Verify pipeline
aws codepipeline get-pipeline-state \
  --name agent-service-pipeline \
  --query 'stageStates[*].[stageName,latestExecution.status]' \
  --output table

echo "✅ Shopping Agent Service deployed successfully!"
```

### Step 7: Deploy MCP Server (Unified Observability)

```bash
# ============================================================================
# BUILD MCP SERVER PACKAGE
# ============================================================================
# Why: MCP server provides observability tools for troubleshooting agent
# What: Creates deployment package with MCP SDK and AWS clients

cd mcp-servers/aws-observability

# Install dependencies to package directory
pip install -r requirements.txt -t package/

# Copy server code
cp server.py package/

# Create deployment package
cd package
zip -r ../aws-observability-mcp.zip .
cd ..

echo "Package created: aws-observability-mcp.zip"
ls -lh aws-observability-mcp.zip

# ============================================================================
# DEPLOY MCP SERVER
# ============================================================================
# Why: Provides 11 observability tools (Logs, Metrics, AWS Services)
# What: Creates Lambda + API Gateway for MCP protocol

cd ../../terraform/mcp-servers
terraform init

terraform apply -var="environment=dev"

# Save MCP server URL
MCP_URL=$(terraform output -raw aws_observability_mcp_url)
echo "MCP Server URL: $MCP_URL"

# ============================================================================
# TEST MCP SERVER TOOLS
# ============================================================================
# Why: Verify all 11 tools are working correctly
# What: Tests each tool category (Logs, Metrics, Services)

# Test 1: List services
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "list_services",
    "arguments": {}
  }'

# Expected: Returns list of all Lambda functions

# Test 2: Check service health
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "check_service_health",
    "arguments": {
      "service": "cart-service-dev"
    }
  }'

# Expected: Returns error rate, duration, throttles

# Test 3: Query logs
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "query_logs",
    "arguments": {
      "log_group": "/aws/lambda/cart-service-dev",
      "query": "fields @timestamp, @message | filter @message like /ERROR/",
      "start_time": "-1h",
      "limit": 10
    }
  }'

# Expected: Returns recent error logs

# Test 4: Get Lambda function details
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "get_lambda_function",
    "arguments": {
      "function_name": "cart-service-dev"
    }
  }'

# Expected: Returns Lambda configuration (memory, timeout, runtime)

# Test 5: Get DynamoDB table details
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "tool": "get_dynamodb_table",
    "arguments": {
      "table_name": "carts-dev"
    }
  }'

# Expected: Returns table status, item count, size

# ============================================================================
# MONITOR MCP SERVER
# ============================================================================
# Why: Ensure MCP server is performing well
# What: Views logs and metrics

# View MCP server logs
aws logs tail /aws/lambda/aws-observability-mcp-dev --follow

# Check MCP server metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=aws-observability-mcp-dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# ============================================================================
# DEPLOY TO PROD
# ============================================================================
# Why: Production MCP server for prod troubleshooting agent
# What: Creates prod Lambda with enhanced monitoring

terraform apply -var="environment=prod"

MCP_URL_PROD=$(terraform output -raw aws_observability_mcp_url)
echo "MCP Server URL (Prod): $MCP_URL_PROD"

echo "✅ MCP Server deployed successfully!"
echo "📊 11 tools available: 4 Logs + 3 Metrics + 4 Services"
```

### Step 8: Deploy Troubleshooting Agent Service (DevOps AI)

```bash
# ============================================================================
# BUILD TROUBLESHOOTING AGENT PACKAGE
# ============================================================================
# Why: AI agent for DevOps troubleshooting using MCP tools
# What: Creates deployment package with Strands SDK and MCP client

cd troubleshooting-agent-service

# Install dependencies to package directory
pip install -r requirements.txt -t package/

# Copy source code
cp -r src/troubleshooting_handler package/

# Create deployment package
cd package
zip -r ../troubleshooting-agent.zip .
cd ..

echo "Package created: troubleshooting-agent.zip"
ls -lh troubleshooting-agent.zip

# ============================================================================
# DEPLOY DEV ENVIRONMENT
# ============================================================================
# Why: Test troubleshooting agent in dev environment
# What: Creates Lambda with MCP client integration

cd ../terraform/troubleshooting-agent-service/dev
terraform init

terraform apply \
  -var="aws_observability_mcp_url=$MCP_URL"

# Save troubleshooting agent API endpoint
TROUBLESHOOT_API=$(terraform output -raw api_gateway_url)
echo "Troubleshooting Agent API: $TROUBLESHOOT_API"

# ============================================================================
# TEST TROUBLESHOOTING AGENT
# ============================================================================
# Why: Verify AI can diagnose issues using MCP tools
# What: Sends troubleshooting questions to agent

# Test 1: Check service health
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Is the cart service healthy?",
    "service": "cart-service-dev",
    "timeRange": "1h"
  }'

# Expected: Agent uses check_service_health tool, returns analysis

# Test 2: Find errors
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Why is the cart service failing?",
    "service": "cart-service-dev",
    "timeRange": "1h"
  }'

# Expected: Agent queries logs, finds errors, suggests fixes

# Test 3: Performance analysis
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Why is the order service slow?",
    "service": "order-service-dev",
    "timeRange": "24h"
  }'

# Expected: Agent checks metrics, identifies bottlenecks

# Test 4: Configuration check
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the Lambda configuration for cart service?",
    "service": "cart-service-dev"
  }'

# Expected: Agent uses get_lambda_function tool, returns config

# Test 5: Pipeline status
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Did the last deployment succeed?",
    "service": "cart-service"
  }'

# Expected: Agent checks pipeline execution, returns status

# ============================================================================
# MONITOR TROUBLESHOOTING AGENT
# ============================================================================
# Why: Track agent usage and MCP tool calls
# What: Views logs showing which tools were used

# View agent logs (shows MCP tool usage)
aws logs tail /aws/lambda/troubleshooting-agent-service-dev --follow

# Check which MCP tools are being used most
aws logs filter-log-events \
  --log-group-name /aws/lambda/troubleshooting-agent-service-dev \
  --filter-pattern "MCP tools used" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# ============================================================================
# DEPLOY PROD ENVIRONMENT
# ============================================================================
# Why: Production troubleshooting agent for ops team
# What: Creates prod Lambda with enhanced monitoring

cd ../prod
terraform init

terraform apply \
  -var="aws_observability_mcp_url=$MCP_URL_PROD" \
  -var="alert_email=your@email.com"

# ============================================================================
# DEPLOY CI/CD PIPELINE
# ============================================================================
# Why: Automate deployment of agent updates
# What: Creates CodePipeline with GitHub integration

cd ../pipeline
terraform init

terraform apply \
  -var="github_owner=YOUR_USERNAME" \
  -var="github_token=$GITHUB_TOKEN" \
  -var="approval_email=your@email.com"

# Verify pipeline
aws codepipeline get-pipeline-state \
  --name troubleshooting-agent-service-pipeline \
  --query 'stageStates[*].[stageName,latestExecution.status]' \
  --output table

echo "✅ Troubleshooting Agent Service deployed successfully!"
echo "🤖 AI-powered DevOps troubleshooting is now available!"
```

## End-to-End Testing

### Test Suite 1: Core Microservices Flow

#### 1. Add Product (Admin Operation)
```bash
# ============================================================================
# CREATE PRODUCT
# ============================================================================
# Why: Populate product catalog for testing
# What: Creates a new product in DynamoDB

curl -X POST "$PRODUCT_API/products" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Wireless Headphones",
    "description": "Premium noise-cancelling headphones",
    "price": 199.99,
    "category": "electronics",
    "stock": 50
  }'

# Expected response:
# {
#   "productId": "prod-abc123",
#   "name": "Wireless Headphones",
#   "price": 199.99,
#   "stock": 50
# }

# Save product ID for next steps
PRODUCT_ID="prod-abc123"  # Replace with actual ID from response
```

#### 2. List Products
```bash
# ============================================================================
# LIST ALL PRODUCTS
# ============================================================================
# Why: Verify product was created and is visible
# What: Retrieves all products from catalog

curl "$PRODUCT_API/products"

# Expected response:
# {
#   "products": [
#     {
#       "productId": "prod-abc123",
#       "name": "Wireless Headphones",
#       "price": 199.99,
#       "stock": 50
#     }
#   ],
#   "count": 1
# }
```

#### 3. Add Items to Cart
```bash
# ============================================================================
# ADD FIRST ITEM TO CART
# ============================================================================
# Why: Test cart service integration with product service
# What: Adds product to user's cart, validates product exists

curl -X POST "$CART_API/cart/add" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "productId": "'$PRODUCT_ID'",
    "quantity": 2
  }'

# Expected response:
# {
#   "success": true,
#   "cartId": "cart-user123",
#   "itemsCount": 1,
#   "totalAmount": 399.98
# }

# ============================================================================
# ADD SECOND ITEM TO CART
# ============================================================================
# Create another product first
curl -X POST "$PRODUCT_API/products" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop Stand",
    "description": "Ergonomic aluminum laptop stand",
    "price": 49.99,
    "category": "accessories",
    "stock": 100
  }'

PRODUCT_ID_2="prod-xyz789"  # Replace with actual ID

# Add to cart
curl -X POST "$CART_API/cart/add" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "productId": "'$PRODUCT_ID_2'",
    "quantity": 1
  }'

# Expected response:
# {
#   "success": true,
#   "cartId": "cart-user123",
#   "itemsCount": 2,
#   "totalAmount": 449.97
# }
```

#### 4. View Cart
```bash
# ============================================================================
# GET CART CONTENTS
# ============================================================================
# Why: Verify all items are in cart with correct quantities
# What: Retrieves user's cart from DynamoDB

curl "$CART_API/cart/user123"

# Expected response:
# {
#   "cartId": "cart-user123",
#   "userId": "user123",
#   "items": [
#     {
#       "productId": "prod-abc123",
#       "name": "Wireless Headphones",
#       "price": 199.99,
#       "quantity": 2,
#       "subtotal": 399.98
#     },
#     {
#       "productId": "prod-xyz789",
#       "name": "Laptop Stand",
#       "price": 49.99,
#       "quantity": 1,
#       "subtotal": 49.99
#     }
#   ],
#   "totalAmount": 449.97,
#   "itemsCount": 2
# }
```

#### 5. Create Order (Checkout)
```bash
# ============================================================================
# CHECKOUT AND CREATE ORDER
# ============================================================================
# Why: Test order orchestration across multiple services
# What: Order service calls Cart, Product, Payment services

curl -X POST "$ORDER_API/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "shippingAddress": {
      "street": "123 Main St",
      "city": "Seattle",
      "state": "WA",
      "zip": "98101",
      "country": "USA"
    },
    "paymentMethod": "CARD"
  }'

# Expected response:
# {
#   "orderId": "order-def456",
#   "userId": "user123",
#   "status": "CONFIRMED",
#   "items": [...],
#   "totalAmount": 449.97,
#   "paymentId": "pay-ghi789",
#   "paymentStatus": "COMPLETED",
#   "createdAt": "2026-02-05T22:30:00Z"
# }

# Save order ID for next steps
ORDER_ID="order-def456"  # Replace with actual ID
PAYMENT_ID="pay-ghi789"  # Replace with actual ID
```

#### 6. View Order
```bash
# ============================================================================
# GET ORDER DETAILS
# ============================================================================
# Why: Verify order was created with all details
# What: Retrieves order from DynamoDB

curl "$ORDER_API/orders/$ORDER_ID"

# Expected response:
# {
#   "orderId": "order-def456",
#   "userId": "user123",
#   "status": "CONFIRMED",
#   "items": [
#     {
#       "productId": "prod-abc123",
#       "name": "Wireless Headphones",
#       "price": 199.99,
#       "quantity": 2
#     },
#     {
#       "productId": "prod-xyz789",
#       "name": "Laptop Stand",
#       "price": 49.99,
#       "quantity": 1
#     }
#   ],
#   "totalAmount": 449.97,
#   "shippingAddress": {...},
#   "paymentId": "pay-ghi789",
#   "createdAt": "2026-02-05T22:30:00Z"
# }
```

#### 7. View User Orders
```bash
# ============================================================================
# LIST USER'S ORDER HISTORY
# ============================================================================
# Why: Verify user can see all their orders
# What: Queries orders by userId

curl "$ORDER_API/orders/user/user123"

# Expected response:
# {
#   "orders": [
#     {
#       "orderId": "order-def456",
#       "status": "CONFIRMED",
#       "totalAmount": 449.97,
#       "createdAt": "2026-02-05T22:30:00Z"
#     }
#   ],
#   "count": 1
# }
```

#### 8. View Payment
```bash
# ============================================================================
# GET PAYMENT DETAILS
# ============================================================================
# Why: Verify payment was processed successfully
# What: Retrieves payment record from DynamoDB

curl "$PAYMENT_API/payments/$PAYMENT_ID"

# Expected response:
# {
#   "paymentId": "pay-ghi789",
#   "orderId": "order-def456",
#   "userId": "user123",
#   "amount": 449.97,
#   "status": "COMPLETED",
#   "paymentMethod": "CARD",
#   "processedAt": "2026-02-05T22:30:00Z"
# }
```

### Test Suite 2: AI Shopping Agent

#### 1. Natural Language Product Search
```bash
# ============================================================================
# TEST: AI PRODUCT SEARCH
# ============================================================================
# Why: Verify agent can understand natural language and search products
# What: Agent uses search_products tool

curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to buy wireless headphones under $200",
    "userId": "user456"
  }'

# Expected response:
# {
#   "response": "I found some great wireless headphones for you! The Premium Noise-Cancelling Headphones are available for $199.99. They have excellent reviews and are in stock. Would you like me to add them to your cart?",
#   "toolsUsed": ["search_products"],
#   "conversationId": "conv-abc123"
# }
```

#### 2. Add to Cart via Conversation
```bash
# ============================================================================
# TEST: AI ADD TO CART
# ============================================================================
# Why: Verify agent can add products to cart conversationally
# What: Agent uses add_to_cart tool

curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Yes, add them to my cart",
    "userId": "user456",
    "conversationId": "conv-abc123"
  }'

# Expected response:
# {
#   "response": "Great! I'\''ve added the Premium Noise-Cancelling Headphones to your cart. Your cart now has 1 item totaling $199.99. Would you like to continue shopping or proceed to checkout?",
#   "toolsUsed": ["add_to_cart", "get_cart"],
#   "conversationId": "conv-abc123"
# }
```

#### 3. Checkout via Conversation
```bash
# ============================================================================
# TEST: AI CHECKOUT
# ============================================================================
# Why: Verify agent can orchestrate checkout process
# What: Agent uses create_order and process_payment tools

curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to checkout. Ship to 123 Main St, Seattle, WA 98101. Pay with credit card.",
    "userId": "user456",
    "conversationId": "conv-abc123"
  }'

# Expected response:
# {
#   "response": "Perfect! I'\''ve processed your order. Your order #order-xyz123 has been confirmed and payment of $199.99 has been processed. Your items will be shipped to 123 Main St, Seattle, WA 98101. You should receive a confirmation email shortly. Is there anything else I can help you with?",
#   "toolsUsed": ["create_order", "process_payment"],
#   "conversationId": "conv-abc123",
#   "orderId": "order-xyz123"
# }
```

### Test Suite 3: AI Troubleshooting Agent

#### 1. Service Health Check
```bash
# ============================================================================
# TEST: AI HEALTH CHECK
# ============================================================================
# Why: Verify agent can diagnose service health
# What: Agent uses check_service_health MCP tool

curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Is the cart service healthy?",
    "service": "cart-service-dev",
    "timeRange": "1h"
  }'

# Expected response:
# {
#   "answer": "The cart service is healthy. In the last hour:\n- Error rate: 0%\n- Average duration: 245ms\n- No throttling\n- All alarms are in OK state\n\nThe service is performing normally.",
#   "toolsUsed": ["check_service_health", "get_alarms"],
#   "service": "cart-service-dev"
# }
```

#### 2. Error Investigation
```bash
# ============================================================================
# TEST: AI ERROR DIAGNOSIS
# ============================================================================
# Why: Verify agent can find and analyze errors
# What: Agent uses search_errors and query_logs MCP tools

curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Why is the cart service failing?",
    "service": "cart-service-dev",
    "timeRange": "1h"
  }'

# Expected response:
# {
#   "answer": "I found 3 errors in the cart service logs:\n\n1. DynamoDB ProvisionedThroughputExceededException (2 occurrences)\n   - Root cause: Write capacity exceeded\n   - Recommendation: Increase DynamoDB write capacity or enable auto-scaling\n   - Cost impact: ~$5/month for 5 additional WCUs\n\n2. Lambda timeout (1 occurrence)\n   - Root cause: Slow DynamoDB query\n   - Recommendation: Add GSI for userId queries\n   - Impact: Reduces query time from 2s to 50ms\n\nImmediate action: Enable DynamoDB auto-scaling to prevent future throttling.",
#   "toolsUsed": ["search_errors", "query_logs", "get_dynamodb_table"],
#   "service": "cart-service-dev"
# }
```

#### 3. Performance Analysis
```bash
# ============================================================================
# TEST: AI PERFORMANCE DIAGNOSIS
# ============================================================================
# Why: Verify agent can identify performance bottlenecks
# What: Agent uses get_metrics MCP tool

curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Why is the order service slow?",
    "service": "order-service-dev",
    "timeRange": "24h"
  }'

# Expected response:
# {
#   "answer": "The order service is experiencing high latency:\n\n- Average duration: 3.2 seconds (normal: <1s)\n- P99 duration: 8.5 seconds\n- No errors or throttling\n\nRoot cause analysis:\n1. Multiple synchronous API calls (Cart, Product, Payment)\n2. No caching of product data\n3. Sequential processing instead of parallel\n\nRecommendations:\n1. Implement parallel API calls using asyncio (reduces latency by 60%)\n2. Add ElastiCache for product data (saves 200ms per request)\n3. Use Step Functions for order orchestration (better visibility)\n\nEstimated improvement: 3.2s → 1.2s average duration",
#   "toolsUsed": ["get_metrics", "get_lambda_function", "query_logs"],
#   "service": "order-service-dev"
# }
```

#### 4. Configuration Check
```bash
# ============================================================================
# TEST: AI CONFIGURATION REVIEW
# ============================================================================
# Why: Verify agent can review service configurations
# What: Agent uses get_lambda_function and get_dynamodb_table MCP tools

curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Review the configuration of cart service",
    "service": "cart-service-dev"
  }'

# Expected response:
# {
#   "answer": "Cart Service Configuration Review:\n\nLambda Configuration:\n- Runtime: Python 3.11 ✅\n- Memory: 256 MB ✅\n- Timeout: 30 seconds ✅\n- Environment variables: 5 configured ✅\n\nDynamoDB Configuration:\n- Table: carts-dev\n- Billing mode: PAY_PER_REQUEST ✅\n- Item count: 1,247\n- Table size: 2.3 MB\n- GSI: userId-index ✅\n\nRecommendations:\n- Consider increasing Lambda memory to 512 MB for better performance\n- Enable DynamoDB point-in-time recovery for prod\n- Add TTL attribute for automatic cart cleanup after 30 days",
#   "toolsUsed": ["get_lambda_function", "get_dynamodb_table"],
#   "service": "cart-service-dev"
# }
```

#### 5. Deployment Status Check
```bash
# ============================================================================
# TEST: AI DEPLOYMENT VERIFICATION
# ============================================================================
# Why: Verify agent can check deployment status
# What: Agent uses get_pipeline_execution MCP tool

curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Did the last deployment of cart service succeed?",
    "service": "cart-service"
  }'

# Expected response:
# {
#   "answer": "Last deployment status for cart-service:\n\nPipeline: cart-service-pipeline\nExecution ID: abc-123-def\nStatus: Succeeded ✅\nStarted: 2026-02-05 20:15:00 UTC\nCompleted: 2026-02-05 20:22:00 UTC\nDuration: 7 minutes\n\nStages:\n1. Source: Succeeded (GitHub webhook)\n2. Build: Succeeded (CodeBuild)\n3. Test: Succeeded (Unit + Integration tests)\n4. Deploy-Dev: Succeeded\n5. Approval: Approved by john@example.com\n6. Deploy-Prod: Succeeded\n\nThe deployment completed successfully with no issues.",
#   "toolsUsed": ["get_pipeline_execution"],
#   "service": "cart-service"
# }
```

## Service Communication Flow

```
1. User adds items to cart
   Frontend → Cart Service → Product Service (validate)
   
2. User views cart
   Frontend → Cart Service
   
3. User checks out
   Frontend → Order Service
   Order Service → Cart Service (get items)
   Order Service → Product Service (validate inventory)
   Order Service → Payment Service (process payment)
   Order Service → Cart Service (clear cart)
   Order Service → EventBridge (publish OrderCreated event)
   
4. User views order history
   Frontend → Order Service
```

## Monitoring All Services

### CloudWatch Logs
```bash
# Product Service
aws logs tail /aws/lambda/product-service-get-dev --follow

# Cart Service
aws logs tail /aws/lambda/cart-service-add-dev --follow

# Payment Service
aws logs tail /aws/lambda/payment-service-process-dev --follow

# Order Service
aws logs tail /aws/lambda/order-service-create-dev --follow
```

### CloudWatch Metrics Dashboard
```bash
# Create unified dashboard
aws cloudwatch put-dashboard \
  --dashboard-name microservices-dashboard \
  --dashboard-body file://dashboard.json
```

### X-Ray Service Map
```bash
# View in AWS Console
# X-Ray → Service Map
# Shows all service interactions
```

## CI/CD Pipeline Status

```bash
# Check all pipelines
for service in product cart payment order; do
  echo "=== ${service}-service-pipeline ==="
  aws codepipeline get-pipeline-state \
    --name ${service}-service-pipeline \
    --query 'stageStates[*].[stageName,latestExecution.status]' \
    --output table
done
```

## Cost Estimation & Monitoring

### Detailed Monthly Cost Breakdown

#### Core Microservices (4 services × 2 environments)
```
Product Service:
├─ Lambda (dev):     $0.20/month (free tier)
├─ Lambda (prod):    $1.00/month
├─ DynamoDB (dev):   $0.25/month (free tier)
├─ DynamoDB (prod):  $2.50/month
├─ API Gateway:      $3.50/month (1M requests)
└─ CloudWatch:       $0.50/month
Total: ~$8/month per service × 4 = $32/month

Cart Service:        $8/month
Payment Service:     $8/month
Order Service:       $8/month
Product Service:     $8/month
```

#### AI Services
```
Shopping Agent Service:
├─ Lambda:           $2/month
├─ Bedrock (Claude Sonnet): $20/month (10K requests)
│  └─ Input tokens:  $3/1M tokens
│  └─ Output tokens: $15/1M tokens
├─ API Gateway:      $3.50/month
└─ CloudWatch:       $1/month
Total: ~$26.50/month

Troubleshooting Agent Service:
├─ Lambda:           $1/month
├─ Bedrock (Claude Sonnet): $8/month (3K requests)
├─ API Gateway:      $1/month
└─ CloudWatch:       $0.50/month
Total: ~$10.50/month

MCP Server (Unified):
├─ Lambda:           $2/month
├─ API Gateway:      $1/month
└─ CloudWatch:       $1/month
Total: ~$4/month
```

#### CI/CD Infrastructure
```
CodePipeline (6 pipelines):
├─ Product:          $1/month
├─ Cart:             $1/month
├─ Payment:          $1/month
├─ Order:            $1/month
├─ Agent:            $1/month
└─ Troubleshooting:  $1/month
Total: $6/month

CodeBuild (6 projects):
├─ Build minutes:    ~300 min/month
├─ Cost:             $0.005/min
└─ Total:            $1.50/month

S3 (Artifacts):      $1/month
```

#### Shared Infrastructure
```
Terraform State:
├─ S3:               $0.50/month
└─ DynamoDB:         $0.25/month (free tier)

Secrets Manager:     $2/month (4 secrets)
CloudWatch Dashboards: $3/month
X-Ray:               $1/month
```

#### **TOTAL MONTHLY COST: ~$110/month**

### Cost Optimization Strategies

#### Strategy 1: Use Cheaper AI Models (Save $15/month)
```bash
# Replace Claude Sonnet with Claude Haiku
# Edit agent-service/src/agent_handler/app.py

# Before:
model="anthropic.claude-3-sonnet-20240229-v1:0"  # $3/$15 per 1M tokens

# After:
model="anthropic.claude-3-haiku-20240307-v1:0"   # $0.25/$1.25 per 1M tokens

# Savings: ~$15/month (75% reduction in AI costs)
```

#### Strategy 2: Delete Dev Environments When Not In Use (Save $20/month)
```bash
# Delete all dev environments
for service in product cart payment order agent troubleshooting; do
  cd terraform/${service}-service/dev
  terraform destroy -auto-approve
  cd ../../..
done

# Recreate when needed (takes 5 minutes)
cd terraform/cart-service/dev
terraform apply -auto-approve

# Savings: ~$20/month when dev is down
```

#### Strategy 3: Use Reserved Capacity (Save $10/month)
```bash
# For predictable workloads, use DynamoDB reserved capacity
aws dynamodb purchase-reserved-capacity-offerings \
  --reserved-capacity-offerings-id abc-123 \
  --reserved-capacity-units 10

# Savings: ~40% on DynamoDB costs = $10/month
```

#### Strategy 4: Reduce Log Retention (Save $2/month)
```bash
# Reduce CloudWatch log retention from 7 days to 3 days
for log_group in $(aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text); do
  aws logs put-retention-policy \
    --log-group-name $log_group \
    --retention-in-days 3
done

# Savings: ~$2/month
```

#### **Optimized Monthly Cost: ~$73/month**

### Cost Monitoring Setup

#### 1. Set Up Budget Alerts
```bash
# Create monthly budget with alerts
aws budgets create-budget \
  --account-id $AWS_ACCOUNT_ID \
  --budget '{
    "BudgetName": "Microservices-Monthly-Budget",
    "BudgetLimit": {
      "Amount": "150",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "TagKeyValue": ["Project$serverless-microservices"]
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 50,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{
        "SubscriptionType": "EMAIL",
        "Address": "your@email.com"
      }]
    },
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{
        "SubscriptionType": "EMAIL",
        "Address": "your@email.com"
      }]
    },
    {
      "Notification": {
        "NotificationType": "FORECASTED",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{
        "SubscriptionType": "EMAIL",
        "Address": "your@email.com"
      }]
    }
  ]'

# Alerts at:
# - 50% ($75) - Warning
# - 80% ($120) - Critical
# - 100% forecast - Projected overage
```

#### 2. Daily Cost Report
```bash
# Create script to check daily costs
cat > check-costs.sh << 'EOF'
#!/bin/bash

# Get yesterday's cost
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 day ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output table

# Get month-to-date cost
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --output table

# Get cost forecast
aws ce get-cost-forecast \
  --time-period Start=$(date +%Y-%m-%d),End=$(date -d '+1 month' +%Y-%m-%d) \
  --metric BLENDED_COST \
  --granularity MONTHLY \
  --output table
EOF

chmod +x check-costs.sh
./check-costs.sh
```

#### 3. Service-Specific Cost Tracking
```bash
# Track Lambda costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["AWS Lambda"]
    }
  }' \
  --group-by Type=DIMENSION,Key=USAGE_TYPE

# Track Bedrock costs (AI)
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon Bedrock"]
    }
  }'

# Track DynamoDB costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter '{
    "Dimensions": {
      "Key": "SERVICE",
      "Values": ["Amazon DynamoDB"]
    }
  }'
```

### Monitoring Dashboard

#### Create Unified CloudWatch Dashboard
```bash
# Create dashboard JSON
cat > dashboard.json << 'EOF'
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Invocations", {"stat": "Sum"}],
          [".", "Errors", {"stat": "Sum"}],
          [".", "Duration", {"stat": "Average"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Lambda Overview"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/DynamoDB", "ConsumedReadCapacityUnits", {"stat": "Sum"}],
          [".", "ConsumedWriteCapacityUnits", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "DynamoDB Capacity"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApiGateway", "Count", {"stat": "Sum"}],
          [".", "4XXError", {"stat": "Sum"}],
          [".", "5XXError", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "API Gateway"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Bedrock", "InvocationCount", {"stat": "Sum"}],
          [".", "InvocationLatency", {"stat": "Average"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "AI Agent Usage"
      }
    }
  ]
}
EOF

# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name serverless-microservices \
  --dashboard-body file://dashboard.json

# View dashboard
echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=serverless-microservices"
```

#### Set Up CloudWatch Alarms
```bash
# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name high-error-rate \
  --alarm-description "Alert when error rate exceeds 1%" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:$AWS_ACCOUNT_ID:alerts

# High latency alarm
aws cloudwatch put-metric-alarm \
  --alarm-name high-latency \
  --alarm-description "Alert when latency exceeds 3 seconds" \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 3000 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:$AWS_ACCOUNT_ID:alerts

# DynamoDB throttling alarm
aws cloudwatch put-metric-alarm \
  --alarm-name dynamodb-throttling \
  --alarm-description "Alert when DynamoDB is throttling" \
  --metric-name UserErrors \
  --namespace AWS/DynamoDB \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:$AWS_ACCOUNT_ID:alerts
```

## Troubleshooting Common Issues

### Issue 1: Terraform State Lock

**Symptom:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc-123-def
  Path:      terraform-state-ACCOUNT_ID/...
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.5.0
  Created:   2026-02-05 20:15:00 UTC
```

**Root Cause:** Previous Terraform operation didn't release lock (crashed, interrupted, etc.)

**Solution:**
```bash
# Option 1: Wait for lock to expire (usually 15 minutes)
# Check lock status
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "terraform-state-ACCOUNT_ID/cart-service/dev/terraform.tfstate-md5"}}'

# Option 2: Force unlock (use with caution!)
terraform force-unlock abc-123-def

# Option 3: Manual DynamoDB cleanup (last resort)
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "terraform-state-ACCOUNT_ID/cart-service/dev/terraform.tfstate-md5"}}'
```

**Prevention:**
- Always use `terraform apply` with proper error handling
- Don't interrupt Terraform operations
- Use remote state locking properly

---

### Issue 2: Order Service Can't Reach Cart Service

**Symptom:**
```
Error: Unable to connect to cart service
ConnectionError: HTTPSConnectionPool(host='cart-api.execute-api.us-east-1.amazonaws.com', port=443)
```

**Root Cause:** Cart Service API endpoint not configured in Order Service environment variables

**Diagnosis:**
```bash
# Check Order Service environment variables
aws lambda get-function-configuration \
  --function-name order-service-create-dev \
  --query 'Environment.Variables' \
  --output json

# Expected: Should have CART_API_URL variable
# {
#   "CART_API_URL": "https://abc123.execute-api.us-east-1.amazonaws.com",
#   "PRODUCT_API_URL": "...",
#   "PAYMENT_API_URL": "..."
# }
```

**Solution:**
```bash
# Option 1: Update via Terraform (recommended)
cd terraform/order-service/dev
terraform apply \
  -var="cart_api_url=$CART_API"

# Option 2: Update directly (quick fix)
aws lambda update-function-configuration \
  --function-name order-service-create-dev \
  --environment "Variables={CART_API_URL=$CART_API,PRODUCT_API_URL=$PRODUCT_API,PAYMENT_API_URL=$PAYMENT_API}"

# Verify update
aws lambda get-function-configuration \
  --function-name order-service-create-dev \
  --query 'Environment.Variables.CART_API_URL'
```

**Test Fix:**
```bash
# Test order creation
curl -X POST "$ORDER_API/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "shippingAddress": {"street": "123 Main St", "city": "Seattle", "state": "WA", "zip": "98101"},
    "paymentMethod": "CARD"
  }'
```

---

### Issue 3: Payment Processing Fails

**Symptom:**
```
{
  "error": "payment_failed",
  "message": "Unable to process payment"
}
```

**Root Cause:** Payment service can't access Secrets Manager for API keys

**Diagnosis:**
```bash
# Check payment service logs
aws logs tail /aws/lambda/payment-service-process-dev --follow

# Look for errors like:
# "AccessDeniedException: User is not authorized to perform: secretsmanager:GetSecretValue"

# Check IAM role permissions
ROLE_ARN=$(aws lambda get-function \
  --function-name payment-service-process-dev \
  --query 'Configuration.Role' \
  --output text)

ROLE_NAME=$(echo $ROLE_ARN | cut -d'/' -f2)

aws iam list-attached-role-policies --role-name $ROLE_NAME
```

**Solution:**
```bash
# Add Secrets Manager permissions to Lambda role
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite

# Or use Terraform (recommended)
cd terraform/payment-service/dev
terraform apply  # Will add missing permissions
```

**Test Fix:**
```bash
# Test payment processing
curl -X POST "$PAYMENT_API/payments" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "test-order",
    "userId": "test-user",
    "amount": 100.00,
    "paymentMethod": "CARD"
  }'
```

---

### Issue 4: Lambda Timeout

**Symptom:**
```
{
  "errorType": "Task timed out after 3.00 seconds"
}
```

**Root Cause:** Lambda function exceeds configured timeout (default: 3 seconds)

**Diagnosis:**
```bash
# Check Lambda timeout configuration
aws lambda get-function-configuration \
  --function-name cart-service-add-dev \
  --query 'Timeout'

# Check average duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=cart-service-add-dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

**Solution:**
```bash
# Option 1: Increase timeout via Terraform (recommended)
# Edit terraform/cart-service/dev/main.tf
# Change: timeout = 30  # seconds

cd terraform/cart-service/dev
terraform apply

# Option 2: Increase timeout directly (quick fix)
aws lambda update-function-configuration \
  --function-name cart-service-add-dev \
  --timeout 30

# Option 3: Optimize code (best long-term solution)
# - Add caching
# - Optimize database queries
# - Use connection pooling
```

---

### Issue 5: DynamoDB Throttling

**Symptom:**
```
{
  "errorType": "ProvisionedThroughputExceededException",
  "errorMessage": "The level of configured provisioned throughput for the table was exceeded"
}
```

**Root Cause:** DynamoDB write/read capacity exceeded

**Diagnosis:**
```bash
# Check DynamoDB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=carts-dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# Check table configuration
aws dynamodb describe-table \
  --table-name carts-dev \
  --query 'Table.[BillingModeSummary,ProvisionedThroughput]'
```

**Solution:**
```bash
# Option 1: Switch to on-demand billing (recommended for variable workloads)
aws dynamodb update-table \
  --table-name carts-dev \
  --billing-mode PAY_PER_REQUEST

# Option 2: Increase provisioned capacity
aws dynamodb update-table \
  --table-name carts-dev \
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10

# Option 3: Enable auto-scaling (best for predictable growth)
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/carts-dev \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 5 \
  --max-capacity 100

aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --resource-id table/carts-dev \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --policy-name WriteAutoScalingPolicy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "DynamoDBWriteCapacityUtilization"
    }
  }'
```

---

### Issue 6: Shopping Agent Returns Generic Responses

**Symptom:**
```
{
  "response": "I'm sorry, I couldn't process your request.",
  "toolsUsed": []
}
```

**Root Cause:** Agent can't access Bedrock or tool calling is failing

**Diagnosis:**
```bash
# Check agent logs
aws logs tail /aws/lambda/agent-service-dev --follow

# Look for errors like:
# "AccessDeniedException: User is not authorized to perform: bedrock:InvokeModel"
# "ToolExecutionError: Unable to call search_products"

# Check Bedrock permissions
ROLE_ARN=$(aws lambda get-function \
  --function-name agent-service-dev \
  --query 'Configuration.Role' \
  --output text)

ROLE_NAME=$(echo $ROLE_ARN | cut -d'/' -f2)

aws iam get-role-policy \
  --role-name $ROLE_NAME \
  --policy-name bedrock-access
```

**Solution:**
```bash
# Add Bedrock permissions
aws iam put-role-policy \
  --role-name $ROLE_NAME \
  --policy-name bedrock-access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
    }]
  }'

# Verify tool endpoints are configured
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables' | jq '.PRODUCT_API_URL, .CART_API_URL, .ORDER_API_URL, .PAYMENT_API_URL'
```

**Test Fix:**
```bash
# Test agent with simple query
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me all products",
    "userId": "test-user"
  }'
```

---

### Issue 7: Troubleshooting Agent Can't Access MCP Server

**Symptom:**
```
{
  "error": "mcp_connection_error",
  "message": "Unable to connect to MCP server"
}
```

**Root Cause:** MCP server URL not configured or MCP server not deployed

**Diagnosis:**
```bash
# Check troubleshooting agent configuration
aws lambda get-function-configuration \
  --function-name troubleshooting-agent-service-dev \
  --query 'Environment.Variables.AWS_OBSERVABILITY_MCP_URL'

# Test MCP server directly
curl -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -d '{"tool": "list_services", "arguments": {}}'

# Check MCP server logs
aws logs tail /aws/lambda/aws-observability-mcp-dev --follow
```

**Solution:**
```bash
# Deploy MCP server if not deployed
cd terraform/mcp-servers
terraform init
terraform apply -var="environment=dev"

# Get MCP URL
MCP_URL=$(terraform output -raw aws_observability_mcp_url)

# Update troubleshooting agent with MCP URL
cd ../troubleshooting-agent-service/dev
terraform apply -var="aws_observability_mcp_url=$MCP_URL"

# Or update directly
aws lambda update-function-configuration \
  --function-name troubleshooting-agent-service-dev \
  --environment "Variables={AWS_OBSERVABILITY_MCP_URL=$MCP_URL}"
```

**Test Fix:**
```bash
# Test troubleshooting agent
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "List all services",
    "timeRange": "1h"
  }'
```

---

### Issue 8: CodePipeline Build Fails

**Symptom:**
```
Build failed: COMMAND_EXECUTION_ERROR
Error: pip install failed
```

**Root Cause:** Missing dependencies or incorrect buildspec.yml

**Diagnosis:**
```bash
# Get build logs
BUILD_ID=$(aws codepipeline get-pipeline-state \
  --name cart-service-pipeline \
  --query 'stageStates[?stageName==`Build`].latestExecution.externalExecutionId' \
  --output text)

aws codebuild batch-get-builds \
  --ids $BUILD_ID \
  --query 'builds[0].logs.deepLink' \
  --output text

# View logs in browser or:
aws logs tail /aws/codebuild/cart-service-build --follow
```

**Solution:**
```bash
# Fix requirements.txt (ensure all dependencies listed)
cd cart-service
cat requirements.txt
# Should include:
# boto3>=1.34.0
# requests>=2.31.0

# Fix buildspec.yml (ensure correct Python version)
cat buildspec.yml
# Should have:
# runtime-versions:
#   python: 3.11

# Test build locally
pip install -r requirements.txt -t package/
cp -r src/* package/
cd package && zip -r ../cart-service.zip . && cd ..

# Commit and push fixes
git add requirements.txt buildspec.yml
git commit -m "Fix build dependencies"
git push origin main

# Pipeline will automatically trigger
```

---

### Issue 9: High AWS Costs

**Symptom:** AWS bill higher than expected

**Diagnosis:**
```bash
# Check cost by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum

# Check Bedrock usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/Bedrock \
  --metric-name InvocationCount \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum
```

**Cost Optimization:**
```bash
# 1. Delete dev environments when not in use
cd terraform/cart-service/dev
terraform destroy -auto-approve

# 2. Use Claude Haiku instead of Sonnet (75% cheaper)
# Edit agent-service/src/agent_handler/app.py
# Change: model="anthropic.claude-3-haiku-20240307-v1:0"

# 3. Reduce Lambda memory (if not needed)
aws lambda update-function-configuration \
  --function-name cart-service-add-dev \
  --memory-size 128  # Instead of 256

# 4. Reduce DynamoDB capacity
aws dynamodb update-table \
  --table-name carts-dev \
  --billing-mode PAY_PER_REQUEST  # Pay only for what you use

# 5. Reduce CloudWatch log retention
aws logs put-retention-policy \
  --log-group-name /aws/lambda/cart-service-add-dev \
  --retention-in-days 3  # Instead of 7

# 6. Set up budget alerts
aws budgets create-budget \
  --account-id $AWS_ACCOUNT_ID \
  --budget '{
    "BudgetName": "Monthly-Budget",
    "BudgetLimit": {"Amount": "100", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "your@email.com"}]
  }]'
```

---

### Issue 10: Can't Access AWS Console

**Symptom:** "Access Denied" when trying to view Lambda functions, DynamoDB tables, etc.

**Root Cause:** IAM user lacks necessary permissions

**Solution:**
```bash
# Check current permissions
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# Attach AdministratorAccess (for learning/development)
aws iam attach-user-policy \
  --user-name YOUR_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Or attach specific policies (for production)
aws iam attach-user-policy \
  --user-name YOUR_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess

aws iam attach-user-policy \
  --user-name YOUR_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Verify permissions
aws lambda list-functions --max-items 1
aws dynamodb list-tables
```

---

## Quick Troubleshooting Commands

```bash
# Check all Lambda functions
aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output table

# Check all DynamoDB tables
aws dynamodb list-tables --query 'TableNames' --output table

# Check all API Gateways
aws apigatewayv2 get-apis --query 'Items[*].[Name,ApiEndpoint]' --output table

# Check all CodePipelines
aws codepipeline list-pipelines --query 'pipelines[*].[name]' --output table

# Check recent Lambda errors
for func in $(aws lambda list-functions --query 'Functions[*].FunctionName' --output text); do
  echo "=== $func ==="
  aws logs filter-log-events \
    --log-group-name /aws/lambda/$func \
    --filter-pattern "ERROR" \
    --start-time $(date -u -d '1 hour ago' +%s)000 \
    --max-items 5
done

# Check CloudWatch alarms in ALARM state
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table
```

## Cleanup

### Delete All Services
```bash
#!/bin/bash

# Delete in reverse dependency order
for service in order cart payment product; do
  echo "Deleting ${service}-service..."
  
  # Delete prod
  cd terraform/${service}-service/prod
  terraform destroy -auto-approve
  
  # Delete dev
  cd ../dev
  terraform destroy -auto-approve
  
  # Delete pipeline
  cd ../pipeline
  terraform destroy -auto-approve
  
  cd ../../..
done

# Delete shared infrastructure
cd terraform/shared
terraform destroy -auto-approve
```

## Next Steps

1. **Add Authentication**: Integrate AWS Cognito
2. **Add API Gateway Custom Domain**: Route53 + ACM
3. **Add Monitoring Dashboard**: CloudWatch Dashboard
4. **Add Alerting**: SNS + CloudWatch Alarms
5. **Add Load Testing**: Artillery or Locust
6. **Add Contract Tests**: Pact for API contracts
7. **Add Chaos Engineering**: AWS Fault Injection Simulator

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT APPLICATIONS                       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Product    │    │     Cart     │    │    Order     │
│   Service    │◀───│   Service    │◀───│   Service    │
│              │    │              │    │      │       │
│ - List       │    │ - Add        │    │ - Create     │
│ - Get        │    │ - Remove     │    │ - Get        │
│ - Search     │    │ - Update     │    │ - List       │
└──────────────┘    └──────────────┘    └──────┬───────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  ProductDB   │    │   CartDB     │    │   OrderDB    │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                                                ▼
                                        ┌──────────────┐
                                        │   Payment    │
                                        │   Service    │
                                        │              │
                                        │ - Process    │
                                        │ - Get        │
                                        │ - Refund     │
                                        └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │  PaymentDB   │
                                        └──────────────┘
```

## Support

For issues or questions:
1. Check CloudWatch Logs
2. Review X-Ray traces
3. Check service health endpoints
4. Review Terraform state
5. Consult AWS documentation
