# Payment Service

Handles payment processing with Stripe integration, refunds, and webhook events.

## Features

- ✅ Stripe payment processing
- ✅ Payment status tracking
- ✅ Refund processing
- ✅ Webhook event handling
- ✅ Idempotent operations
- ✅ X-Ray tracing
- ✅ CloudWatch metrics

## API Endpoints

### Process Payment
```bash
POST /payments
{
  "orderId": "order-123",
  "paymentMethod": "card",
  "cardToken": "tok_visa",
  "amount": 1299.99,
  "currency": "USD",
  "billingDetails": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Get Payment
```bash
GET /payments/{paymentId}
```

### Refund Payment
```bash
POST /payments/{paymentId}/refund
{
  "amount": 1299.99,
  "reason": "Customer requested cancellation"
}
```

### Stripe Webhook
```bash
POST /payments/webhook
# Stripe sends events here
```

## Stripe Integration

### Setup
1. Create Stripe account at https://stripe.com
2. Get API keys from Dashboard
3. Store in AWS Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name stripe-api-key \
  --secret-string '{"api_key":"sk_test_..."}'
```

### Webhook Configuration
1. Configure webhook URL in Stripe Dashboard
2. Add events: charge.succeeded, charge.failed, charge.refunded
3. Copy webhook signing secret to Secrets Manager

## Events Published

- `Payment Completed` - Payment successful
- `Payment Failed` - Payment failed
- `Payment Refunded` - Refund processed

## Testing

```bash
# Use Stripe test cards
# Success: 4242 4242 4242 4242
# Decline: 4000 0000 0000 0002

pytest tests/ -v
```

## Deployment

```bash
cd terraform/payment-service/dev
terraform init
terraform apply
```
