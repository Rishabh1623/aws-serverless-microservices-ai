# AWS Step Functions Migration Plan

## Overview
Migrating from AWS Lambda Durable Functions (preview) to AWS Step Functions (production-ready) for workflow orchestration.

## What We're Removing
- Durable function orchestrators from base services
- Complex orchestrator Lambda functions
- Durable function-specific configurations

## What We're Implementing
AWS Step Functions workflows following AWS best practices:

### 1. Hotel Booking Workflow
**State Machine:** `hotel-booking-workflow-dev`

**Steps:**
1. Validate Request
2. Check Room Availability  
3. Reserve Room (with transaction)
4. Process Payment (with retry)
5. Confirm Booking
6. Send Email Notification
7. Error Handling & Rollback

**Benefits:**
- Visual workflow in AWS Console
- Built-in retry logic (exponential backoff)
- Automatic state persistence
- Error handling with catch blocks
- Parallel execution where possible

### 2. Order Processing Workflow  
**State Machine:** `order-processing-workflow-dev`

**Steps:**
1. Validate Order
2. Get Cart Items
3. Calculate Total (with promo codes)
4. Create Order Record
5. Process Payment (with retry)
6. Clear Cart
7. Send Confirmation Email
8. Error Handling & Cart Restoration

### 3. Payment Processing Workflow
**State Machine:** `payment-processing-workflow-dev`

**Steps:**
1. Validate Payment Request
2. Create Stripe Payment Intent
3. Wait for 3D Secure (if needed)
4. Confirm Payment
5. Update Order Status
6. Send Receipt Email
7. Error Handling & Refund

## Architecture

```
API Gateway → Lambda (Start Workflow) → Step Functions → Lambda Tasks → DynamoDB/SES
```

## Implementation Steps

### Phase 1: Clean Up (DONE)
- ✅ Remove orchestrator functions from hotel service
- ⏳ Remove orchestrator functions from order service  
- ⏳ Remove orchestrator functions from payment service

### Phase 2: Create Step Functions Module
- Create reusable Terraform module for Step Functions
- Define IAM roles and policies
- Configure CloudWatch logging
- Set up X-Ray tracing

### Phase 3: Implement Workflows
- Create state machine definitions (ASL - Amazon States Language)
- Deploy Step Functions
- Create starter Lambda functions
- Configure API Gateway integration

### Phase 4: Testing & Monitoring
- Test each workflow end-to-end
- Set up CloudWatch alarms
- Configure Step Functions metrics
- Create execution dashboards

## AWS Best Practices Applied

1. **Error Handling**
   - Retry with exponential backoff
   - Catch blocks for graceful degradation
   - Compensating transactions for rollback

2. **Security**
   - Least privilege IAM roles
   - Encryption at rest and in transit
   - VPC endpoints for private communication

3. **Observability**
   - CloudWatch Logs integration
   - X-Ray tracing enabled
   - Custom metrics for business KPIs

4. **Cost Optimization**
   - Express workflows for short-running tasks (<5 min)
   - Standard workflows for long-running (payment waits)
   - Appropriate timeout configurations

5. **Reliability**
   - Idempotency tokens
   - DynamoDB transactions
   - Automatic retries with jitter

## Migration Timeline

- **Phase 1:** 10 minutes (cleanup)
- **Phase 2:** 20 minutes (module creation)
- **Phase 3:** 30 minutes (workflow implementation)
- **Phase 4:** 15 minutes (testing)

**Total:** ~75 minutes

## Next Steps

1. Complete cleanup of orchestrator functions
2. Create Step Functions Terraform module
3. Implement hotel booking workflow first (pilot)
4. Test and validate
5. Roll out to order and payment workflows
6. Update documentation and deployment guides

## References

- [AWS Step Functions Best Practices](https://docs.aws.amazon.com/step-functions/latest/dg/best-practices.html)
- [Amazon States Language Specification](https://states-language.net/spec.html)
- [Step Functions Error Handling](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
