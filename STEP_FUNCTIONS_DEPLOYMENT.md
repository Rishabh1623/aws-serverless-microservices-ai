# AWS Step Functions Deployment Guide

## What's Been Created

### 1. Reusable Step Functions Module ✅
**Location:** `terraform/modules/step-functions-workflow/`

**Features:**
- CloudWatch Logs integration (30-day retention)
- X-Ray tracing enabled
- IAM roles with least privilege
- Support for Lambda invocation
- DynamoDB access
- Configurable workflow type (STANDARD/EXPRESS)

### 2. Hotel Booking Workflow ✅
**Location:** `terraform/workflows/hotel-booking/`

**Workflow Steps:**
1. **Validate Request** - Check booking data
2. **Check Availability** - Query room status from DynamoDB
3. **Reserve Room** - Update room status with conditional check
4. **Create Booking** - Store booking record
5. **Process Payment** - Handle payment with retries
6. **Send Email** - Confirmation notification
7. **Rollback** - Automatic cleanup on failures

**Error Handling:**
- Exponential backoff retries
- Conditional rollback on payment failure
- Graceful degradation (continues if email fails)

## Deployment Instructions

### Step 1: Deploy Hotel Booking Workflow

```bash
cd terraform/workflows/hotel-booking
terraform init
terraform plan
terraform apply
```

This will create:
- Step Functions state machine
- IAM role with permissions
- CloudWatch log group
- X-Ray tracing configuration

### Step 2: Test the Workflow

```bash
# Start execution
aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --input '{
    "hotelId": "h123",
    "roomId": "r456",
    "userId": "u789",
    "checkIn": "2026-05-01",
    "checkOut": "2026-05-05",
    "guestName": "John Doe",
    "guestEmail": "john@example.com"
  }'

# View execution
aws stepfunctions describe-execution \
  --execution-arn <execution-arn-from-above>

# View logs
aws logs tail /aws/vendedlogs/states/travel-platform-hotel-booking-dev --follow
```

### Step 3: View in AWS Console

1. Go to AWS Step Functions console
2. Find `travel-platform-hotel-booking-dev`
3. Click to see visual workflow
4. View execution history and logs

## Next: Order and Payment Workflows

The same pattern will be used for:

### Order Processing Workflow
**Steps:**
1. Validate order
2. Get cart items
3. Calculate total (with promo codes)
4. Create order record
5. Process payment (with retries)
6. Clear cart
7. Send confirmation email
8. Rollback on failure

### Payment Processing Workflow
**Steps:**
1. Validate payment request
2. Create Stripe Payment Intent
3. Wait for 3D Secure (if needed)
4. Confirm payment
5. Update order status
6. Send receipt email
7. Refund on failure

## Architecture Benefits

### vs. Lambda Durable Functions
- ✅ Production-ready (not preview)
- ✅ Visual workflow designer
- ✅ Built-in state persistence
- ✅ No custom code for orchestration
- ✅ Better observability

### vs. EventBridge Only
- ✅ Guaranteed execution order
- ✅ Built-in retry logic
- ✅ Automatic rollback
- ✅ Long-running workflows (up to 1 year)
- ✅ Better error handling

## Cost Estimate

**Step Functions Pricing:**
- Standard workflows: $0.025 per 1,000 state transitions
- Example: 10,000 bookings/month × 8 steps = 80,000 transitions = $2/month

**Total Additional Cost:** ~$2-5/month for all workflows

## Monitoring

### CloudWatch Metrics
- ExecutionsStarted
- ExecutionsSucceeded
- ExecutionsFailed
- ExecutionTime

### CloudWatch Alarms (Recommended)
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name hotel-booking-failures \
  --alarm-description "Alert on booking workflow failures" \
  --metric-name ExecutionsFailed \
  --namespace AWS/States \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

### X-Ray Service Map
View end-to-end traces in X-Ray console to see:
- Workflow execution path
- Lambda invocation times
- DynamoDB query performance
- Error locations

## Best Practices Applied

1. **Idempotency** - Safe to retry any step
2. **Timeouts** - Configured for each task
3. **Retries** - Exponential backoff with jitter
4. **Error Handling** - Catch blocks for graceful degradation
5. **Logging** - Full execution data logged
6. **Tracing** - X-Ray enabled for observability
7. **Least Privilege** - IAM roles grant only needed permissions
8. **Rollback** - Compensating transactions on failures

## Integration with Existing Services

The workflows use your existing Lambda functions:
- `hotel-service-create-booking-dev`
- `hotel-service-booking-notification-dev`

No changes needed to existing code!

## Next Steps

1. Deploy hotel booking workflow
2. Test with sample booking
3. Review execution in console
4. Implement order workflow (same pattern)
5. Implement payment workflow (same pattern)
6. Update API Gateway to trigger workflows
7. Set up CloudWatch alarms

## Support

- **AWS Step Functions Docs:** https://docs.aws.amazon.com/step-functions/
- **Best Practices:** https://docs.aws.amazon.com/step-functions/latest/dg/best-practices.html
- **Workflow Studio:** Visual designer in AWS Console
