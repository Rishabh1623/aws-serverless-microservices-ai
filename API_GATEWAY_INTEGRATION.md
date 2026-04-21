# API Gateway Integration - Deployment Guide

## 🎯 What This Creates

A **unified API Gateway** that provides REST endpoints to trigger your Step Functions workflows.

### New Endpoints

**Base URL:** `https://<api-id>.execute-api.us-east-1.amazonaws.com/dev`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/workflows/hotel-booking` | POST | Trigger hotel booking workflow |
| `/workflows/order-processing` | POST | Trigger order processing workflow |
| `/workflows/payment-processing` | POST | Trigger payment processing workflow |

### Features
- ✅ CORS enabled for frontend
- ✅ Step Functions integration
- ✅ X-Ray tracing
- ✅ Async workflow execution
- ✅ Returns execution ARN immediately

---

## 📋 Deployment Steps

### 1. Commit and Push
```bash
cd ~/aws-serverless-microservices-ai
git pull origin main
```

### 2. Deploy API Gateway
```bash
cd terraform/api-gateway-unified/dev
terraform init
terraform plan
terraform apply
```

### 3. Get Endpoints
```bash
terraform output workflow_endpoints
```

---

## 🧪 Testing

### Test Hotel Booking Workflow
```bash
# Get the endpoint
API_URL=$(cd terraform/api-gateway-unified/dev && terraform output -raw api_gateway_url)

# Trigger workflow
curl -X POST "${API_URL}/workflows/hotel-booking" \
  -H "Content-Type: application/json" \
  -d '{
    "hotelId": "h123",
    "roomId": "r456",
    "userId": "u789",
    "checkIn": "2026-05-01",
    "checkOut": "2026-05-05",
    "guestName": "John Doe",
    "guestEmail": "john@example.com"
  }'
```

**Expected Response:**
```json
{
  "executionArn": "arn:aws:states:us-east-1:...:execution:travel-platform-hotel-booking-dev:...",
  "startDate": "2026-04-21T...",
  "message": "Workflow started successfully"
}
```

### Test Order Processing Workflow
```bash
curl -X POST "${API_URL}/workflows/order-processing" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "promoCode": "SUMMER20",
    "paymentMethod": {
      "type": "card",
      "cardNumber": "4242424242424242"
    }
  }'
```

### Test Payment Processing Workflow
```bash
curl -X POST "${API_URL}/workflows/payment-processing" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "order123",
    "userId": "user123",
    "amount": 100.00,
    "currency": "USD",
    "paymentMethod": {
      "type": "card",
      "cardNumber": "4242424242424242"
    }
  }'
```

---

## 🔗 Frontend Integration

### Update Frontend Config

**File:** `frontend/src/config.js`

```javascript
export const API_CONFIG = {
  // Existing service endpoints
  hotelService: 'https://zttuy6f8bj.execute-api.us-east-1.amazonaws.com/dev',
  orderService: 'https://vy2wiorpxl.execute-api.us-east-1.amazonaws.com/dev',
  paymentService: 'https://gupn3gch28.execute-api.us-east-1.amazonaws.com/dev',
  agentService: 'https://bj623ttpd4.execute-api.us-east-1.amazonaws.com',
  
  // NEW: Unified API for workflows
  unifiedApi: '<YOUR_API_GATEWAY_URL>',  // From terraform output
  
  workflows: {
    hotelBooking: '<YOUR_API_GATEWAY_URL>/workflows/hotel-booking',
    orderProcessing: '<YOUR_API_GATEWAY_URL>/workflows/order-processing',
    paymentProcessing: '<YOUR_API_GATEWAY_URL>/workflows/payment-processing'
  }
};
```

### Example: Trigger Workflow from React

```javascript
// Trigger hotel booking workflow
const bookHotel = async (bookingData) => {
  try {
    const response = await fetch(API_CONFIG.workflows.hotelBooking, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bookingData)
    });
    
    const result = await response.json();
    console.log('Workflow started:', result.executionArn);
    
    // Poll for workflow status or show success message
    return result;
  } catch (error) {
    console.error('Workflow failed:', error);
    throw error;
  }
};
```

---

## 📊 Architecture

```
Frontend (React)
    ↓
API Gateway (Unified)
    ↓
Step Functions Workflows
    ↓
Lambda Functions + DynamoDB
```

### Benefits
- ✅ **Single entry point** for all workflows
- ✅ **Async execution** - returns immediately
- ✅ **Scalable** - API Gateway handles traffic
- ✅ **Monitored** - X-Ray tracing enabled
- ✅ **Secure** - Can add Cognito auth later

---

## 🔐 Adding Authentication (Optional)

To add Cognito authentication:

1. Update method authorization:
```terraform
resource "aws_api_gateway_method" "hotel_booking_post" {
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}
```

2. Create Cognito authorizer:
```terraform
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.unified.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [data.aws_cognito_user_pool.main.arn]
}
```

---

## 📈 Monitoring

### View API Gateway Metrics
```bash
# API Gateway dashboard
https://console.aws.amazon.com/apigateway/home?region=us-east-1

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=travel-platform-unified-api-dev \
  --start-time 2026-04-21T00:00:00Z \
  --end-time 2026-04-21T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### View Workflow Executions
```bash
# List recent executions
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:us-east-1:600105205879:stateMachine:travel-platform-hotel-booking-dev \
  --max-results 10
```

---

## 💰 Cost Estimate

**API Gateway Pricing:**
- First 333 million requests: $3.50 per million
- Example: 100,000 requests/month = $0.35/month

**Step Functions Pricing:**
- Already covered in workflow deployment

**Total Additional Cost:** ~$0.35-$1/month

---

## 🎉 What You Get

After deployment:
- ✅ REST API endpoints for all workflows
- ✅ CORS configured for frontend
- ✅ Async workflow execution
- ✅ X-Ray tracing
- ✅ CloudWatch monitoring
- ✅ Ready for frontend integration

---

## 🚀 Next Steps

1. **Deploy API Gateway** (steps above)
2. **Test endpoints** with curl
3. **Update frontend** with new API URLs
4. **Add authentication** (optional)
5. **Set up monitoring** alarms

Let me know once deployed and I'll help with frontend integration! 🎯
