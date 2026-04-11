# Order Processing Orchestrator - Deployment Guide

## Overview

The Order Processing Orchestrator is a Lambda Durable Function that handles the complete order workflow from cart to payment confirmation.

## What It Does

Single durable function orchestrates:
1. ✅ Validates order request
2. ✅ Gets cart items
3. ✅ Applies promo code discount
4. ✅ Creates order
5. ✅ Processes payment (with automatic retries)
6. ✅ Confirms order
7. ✅ Clears cart
8. ✅ Sends confirmation email
9. ✅ Handles rollback on payment failure

## Workflow Diagram

```
User Request
    ↓
Validate Request
    ↓
Get Cart Items → (if empty) → Return Error
    ↓
Calculate Pricing (apply promo)
    ↓
Create Order (status: pending_payment)
    ↓
Process Payment (retry up to 3 times)
    ↓
  Success?
    ├─ YES → Confirm Order
    │         ↓
    │      Clear Cart
    │         ↓
    │      Send Email
    │         ↓
    │      Return Success
    │
    └─ NO → Rollback Order
             ↓
          Restore Cart
             ↓
          Return Error
```

## Prerequisites

Make sure you've already deployed:
- ✅ Bootstrap (terraform/bootstrap)
- ✅ Order Service (terraform/order-service/dev)
- ✅ Cart Service (terraform/cart-service/dev)
- ✅ Payment Service (terraform/payment-service/dev)
- ✅ DynamoDB tables exist
- ✅ API Gateway exists
- ✅ Stripe secret in Secrets Manager

## Deployment Steps

### Step 1: Install Dependencies

```bash
cd order-service/src/order_orchestrator
pip install -r requirements.txt -t .
cd ../../..
```

### Step 2: Deploy with Terraform

```bash
cd terraform/order-service-durable
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted.

### Step 3: Get API Endpoint

```bash
terraform output api_endpoint
```

Save this URL for testing.

## Testing

### Test Complete Order Flow

```bash
# Replace with your actual API endpoint
API_ENDPOINT="https://your-api-id.execute-api.us-east-1.amazonaws.com/orders/orchestrated"

# First, add items to cart (use cart service)
curl -X POST "https://your-cart-api.com/cart/add" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "hotelId": "hotel-001",
    "roomId": "room-001",
    "checkIn": "2024-06-15",
    "checkOut": "2024-06-20",
    "guests": 2
  }'

# Then create order with payment
curl -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "guestDetails": {
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    },
    "promoCode": "SUMMER20",
    "paymentMethod": {
      "type": "card",
      "cardToken": "tok_visa"
    },
    "billingDetails": {
      "name": "John Doe",
      "email": "john@example.com",
      "address": {
        "line1": "123 Main St",
        "city": "New York",
        "state": "NY",
        "postal_code": "10001",
        "country": "US"
      }
    }
  }'
```

### Expected Response (Success)

```json
{
  "message": "Order created and payment processed successfully",
  "orderId": "uuid-here",
  "paymentId": "uuid-here",
  "totalPrice": "800.00",
  "discountAmount": "160.00",
  "itemCount": 1,
  "status": "confirmed",
  "createdAt": "2024-06-10T10:30:00Z"
}
```

### Expected Response (Payment Failed)

```json
{
  "error": "Payment failed",
  "details": "Payment gateway timeout",
  "orderId": "uuid-here"
}
```

Note: Cart items are restored, order is marked as cancelled.

## Features

### 1. Automatic Payment Retries

Payment processing automatically retries up to 3 times with 5-second delays:

```python
payment_result = durable_context.step(
    'process_payment',
    process_payment_step,
    order_id,
    amount,
    payment_method,
    billing_details,
    max_retries=3,           # Retry up to 3 times
    retry_delay_seconds=5    # Wait 5 seconds between retries
)
```

### 2. Automatic Rollback

If payment fails after all retries:
- Order status → `cancelled`
- Payment status → `failed`
- Cart items restored to `active`
- User can try again

### 3. Promo Code Support

Supports promo codes with automatic discount calculation:

```python
# Built-in promo codes:
SUMMER20 → 20% off
WELCOME10 → 10% off
VIP25 → 25% off
```

### 4. Email Confirmation

Sends order confirmation email with:
- Order ID
- Item details (hotels, dates, prices)
- Subtotal, discount, final price
- Payment ID

### 5. Comprehensive Metrics

Publishes CloudWatch metrics:
- `OrderCount` - Number of successful orders
- `Duration` - Execution time
- `Revenue` - Total order value
- `Errors` - Failed orders

## Monitoring

### View Logs

```bash
aws logs tail /aws/lambda/travel-platform-order-orchestrator-dev --follow
```

### View Metrics

```bash
aws cloudwatch get-metric-statistics \
  --namespace TravelPlatform/OrderService \
  --metric-name OrderCount \
  --dimensions Name=Operation,Value=OrderOrchestrator \
  --start-time $(date -u -d '1 hour ago' --iso-8601) \
  --end-time $(date -u --iso-8601) \
  --period 300 \
  --statistics Sum
