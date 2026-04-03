# 🚀 Getting Started - AWS Serverless Travel Platform

> **Complete guide from scratch to deployment**

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Quick Start (3 Options)](#quick-start)
5. [Step-by-Step Deployment](#step-by-step-deployment)
6. [Testing](#testing)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)
9. [Cost Estimation](#cost-estimation)

---

## 🎯 Project Overview

A **production-grade serverless travel booking platform** built on AWS with:

- **2 Core Microservices**: Hotel and Agent (AI) services
- **AI Travel Assistant**: Powered by AWS Bedrock (Claude 3)
- **Event-Driven Architecture**: EventBridge + SNS + SQS
- **Production Features**: Transactions, idempotency, backups, email notifications
- **100% Infrastructure as Code**: Terraform managed

### What You'll Build

```
┌─────────────────────────────────────────────────────────┐
│                   Travel Platform                        │
│                                                          │
│  Frontend (React) → API Gateway → Lambda → DynamoDB     │
│                          ↓                               │
│                    EventBridge                           │
│                          ↓                               │
│                   Email Notifications                    │
└─────────────────────────────────────────────────────────┘
```

**Key Features:**
- Search and book hotels
- AI-powered travel recommendations
- Automated booking confirmations via email
- Atomic transactions (no double-booking)
- Automated backups
- Production monitoring

---

## 📦 Prerequisites

### Required Tools

1. **AWS Account**
   - Free tier eligible
   - Credit card required
   - Estimated cost: $10-15/month

2. **AWS CLI** (v2.x)
   ```bash
   # Install
   # Windows: https://awscli.amazonaws.com/AWSCLIV2.msi
   # Mac: brew install awscli
   # Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   
   # Configure
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
   ```

3. **Terraform** (v1.5+)
   ```bash
   # Install
   # Windows: choco install terraform
   # Mac: brew install terraform
   # Linux: https://developer.hashicorp.com/terraform/downloads
   
   # Verify
   terraform --version
   ```

4. **Python** (3.11+)
   ```bash
   python --version
   pip --version
   ```

5. **Git**
   ```bash
   git --version
   ```

### Optional Tools

- **Node.js** (18+) - For frontend development
- **Docker** - For local testing with SAM CLI
- **SAM CLI** - For local Lambda testing

---

## 🏗️ Architecture

### Services

| Service | Purpose | Tech Stack |
|---------|---------|------------|
| **Hotel Service** | Search hotels, create bookings | Lambda + DynamoDB + EventBridge |
| **Agent Service** | AI travel assistant | Lambda + Bedrock (Claude 3) |

### Infrastructure Components

- **Compute**: AWS Lambda (Python 3.11)
- **API**: API Gateway (REST + HTTP)
- **Database**: DynamoDB (NoSQL)
- **Events**: EventBridge + SNS + SQS
- **Email**: Amazon SES
- **Auth**: Cognito User Pool
- **Secrets**: AWS Secrets Manager
- **Monitoring**: CloudWatch + X-Ray
- **Backups**: AWS Backup
- **IaC**: Terraform

### Production Features

✅ **Data Consistency**
- DynamoDB transactions (atomic operations)
- Idempotency keys (prevent duplicates)
- Optimistic locking

✅ **Resilience**
- Circuit breaker pattern
- Retry with exponential backoff
- Dead Letter Queues (DLQ)

✅ **Observability**
- CloudWatch Logs
- X-Ray distributed tracing
- CloudWatch Alarms

✅ **Security**
- Cognito authentication
- Secrets Manager
- IAM least privilege
- Encryption at-rest and in-transit

---

## 🚀 Quick Start

Choose your path:

### Option 1: Frontend Demo (No AWS Required)

Perfect for seeing the UI without deploying anything.

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:5173 - Full UI with demo data!

### Option 2: Local Testing with SAM CLI

Test Lambda functions locally before deploying.

```bash
# Install SAM CLI
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

# Start local services
bash scripts/start-local-services.sh

# Test
bash scripts/test-local-services.sh
```

### Option 3: Full AWS Deployment

Deploy the complete platform to AWS (recommended).

**Continue to Step-by-Step Deployment below** ⬇️

---

## 📖 Step-by-Step Deployment

### Step 1: Clone and Setup

```bash
# Clone repository
git clone <your-repo-url>
cd serverless-microservices

# Verify prerequisites
aws sts get-caller-identity  # Should show your AWS account
terraform --version           # Should be 1.5+
python --version             # Should be 3.11+
```

### Step 2: Bootstrap Terraform State Backend

This creates S3 bucket and DynamoDB table for Terraform state management.

```bash
cd terraform/bootstrap

# Initialize
terraform init

# Review what will be created
terraform plan

# Create state backend
terraform apply

# Output will show:
# - S3 bucket name: terraform-state-<account-id>
# - DynamoDB table: terraform-state-lock
```

**What this does:**
- Creates S3 bucket for Terraform state
- Creates DynamoDB table for state locking
- Prevents concurrent modifications
- Enables team collaboration

### Step 3: Deploy Hotel Service

This is the core service with all production features.

```bash
cd ../hotel-service/dev

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
domain_name = "example.com"  # Replace with your domain (or leave as-is for testing)
verified_emails = [
  "your-email@example.com"   # Replace with your email for testing
]
EOF

# Initialize modules
terraform init

# Review deployment plan
terraform plan

# Deploy (takes ~5-10 minutes)
terraform apply

# Save API endpoint
terraform output api_endpoint > api_endpoint.txt
```

**What this creates:**
- 4 Lambda functions (search, get, create-booking, notification)
- 4 DynamoDB tables (hotels, rooms, bookings, idempotency)
- 1 API Gateway
- 1 EventBridge event bus
- 3 SNS topics + 6 SQS queues
- 1 Cognito User Pool
- 2 Secrets Manager secrets
- 1 SES domain identity
- 2 Email templates
- 1 Backup vault
- 10+ CloudWatch alarms

**Cost**: ~$5-10/month

### Step 4: Configure Email (SES)

#### For Testing (Sandbox Mode)

```bash
# Verify your email address
aws ses verify-email-identity --email-address your-email@example.com

# Check your inbox and click verification link

# Verify it's confirmed
aws ses list-verified-email-addresses
```

**Note**: In sandbox mode, you can only send emails to verified addresses.

#### For Production

1. Go to AWS Console → Amazon SES
2. Click "Request production access"
3. Fill out form (takes 24-48 hours)
4. Add DNS records for domain verification

### Step 5: Add Sample Hotel Data

```bash
# Run the sample data script
bash scripts/add-sample-hotels.sh

# This creates:
# - 3 sample hotels
# - 9 rooms (3 per hotel)
# - Different room types and prices
```

### Step 6: Deploy Agent Service (AI Assistant)

```bash
cd ../../agent-service/dev

# Get hotel API endpoint from previous step
HOTEL_API=$(cd ../../hotel-service/dev && terraform output -raw api_endpoint)

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
hotel_api_url = "$HOTEL_API"
EOF

# Deploy
terraform init
terraform plan
terraform apply

# Save API endpoint
terraform output api_endpoint > api_endpoint.txt
```

**What this creates:**
- 1 Lambda function (AI agent)
- 1 API Gateway HTTP API
- Bedrock integration
- Secrets Manager integration
- X-Ray tracing

**Cost**: ~$20-30/month (Bedrock usage)

### Step 7: Deploy Frontend (Optional)

```bash
cd ../../../frontend

# Install dependencies
npm install

# Create .env file
cat > .env <<EOF
VITE_HOTEL_API_URL=$(cd ../terraform/hotel-service/dev && terraform output -raw api_endpoint)
VITE_AGENT_API_URL=$(cd ../terraform/agent-service/dev && terraform output -raw api_endpoint)
EOF

# Run locally
npm run dev

# Or build for production
npm run build
```

---

## 🧪 Testing

### Test 1: Create a Booking

```bash
# Get API endpoint
HOTEL_API=$(cd terraform/hotel-service/dev && terraform output -raw api_endpoint)

# Create booking
curl -X POST "$HOTEL_API/bookings" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "hotelId": "hotel-001",
    "roomId": "room-001",
    "checkIn": "2024-07-01",
    "checkOut": "2024-07-05",
    "guests": 2,
    "guestDetails": {
      "name": "John Doe",
      "email": "your-email@example.com",
      "phone": "+1234567890"
    }
  }'
```

**Expected Response:**
```json
{
  "message": "Booking created successfully",
  "bookingId": "uuid-here",
  "status": "confirmed",
  "totalPrice": "800.00",
  "nights": 4
}
```

**What happens:**
1. Lambda validates request
2. DynamoDB transaction creates booking + updates room availability
3. EventBridge publishes event
4. Notification Lambda triggered
5. SES sends confirmation email
6. You receive email!

### Test 2: Search Hotels

```bash
curl "$HOTEL_API/hotels?location=Bali&checkIn=2024-07-01&checkOut=2024-07-05"
```

### Test 3: AI Travel Assistant

```bash
AGENT_API=$(cd terraform/agent-service/dev && terraform output -raw api_endpoint)

curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to book a romantic hotel in Bali for 3 nights",
    "userId": "user123"
  }'
```

### Test 4: Verify Idempotency

```bash
# Send same request twice (same data)
# Should return same bookingId, no duplicate created
```

### Test 5: Test Transaction Rollback

```bash
# Try to book same room again
# Should return 409 Conflict: "Room not available"
```

---

## 📊 Monitoring

### CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/hotel-service-create-booking-dev --follow

# View API Gateway logs
aws logs tail /aws/apigateway/hotel-service-dev --follow
```

### CloudWatch Alarms

```bash
# List alarms
aws cloudwatch describe-alarms --alarm-name-prefix hotel-service-dev

# Check alarm state
aws cloudwatch describe-alarms --state-value ALARM
```

### X-Ray Traces

```bash
# View service map
aws xray get-service-graph \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s)
```

### DynamoDB Metrics

```bash
# Check table metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=hotel-service-bookings-dev \
  --start-time $(date -u -d '1 hour ago' --iso-8601) \
  --end-time $(date -u --iso-8601) \
  --period 300 \
  --statistics Sum
```

### Cost Monitoring

```bash
# View current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 month ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

---

## 🐛 Troubleshooting

### Issue: Email not received

**Symptoms**: Booking created but no email

**Causes**:
1. SES in sandbox mode - both sender and recipient must be verified
2. Email in spam folder
3. Lambda timeout

**Debug**:
```bash
# Check notification Lambda logs
aws logs tail /aws/lambda/hotel-service-booking-notification-dev --since 1h

# Check SES sending statistics
aws ses get-send-statistics

# Verify email address
aws ses list-verified-email-addresses
```

**Fix**:
```bash
# Verify your email
aws ses verify-email-identity --email-address your-email@example.com
```

### Issue: Booking creation fails

**Symptoms**: 500 error or timeout

**Causes**:
1. DynamoDB table doesn't exist
2. Room not available
3. Invalid date format
4. Missing IAM permissions

**Debug**:
```bash
# Check Lambda logs
aws logs tail /aws/lambda/hotel-service-create-booking-dev --since 1h

# Check DynamoDB table
aws dynamodb describe-table --table-name hotel-service-bookings-dev

# Check room availability
aws dynamodb get-item \
  --table-name hotel-service-rooms-dev \
  --key '{"roomId":{"S":"room-001"}}'
```

### Issue: Terraform apply fails

**Symptoms**: Resource already exists or permission denied

**Causes**:
1. Resources already deployed
2. Insufficient IAM permissions
3. State file out of sync

**Fix**:
```bash
# Import existing resource
terraform import aws_dynamodb_table.example hotel-service-bookings-dev

# Or destroy and recreate
terraform destroy
terraform apply

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

### Issue: High costs

**Symptoms**: AWS bill higher than expected

**Causes**:
1. Bedrock usage (AI calls)
2. DynamoDB on-demand mode
3. CloudWatch Logs retention
4. NAT Gateway (if using VPC)

**Fix**:
```bash
# Check cost breakdown
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Reduce costs:
# 1. Delete unused resources
terraform destroy

# 2. Reduce CloudWatch Logs retention
aws logs put-retention-policy \
  --log-group-name /aws/lambda/hotel-service-create-booking-dev \
  --retention-in-days 3

# 3. Use provisioned capacity for DynamoDB (if predictable traffic)
```

---

## 💰 Cost Estimation

### Development/Testing (Low Traffic)

| Service | Monthly Cost |
|---------|-------------|
| Lambda | $0-2 (free tier) |
| DynamoDB | $1-5 |
| API Gateway | $0-1 (free tier) |
| EventBridge | $0-1 |
| SNS/SQS | $0-1 |
| SES | $0 (free tier: 62,000 emails) |
| Secrets Manager | $0.80 (2 secrets) |
| Bedrock (AI) | $20-30 |
| CloudWatch | $1-3 |
| **Total** | **$25-45/month** |

### Production (Medium Traffic)

| Service | Monthly Cost |
|---------|-------------|
| Lambda | $10-20 |
| DynamoDB | $20-50 |
| API Gateway | $10-20 |
| EventBridge | $2-5 |
| SNS/SQS | $2-5 |
| SES | $10-20 |
| Secrets Manager | $0.80 |
| Bedrock (AI) | $100-200 |
| CloudWatch | $10-20 |
| Backups | $5-10 |
| **Total** | **$170-350/month** |

### Cost Optimization Tips

1. **Use Free Tier**
   - Lambda: 1M requests/month free
   - DynamoDB: 25 GB storage free
   - SES: 62,000 emails/month free

2. **Optimize Lambda**
   - Right-size memory (256 MB is often enough)
   - Reduce timeout (30s → 10s if possible)
   - Use Lambda layers for shared code

3. **Optimize DynamoDB**
   - Use on-demand for unpredictable traffic
   - Use provisioned for predictable traffic
   - Enable TTL for temporary data

4. **Reduce Bedrock Costs**
   - Cache AI responses
   - Use smaller models when possible
   - Implement rate limiting

5. **Clean Up**
   ```bash
   # Delete unused resources
   terraform destroy
   
   # Delete old CloudWatch Logs
   aws logs delete-log-group --log-group-name /aws/lambda/old-function
   ```

---

## 🎓 What You've Built

### Technical Skills Demonstrated

✅ **AWS Serverless**
- Lambda, API Gateway, DynamoDB
- EventBridge, SNS, SQS
- Cognito, Secrets Manager, SES
- CloudWatch, X-Ray

✅ **Architecture Patterns**
- Microservices
- Event-Driven Architecture
- CQRS (Command Query Responsibility Segregation)
- Saga Pattern (distributed transactions)

✅ **Production Features**
- Atomic transactions
- Idempotency
- Circuit breaker & retry
- Automated backups
- Email notifications
- Distributed tracing

✅ **DevOps**
- Infrastructure as Code (Terraform)
- CI/CD pipelines
- Monitoring & alerting
- Cost optimization

✅ **Security**
- Authentication (Cognito)
- Secrets management
- IAM least privilege
- Encryption

---

## 📚 Next Steps

### Enhance the Platform

1. **Add More Features**
   - User reviews and ratings
   - Payment integration (Stripe)
   - Multi-currency support
   - Loyalty program

2. **Improve Performance**
   - Add DAX caching for DynamoDB
   - Enable API Gateway caching
   - Use CloudFront CDN

3. **Production Hardening**
   - Exit SES sandbox mode
   - Configure custom domain
   - Add WAF rules
   - Enable GuardDuty
   - Set up AWS Config

4. **Scale the Platform**
   - Add more regions
   - Implement global tables
   - Add read replicas
   - Use Lambda reserved concurrency

### Learn More

- [AWS Serverless Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file

---

## 📞 Support

- **Issues**: Open a GitHub issue
- **Questions**: Check existing issues or create new one
- **Documentation**: See README.md and code comments

---

## ✅ Checklist

Use this to track your progress:

- [ ] Prerequisites installed (AWS CLI, Terraform, Python)
- [ ] AWS account configured
- [ ] Terraform state backend created
- [ ] Hotel service deployed
- [ ] Email verified in SES
- [ ] Sample data added
- [ ] Booking tested successfully
- [ ] Email received
- [ ] Agent service deployed
- [ ] Order service deployed
- [ ] Payment service deployed
- [ ] Frontend deployed (optional)
- [ ] Monitoring configured
- [ ] Cost alerts set up

---

**🎉 Congratulations!** You've built a production-grade serverless travel platform!

**Estimated Time**: 2-3 hours  
**Difficulty**: Intermediate  
**Cost**: $25-45/month (dev), $170-350/month (prod)

---

*Last Updated: 2024*  
*Version: 1.0.0*
