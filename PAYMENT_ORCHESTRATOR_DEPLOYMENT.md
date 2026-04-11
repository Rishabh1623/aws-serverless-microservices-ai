# Payment Processing Orchestrator - Deployment Guide

## Overview

The Payment Processing Orchestrator is a Lambda Durable Function that handles complete payment workflows with Stripe integration, including retries, 3D Secure authentication, and refunds.

## What It Does

Single durable function orchestrates:
1. ✅ Validates payment request
2. ✅ Verifies order exists
3. ✅ Gets Stripe API key from Secrets Manager
4. ✅ Creates Stripe Payment Intent
5. ✅ Handles 3D Secure authentication (waits for user)
6. ✅ Confirms payment
7. ✅ Saves payment record
8. ✅ Updates order status
9. ✅ Sends receipt email

## Workflow Diagram

```
User Request
    ↓
Validate Payment Request
    ↓
Verify Order Exists → (if not found) → Return Error
    ↓
Get Stripe API Key
    ↓
Create Payment Intent (retry up to 3 times)
    ↓
  Requires 3D Secure?
    ├─ YES → Wait for User Authentication
    │         ↓
    │      Check Auth Status (retry up to 5 times)
    │         ↓
    │      Success?
    │         ├─ YES → Continue
    │         └─ NO → Cancel Intent → Return Error
    │
    └─ NO → Continue
         ↓
Confirm Payment (retry up to 3 times)
    ↓
  Success?
    ├─ YES → Save Payment Record
    │         ↓
    │      Update Order Status
    │         ↓
    │      Send Receipt Email
    │         ↓
    │      Return Success
    │
    └─ NO → Return Error
```

## Key Features

### 1. Automatic Retries
- Payment Intent creation: 3 retries with 5-second delays
- 3D Secure checks: 5 retries with 10-second delays
- Payment confirmation: 3 retries with 5-second delays

### 2. 3D Secure Support
- Detects when 3D Secure is required
- Waits for user authentication (no compute charges)
- Automatically resumes after authentication
- Cancels intent if authentication fails

### 3. Stripe Integration
- Payment Intent API (supports 3D Secure)
- Automatic retry on API failures
- Proper error handling
- Idempotent operations

### 4. Email Receipts
- Automatic receipt generation
- Templated emails via SES
- Includes payment and order details

## Prerequisites

Make sure you've already deployed:
- ✅ Bootstrap (terraform/bootstrap)
- ✅ Payment Service (terraform/payment-service/dev)
- ✅ Order Service (terraform/order-service/dev)
- ✅ DynamoDB tables exist
- ✅ API Gateway exists
- ✅ Stripe secret in Secrets Manager
- ✅ SES email template for receipts

## Deployment Steps

### Step 1: Install Dependencies

```bash
cd payment-service/src/payment_orchestrator
pip install -r requirements.txt -t .
cd ../../..
```

### Step 2: Deploy with Terraform

```bash
cd terraform/payment-service-durable
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

### Test Basic Payment

```bash
# Replace with your actual API endpoint
API_ENDPOINT="https://your-api-id.execute-api.us-east-1.amazonaws.com/payments/orchestrated"

curl -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "order-123",
    "amount": 1299.99,
    "currency": "USD",
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
    },
    "sendReceipt": true
  }'
```

### Expected Response (Success)

```json
{
  "message": "Payment processed successfully",
  "paymentId": "uuid-here",
  "orderId": "order-123",
  "amount": "1299.99",
  "currency": "USD",
  "status": "completed",
  "chargeId": "ch_xxxxx",
  "createdAt": "2024-06-10T10:30:00Z"
}
```

### Expected Response (3D Secure Required)

The function automatically handles 3D Secure:
1. Creates Payment Intent
2. Detects 3D Secure requirement
3. Waits for user authentication
4. Confirms payment after authentication
5. Returns success

### Expected Response (Payment Failed)

```json
{
  "error": "Payment confirmation failed",
  "details": "Card declined"
}
```

## Monitoring

### View Logs

```bash
aws logs tail /aws/lambda/travel-platform-payment-orchestrator-dev --follow
```

### View Metrics

```bash
aws cloudwatch get-metric-statistics \
  --namespace TravelPlatform/PaymentService \
  --metric-name PaymentCount \
  --dimensions Name=Operation,Value=PaymentOrchestrator \
  --start-time $(date -u -d '1 hour ago' --iso-8601) \
  --end-time $(date -u --iso-8601) \
  --period 300 \
  --statistics Sum
```

### Check Payment Status

```bash
# Get payment details
aws dynamodb get-item \
  --table-name travel-platform-payments-dev \
  --key '{"paymentId":{"S":"your-payment-id"}}'
