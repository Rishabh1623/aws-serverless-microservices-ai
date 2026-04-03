# 🚀 Complete Deployment Guide

## Project Overview

**AI-Powered Serverless Travel Booking Platform**
- 5 Microservices (Hotel, Cart, Order, Payment, Agent)
- Event-driven architecture with EventBridge
- Infrastructure as Code with Terraform
- Production-ready with state locking, monitoring, security

**Monthly Cost**: ~$22 for 10K requests

---

## Prerequisites

```bash
# 1. AWS CLI
aws --version  # >= 2.0
aws configure  # Set credentials

# 2. Terraform
terraform --version  # >= 1.5.0

# 3. Python
python --version  # >= 3.11

# 4. Node.js (for frontend)
node --version  # >= 18

# 5. Verify AWS access
aws sts get-caller-identity
```

---

## Architecture

```
5 Microservices:
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│    Hotel     │  │     Cart     │  │    Order     │  │   Payment    │  │    Agent     │
│   Service    │  │   Service    │  │   Service    │  │   Service    │  │   Service    │
│              │  │              │  │              │  │              │  │              │
│ 4 Lambdas    │  │ 4 Lambdas    │  │ 4 Lambdas    │  │ 4 Lambdas    │  │ 1 Lambda     │
│ API Gateway  │  │ API Gateway  │  │ API Gateway  │  │ API Gateway  │  │ API Gateway  │
│ DynamoDB     │  │ DynamoDB     │  │ DynamoDB     │  │ DynamoDB     │  │ Bedrock      │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │                 │
       └─────────────────┴─────────────────┴─────────────────┴─────────────────┘
                                           │
                                    EventBridge Bus
                                           │
                                    ┌──────┴──────┐
                                    │     SES     │
                                    │Notifications│
                                    └─────────────┘
```

**User Journey**: Browse Hotels → Add to Cart → Checkout → Payment → Confirmation

---

## Step-by-Step Deployment

### Step 1: Bootstrap (One-Time Setup)

Creates S3 bucket and DynamoDB table for Terraform state locking.

```bash
cd terraform/bootstrap
terraform init
terraform apply -auto-approve

# Note outputs
terraform output
```

**What it creates**:
- S3 bucket: `terraform-state-543927035352`
- DynamoDB table: `terraform-state-lock`

---

### Step 2: Deploy Hotel Service

```bash
cd ../hotel-service/dev
terraform init
terraform apply -auto-approve

# Save API URL
export HOTEL_API=$(terraform output -raw api_gateway_url)
echo "Hotel API: $HOTEL_API"
```

**What it creates**:
- 4 Lambda functions (search, get, create-booking, notification)
- API Gateway
- 4 DynamoDB tables (hotels, rooms, bookings, idempotency)
- EventBridge bus
- SES email configuration

---

### Step 3: Deploy Cart Service

```bash
cd ../../cart-service/dev
terraform init
terraform apply -auto-approve

# Save API URL
export CART_API=$(terraform output -raw api_gateway_url)
echo "Cart API: $CART_API"
```

**What it creates**:
- 4 Lambda functions (add, get, remove, apply-promo)
- API Gateway
- DynamoDB table with 15-min TTL

---

### Step 4: Deploy Order Service

```bash
cd ../../order-service/dev
terraform init
terraform apply -auto-approve

# Save API URL
export ORDER_API=$(terraform output -raw api_gateway_url)
echo "Order API: $ORDER_API"
```

**What it creates**:
- 4 Lambda functions (create, get, list, cancel)
- API Gateway
- DynamoDB table

---

### Step 5: Deploy Payment Service

```bash
cd ../../payment-service/dev

# Set Stripe API key (get from https://stripe.com)
export TF_VAR_stripe_api_key="sk_test_your_stripe_key"

terraform init
terraform apply -auto-approve

# Save API URL
export PAYMENT_API=$(terraform output -raw api_gateway_url)
echo "Payment API: $PAYMENT_API"
```

**What it creates**:
- 4 Lambda functions (process, get, refund, webhook)
- API Gateway
- DynamoDB table
- Secrets Manager for Stripe key