```

### Check Order Status

```bash
# Get order details
aws dynamodb get-item \
  --table-name travel-platform-orders-dev \
  --key '{"orderId":{"S":"your-order-id"}}'
```

## Comparison: EventBridge vs Durable Functions

| Feature | EventBridge (Old) | Durable Functions (New) |
|---------|------------------|-------------------------|
| **Components** | 3 separate Lambdas | 1 Lambda function |
| **State Management** | Manual (DynamoDB) | Automatic |
| **Retry Logic** | Manual implementation | Built-in |
| **Rollback** | Manual compensation | Automatic |
| **Debugging** | Distributed traces | Single execution |
| **Code Complexity** | High | Low |
| **Maintenance** | Multiple functions | Single function |

## Architecture Benefits

### Before (EventBridge)
```
Create Order Lambda → EventBridge → Process Payment Lambda
                                  ↓
                            Update Order Lambda
                                  ↓
                            Send Email Lambda
```

Problems:
- 4 separate Lambda functions
- Manual state management
- Complex error handling
- Distributed debugging

### After (Durable Function)
```
Order Orchestrator Durable Function
├─ Step 1: Validate
├─ Step 2: Get Cart
├─ Step 3: Calculate Pricing
├─ Step 4: Create Order
├─ Step 5: Process Payment (auto-retry)
├─ Step 6: Confirm Order
├─ Step 7: Clear Cart
└─ Step 8: Send Email
```

Benefits:
- Single Lambda function
- Automatic state management
- Built-in retry logic
- Easy debugging

## Cost Estimate

Additional cost: ~$3-7/month for typical usage

- Lambda invocations: $0.20 per 1M requests
- Lambda duration: $0.0000166667 per GB-second
- DynamoDB: Included (existing tables)
- SES: $0.10 per 1,000 emails

## Troubleshooting

### Issue: Payment always fails

**Check:**
1. Stripe secret exists in Secrets Manager
2. Lambda has permission to access secret
3. Payment table exists

```bash
# Verify secret
aws secretsmanager get-secret-value \
  --secret-id travel-platform-stripe-key-dev

# Check Lambda permissions
aws iam get-role-policy \
  --role-name travel-platform-order-orchestrator-dev-role \
  --policy-name travel-platform-order-orchestrator-secrets-dev
```

### Issue: Cart items not cleared

**Check:**
1. Cart table has correct index
2. Lambda has DynamoDB permissions

```bash
# Verify cart table
aws dynamodb describe-table \
  --table-name travel-platform-carts-dev
```

### Issue: Email not sent

**Check:**
1. SES email verified
2. Email template exists
3. Lambda has SES permissions

```bash
# Verify email
aws ses list-verified-email-addresses

# Check template
aws ses get-template \
  --template-name order-confirmation-dev
```

## Cleanup

```bash
cd terraform/order-service-durable
terraform destroy
```

## Next Steps

1. ✅ Deploy order orchestrator
2. ✅ Test with sample order
3. ✅ Monitor CloudWatch logs
4. ✅ Review metrics
5. ✅ Update frontend to use new endpoint
6. ✅ Consider implementing payment orchestrator next

## Related Documentation

- [DURABLE_FUNCTIONS_GUIDE.md](DURABLE_FUNCTIONS_GUIDE.md) - Complete durable functions guide
- [DEPLOY.md](DEPLOY.md) - Main deployment guide
- [Payment Orchestrator](PAYMENT_ORCHESTRATOR_DEPLOYMENT.md) - Next implementation

---

For questions or issues, check CloudWatch logs or review the main deployment documentation.