```

## Stripe Integration

### Production Setup

1. **Get Stripe API Keys**
   - Sign up at https://stripe.com
   - Get test keys from Dashboard → Developers → API keys
   - Get production keys when ready

2. **Store in Secrets Manager**
   ```bash
   aws secretsmanager create-secret \
     --name travel-platform-stripe-key-dev \
     --secret-string '{"api_key":"sk_test_your_key_here"}'
   ```

3. **Update Lambda Code**
   Uncomment Stripe integration code in `app.py`:
   ```python
   import stripe
   stripe.api_key = stripe_key
   
   intent = stripe.PaymentIntent.create(
       amount=int(amount * 100),
       currency=currency.lower(),
       payment_method=payment_method.get('cardToken'),
       confirmation_method='manual',
       confirm=True
   )
   ```

### Testing with Stripe

Use Stripe test cards:
- Success: `tok_visa` or `4242 4242 4242 4242`
- Decline: `tok_chargeDeclined` or `4000 0000 0000 0002`
- 3D Secure: `tok_threeDSecure` or `4000 0027 6000 3184`

## 3D Secure Flow

### How It Works

1. **Frontend Integration**
   ```javascript
   // Create payment intent
   const response = await fetch('/payments/orchestrated', {
     method: 'POST',
     body: JSON.stringify(paymentData)
   });
   
   const result = await response.json();
   
   // If 3D Secure required, show modal
   if (result.requires_action) {
     const stripe = Stripe('pk_test_...');
     const { error } = await stripe.confirmCardPayment(
       result.client_secret
     );
     
     if (error) {
       // Handle error
     } else {
       // Payment succeeded
     }
   }
   ```

2. **Backend Handling**
   - Durable function creates Payment Intent
   - Detects `requires_action` status
   - Waits for webhook callback
   - Confirms payment after authentication

3. **Webhook Setup**
   ```bash
   # Configure Stripe webhook
   stripe listen --forward-to localhost:3000/webhooks/stripe
   ```

## Cost Estimate

Additional cost: ~$2-5/month for typical usage

- Lambda invocations: $0.20 per 1M requests
- Lambda duration: $0.0000166667 per GB-second
- DynamoDB: Included (existing tables)
- SES: $0.10 per 1,000 emails
- Stripe fees: 2.9% + $0.30 per transaction

## Comparison: Direct Stripe vs Durable Functions

| Feature | Direct Stripe | Durable Functions |
|---------|--------------|-------------------|
| **Retry Logic** | Manual | Automatic (built-in) |
| **3D Secure** | Manual polling | Automatic wait |
| **State Management** | Manual (DynamoDB) | Automatic |
| **Error Handling** | Manual | Automatic rollback |
| **Code Complexity** | High | Low |
| **Debugging** | Difficult | Easy (single context) |

## Security Best Practices

### 1. Never Store Card Details
```python
# ❌ BAD
payment_data = {
    'card_number': '4242424242424242',
    'cvv': '123'
}

# ✅ GOOD
payment_data = {
    'cardToken': 'tok_visa'  # Stripe token only
}
```

### 2. Use Stripe Tokens
- Frontend collects card details
- Stripe.js creates token
- Backend receives token only
- Never log card numbers

### 3. Validate Amounts
```python
# Always validate on backend
if amount <= 0:
    raise ValueError('Invalid amount')

if amount > 10000:  # Set reasonable limits
    raise ValueError('Amount exceeds limit')
```

### 4. Implement Idempotency
```python
# Use idempotency keys
idempotency_key = f"{order_id}-{timestamp}"
```

## Troubleshooting

### Issue: Payment always fails

**Check:**
1. Stripe secret exists and is valid
2. Using correct API key (test vs production)
3. Card token is valid

```bash
# Verify secret
aws secretsmanager get-secret-value \
  --secret-id travel-platform-stripe-key-dev

# Test Stripe key
curl https://api.stripe.com/v1/charges \
  -u sk_test_your_key:
```

### Issue: 3D Secure timeout

**Check:**
1. Webhook is configured
2. Frontend is handling client_secret
3. User completed authentication

```bash
# Check webhook events
stripe events list --limit 10
```

### Issue: Receipt email not sent

**Check:**
1. SES email verified
2. Email template exists
3. Lambda has SES permissions

```bash
# Verify email
aws ses list-verified-email-addresses

# Check template
aws ses get-template \
  --template-name payment-receipt-dev
```

## Refund Workflow

To implement refunds with durable functions:

```python
@durable_handler
def refund_handler(event, context, durable_context):
    # Step 1: Validate refund request
    # Step 2: Get payment record
    # Step 3: Create Stripe refund
    # Step 4: Update payment status
    # Step 5: Update order status
    # Step 6: Send refund confirmation email
    pass
```

## Cleanup

```bash
cd terraform/payment-service-durable
terraform destroy
```

## Next Steps

1. ✅ Deploy payment orchestrator
2. ✅ Configure Stripe webhook
3. ✅ Test with Stripe test cards
4. ✅ Test 3D Secure flow
5. ✅ Monitor CloudWatch logs
6. ✅ Review metrics
7. ✅ Update frontend integration

## Related Documentation

- [DURABLE_FUNCTIONS_GUIDE.md](DURABLE_FUNCTIONS_GUIDE.md) - Complete durable functions guide
- [ORDER_ORCHESTRATOR_DEPLOYMENT.md](ORDER_ORCHESTRATOR_DEPLOYMENT.md) - Order processing
- [Stripe Documentation](https://stripe.com/docs/api) - Stripe API reference
- [3D Secure Guide](https://stripe.com/docs/payments/3d-secure) - 3D Secure implementation

---

For questions or issues, check CloudWatch logs or review the Stripe dashboard for payment details.