---

### Step 6: Deploy Agent Service

```bash
cd ../../agent-service/dev
terraform init
terraform apply -auto-approve

# Save API URL
export AGENT_API=$(terraform output -raw api_gateway_url)
echo "Agent API: $AGENT_API"
```

**What it creates**:
- 1 Lambda function (AI assistant)
- API Gateway
- Bedrock integration

---

### Step 7: Add Sample Data

```bash
cd ../../../scripts
./add-sample-hotels.sh
```

Adds 30 sample hotels across 10 destinations.

---

### Step 8: Deploy Frontend

```bash
cd ../frontend

# Create .env file
cat > .env << EOF
VITE_HOTEL_API=$HOTEL_API
VITE_CART_API=$CART_API
VITE_ORDER_API=$ORDER_API
VITE_PAYMENT_API=$PAYMENT_API
VITE_AGENT_API=$AGENT_API
EOF

# Install and build
npm install
npm run build

# Run locally
npm run dev
# Open http://localhost:5173
```

---

## Testing

### Test Each Service

```bash
# 1. Search Hotels
curl "$HOTEL_API/hotels?destination=Paris"

# 2. Add to Cart
curl -X POST "$CART_API/cart/add" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "hotelId": "hotel-001",
    "roomId": "room-001",
    "checkIn": "2024-06-15",
    "checkOut": "2024-06-20",
    "guests": 2
  }'

# 3. Get Cart
curl "$CART_API/cart/test-user"

# 4. Create Order
curl -X POST "$ORDER_API/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "guestDetails": {
      "name": "John Doe",
      "email": "john@example.com"
    }
  }'

# 5. List Orders
curl "$ORDER_API/orders/user/test-user"
```

---

## Monitoring

### CloudWatch Logs

```bash
# View logs for a function
aws logs tail /aws/lambda/cart-service-add-to-cart-dev --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/cart-service-add-to-cart-dev \
  --filter-pattern "ERROR"
```

### X-Ray Traces

Open AWS Console → X-Ray → Traces

### CloudWatch Metrics

Open AWS Console → CloudWatch → Metrics → TravelPlatform

---

## State Locking

All services use remote state with DynamoDB locking:

```hcl
backend "s3" {
  bucket         = "terraform-state-543927035352"
  key            = "[service]/dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

**Benefits**:
- Prevents concurrent modifications
- State versioning (90-day retention)
- Encrypted at rest
- Team collaboration ready

**If locked**:
```bash
# Check lock
aws dynamodb scan --table-name terraform-state-lock

# Force unlock if stale
terraform force-unlock <LOCK_ID>
```

---

## Troubleshooting

### Issue: Terraform State Locked

```bash
# Check who has the lock
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"terraform-state-543927035352/cart-service/dev/terraform.tfstate"}}'

# Force unlock if process crashed
cd terraform/cart-service/dev
terraform force-unlock <LOCK_ID>
```

### Issue: Lambda Deployment Failed

```bash
# Check logs
aws logs tail /aws/lambda/<function-name> --follow

# Verify IAM permissions
aws iam get-role --role-name cart-service-add-to-cart-dev
```

### Issue: API Gateway CORS Error

CORS is already configured in Terraform. If issues persist:
```bash
# Check API Gateway console
# Verify CORS settings in API Gateway → Resources → Enable CORS
```

### Issue: DynamoDB Table Not Found

```bash
# List tables
aws dynamodb list-tables

