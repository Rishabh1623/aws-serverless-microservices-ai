# Durable Function Deployment - Quick Guide

## Overview

This adds AWS Lambda Durable Functions to your existing travel platform as an alternative to the EventBridge-based booking orchestration.

## What You're Adding

A single Lambda function that orchestrates the entire booking workflow:
- Validates booking request
- Checks room availability  
- Creates booking with DynamoDB transaction
- Processes payment (with automatic retries)
- Sends confirmation email
- Handles rollback on failures

All with automatic state management and built-in retry logic!

## Prerequisites

Make sure you've already deployed:
- ✅ Bootstrap (terraform/bootstrap)
- ✅ Hotel Service (terraform/hotel-service/dev)
- ✅ DynamoDB tables exist
- ✅ API Gateway exists

## Deployment Steps (Following Your Workflow)

### Step 1: Install Dependencies

```bash
cd hotel-service/src/booking_orchestrator
pip install -r requirements.txt -t .
cd ../../..
```

### Step 2: Deploy with Terraform

```bash
cd terraform/hotel-service-durable
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

```bash
# Replace with your actual API endpoint
API_ENDPOINT="https://your-api-id.execute-api.us-east-1.amazonaws.com/bookings/orchestrated"

curl -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "hotelId": "hotel-001",
    "roomId": "room-001",
    "checkIn": "2024-06-15",
    "checkOut": "2024-06-20",
    "guests": 2,
    "guestDetails": {
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    },
    "paymentMethod": {
      "type": "credit_card",
      "token": "tok_visa"
    }
  }'
```

## Monitoring

```bash
# View logs
aws logs tail /aws/lambda/travel-platform-booking-orchestrator-dev --follow

# View metrics
aws cloudwatch get-metric-statistics \
  --namespace TravelPlatform/HotelService \
  --metric-name BookingCount \
  --dimensions Name=Operation,Value=BookingOrchestrator \
  --start-time $(date -u -d '1 hour ago' --iso-8601) \
  --end-time $(date -u --iso-8601) \
  --period 300 \
  --statistics Sum
```

## Cleanup (If Needed)

```bash
cd terraform/hotel-service-durable
terraform destroy
```

## Comparison: EventBridge vs Durable Functions

| Feature | EventBridge (Current) | Durable Functions (New) |
|---------|----------------------|-------------------------|
| State Management | Manual (DynamoDB) | Automatic |
| Retry Logic | Manual | Built-in |
| Code Complexity | Multiple Lambdas | Single function |
| Debugging | Distributed | Single context |
| Long Waits | Not supported | Up to 1 year |
| Cost During Waits | N/A | Zero |

## When to Use Which?

**Use EventBridge (Current)** when:
- You need loose coupling between services
- Multiple services consume the same events
- You want simple pub/sub patterns

**Use Durable Functions (New)** when:
- Workflow is tightly coupled
- You need automatic retry and state management
- You want code-first orchestration
- You need long-running workflows

## Cost

Additional cost: ~$2-5/month for typical usage

## More Information

See [DURABLE_FUNCTIONS_GUIDE.md](DURABLE_FUNCTIONS_GUIDE.md) for:
- Detailed architecture
- How checkpoint/replay works
- Best practices
- Migration guide

## Support

If you encounter issues:
1. Check CloudWatch logs
2. Verify prerequisites are deployed
3. Check IAM permissions
4. Review Terraform state: `terraform show`