# Verify table name matches environment variable
aws dynamodb describe-table --table-name cart-service-carts-dev
```

---

## Cleanup

### Destroy All Infrastructure

```bash
# Destroy in reverse order
cd terraform/agent-service/dev && terraform destroy -auto-approve
cd ../../payment-service/dev && terraform destroy -auto-approve
cd ../../order-service/dev && terraform destroy -auto-approve
cd ../../cart-service/dev && terraform destroy -auto-approve
cd ../../hotel-service/dev && terraform destroy -auto-approve
cd ../../bootstrap && terraform destroy -auto-approve
```

---

## API Endpoints Reference

### Hotel Service
```
GET    /hotels                    - Search hotels
GET    /hotels/{hotelId}          - Get hotel details
POST   /bookings                  - Create booking
```

### Cart Service
```
POST   /cart/add                  - Add to cart
GET    /cart/{userId}             - Get cart
DELETE /cart/{userId}/{itemId}    - Remove from cart
POST   /cart/{userId}/promo       - Apply promo code
```

### Order Service
```
POST   /orders                    - Create order
GET    /orders/{orderId}          - Get order
GET    /orders/user/{userId}      - List user orders
PATCH  /orders/{orderId}/cancel   - Cancel order
```

### Payment Service
```
POST   /payments                  - Process payment
GET    /payments/{paymentId}      - Get payment
POST   /payments/{paymentId}/refund - Refund payment
POST   /payments/webhook          - Stripe webhook
```

### Agent Service
```
POST   /agent/chat                - Chat with AI assistant
```

---

## Cost Breakdown

**Monthly cost for 10,000 requests**:
- Lambda: $5
- API Gateway: $3
- DynamoDB: $10
- EventBridge: $1
- CloudWatch: $2
- Secrets Manager: $1
- **Total: ~$22/month**

---

## Production Checklist

Before deploying to production:

- [ ] Use production Stripe API keys
- [ ] Configure custom domain (Route53 + ACM)
- [ ] Enable WAF on API Gateway
- [ ] Set up CloudWatch alarms
- [ ] Configure backup retention
- [ ] Enable CloudTrail for audit logging
- [ ] Set Lambda reserved concurrency
- [ ] Configure API Gateway throttling
- [ ] Review IAM policies (least privilege)
- [ ] Set up CI/CD pipeline
- [ ] Configure monitoring dashboards
- [ ] Test disaster recovery

---

## Key Features

✅ **5 Microservices** - Complete architecture
✅ **Event-Driven** - EventBridge for loose coupling
✅ **State Locking** - DynamoDB prevents conflicts
✅ **Observability** - X-Ray + CloudWatch
✅ **Security** - IAM + Secrets Manager + Encryption
✅ **Auto-Scaling** - Serverless handles traffic spikes
✅ **Cost-Effective** - Pay per use (~$22/month)
✅ **Production-Ready** - Monitoring, backups, security

---

## Architecture Highlights

**Microservices**:
1. Hotel Service - Catalog and search
2. Cart Service - Shopping cart with 15-min TTL
3. Order Service - Order management
4. Payment Service - Stripe integration
5. Agent Service - AI assistant (AWS Bedrock)

**AWS Services Used**:
- Lambda (17 functions)
- API Gateway (5 APIs)
- DynamoDB (7 tables)
- EventBridge (event bus)
- S3 (state storage)
- Secrets Manager (Stripe key)
- SES (email notifications)
- X-Ray (tracing)
- CloudWatch (logs & metrics)

**Best Practices**:
- DynamoDB transactions (prevent double-booking)
- Idempotency keys (prevent duplicate operations)
- Circuit breaker pattern (resilience)
- X-Ray tracing (observability)
- CloudWatch metrics (monitoring)
- Secrets Manager (security)
- State locking (team collaboration)

---

## Support

**View Logs**:
```bash
aws logs tail /aws/lambda/<function-name> --follow
```

**Check Resources**:
```bash
aws lambda list-functions
aws dynamodb list-tables
aws apigateway get-rest-apis
```

**Get Help**:
1. Check CloudWatch logs
2. Review Terraform plan output
3. Verify AWS permissions
4. Check service dependencies

---

## Summary

You now have a **production-ready serverless travel booking platform** with:
- Complete microservices architecture
- Event-driven design
- Infrastructure as Code
- State locking for team collaboration
- Full observability
- Security best practices
- Auto-scaling
- Cost-effective (~$22/month)

**Total deployment time**: ~30 minutes
**Total services**: 5 microservices, 17 Lambda functions

🎉 **Ready to deploy!**
