# AWS Lambda Durable Functions Implementation Guide

This guide explains how we've implemented AWS Lambda Durable Functions in the travel platform project as an alternative to Step Functions orchestration.

## What Are Lambda Durable Functions?

Lambda Durable Functions enable you to build resilient multi-step applications that can execute for up to one year while maintaining reliable progress despite interruptions. Key features:

- **Automatic State Management**: Built-in checkpointing and replay
- **Long-Running Workflows**: Execute for up to 1 year
- **Cost Efficient**: Pay only for active execution time (no charges during waits)
- **Automatic Retries**: Built-in retry logic for each step
- **Familiar Programming**: Write in Python, JavaScript, TypeScript, or Java

## Architecture Comparison

### Before: EventBridge Orchestration
```
API Gateway → create_booking Lambda → EventBridge → booking_notification Lambda
                                    ↓
                                DynamoDB (manual state)
```

### After: Durable Function
```
API Gateway → booking_orchestrator Durable Function
              ├─ Step 1: Validate request
              ├─ Step 2: Check availability
              ├─ Step 3: Create booking
              ├─ Step 4: Process payment (with retries)
              ├─ Step 5: Confirm booking
              ├─ Step 6: Send email
              └─ Step 7: Wait & send reminder (optional)
              
              All state managed automatically!
```

## Implementation: Hotel Booking Orchestrator

### Location
- **Lambda Code**: `hotel-service/src/booking_orchestrator/app.py`
- **Terraform Module**: `terraform/modules/durable-function/`
- **Deployment Config**: `terraform/hotel-service-durable/`

### Key Features

1. **Multi-Step Workflow**
   - Validates booking request
   - Checks room availability
   - Creates booking with DynamoDB transaction
   - Processes payment with automatic retries
   - Sends confirmation email
   - Optionally waits for check-in date and sends reminder

2. **Automatic Retry Logic**
   ```python
   payment_result = durable_context.step(
       'process_payment',
       process_payment_step,
       booking_id,
       total_price,
       payment_method,
       max_retries=3,           # Retry up to 3 times
       retry_delay_seconds=5    # Wait 5 seconds between retries
   )
   ```

3. **Rollback on Failure**
   ```python
   if not payment_result['success']:
       # Automatically rollback booking
       durable_context.step(
           'rollback_booking',
           rollback_booking_step,
           booking_id,
           room_id
       )
   ```

4. **Long-Running Capabilities**
   ```python
   # Wait until check-in date (no compute charges during wait!)
   durable_context.wait_until(reminder_date)
   
   # Send reminder email
   durable_context.step('send_reminder_email', ...)
   ```

## How It Works

### Checkpoint & Replay Mechanism

When a durable function runs:

1. **Execution**: Each `step()` creates a checkpoint
2. **Interruption**: If function fails or times out
3. **Replay**: Function restarts from beginning
4. **Skip Completed**: Uses stored results for completed steps
5. **Resume**: Continues from where it left off

Example:
```
First Run:  [✓ Step 1] [✓ Step 2] [✗ Step 3 FAILED]
Replay:     [⏭ Step 1] [⏭ Step 2] [▶ Step 3 RETRY]
```

### Durable Operations

The SDK provides two main primitives:

1. **Steps**: Execute business logic with checkpointing
   ```python
   result = durable_context.step(
       'step_name',
       function_to_execute,
       arg1, arg2,
       max_retries=3
   )
   ```

2. **Waits**: Suspend execution without charges
   ```python
   # Wait for specific duration
   durable_context.wait(timedelta(hours=24))
   
   # Wait until specific time
   durable_context.wait_until(datetime(2024, 6, 15))
   ```

## Installation & Setup

### 1. Install SDK

```bash
cd hotel-service/src/booking_orchestrator
pip install aws-lambda-durable -t .
```

### 2. Update Lambda Handler

```python
from aws_lambda_durable import durable_handler, DurableContext

@durable_handler
def lambda_handler(event, context, durable_context: DurableContext):
    # Your workflow logic using durable_context.step()
    pass
```

### 3. Deploy with Terraform

```bash
cd terraform/hotel-service-durable
terraform init
terraform plan
terraform apply
```

### 4. Configure Environment Variables

The durable function needs:
- `BOOKING_TABLE`: DynamoDB bookings table
- `ROOM_TABLE`: DynamoDB rooms table
- `HOTEL_TABLE`: DynamoDB hotels table
- `FROM_EMAIL`: SES sender email
- `TEMPLATE_NAME`: SES email template

## API Usage

### Endpoint
```
POST /bookings/orchestrated
```

### Request Body
```json
{
  "userId": "user123",
  "hotelId": "hotel-001",
  "roomId": "room-001",
  "checkIn": "2024-06-15",
  "checkOut": "2024-06-20",
  "guests": 2,
  "idempotencyKey": "unique-request-id",
  "specialRequests": "Late check-in",
  "guestDetails": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  },
  "paymentMethod": {
    "type": "credit_card",
    "token": "tok_visa"
  },
  "sendReminder": true
}
```

### Response (Success)
```json
{
  "message": "Booking created successfully",
  "bookingId": "booking-uuid",
  "status": "confirmed",
  "totalPrice": "600.00",
  "paymentTransactionId": "txn-uuid",
  "createdAt": "2024-06-10T10:30:00Z"
}
```

### Response (Failure)
```json
{
  "error": "Room not available for selected dates"
}
```

## Benefits Over EventBridge

| Feature | EventBridge | Durable Functions |
|---------|-------------|-------------------|
| State Management | Manual (DynamoDB) | Automatic |
| Retry Logic | Manual implementation | Built-in |
| Code Complexity | Multiple Lambda functions | Single function |
| Debugging | Distributed traces | Single execution context |
| Long Waits | Requires Step Functions | Native support |
| Cost During Waits | N/A | Zero compute charges |
| Orchestration Service | Required | Not required |

## When to Use Durable Functions vs Step Functions

### Use Durable Functions When:
- Workflow is tightly coupled with business logic
- You prefer code-first approach
- Need to minimize infrastructure components
- Want to leverage existing Lambda development workflow
- Workflow logic changes frequently

### Use Step Functions When:
- Need visual workflow designer
- Require native integrations with 220+ AWS services
- Prefer declarative workflow definitions
- Need workflow versioning and rollback
- Want zero-maintenance orchestration infrastructure

## Monitoring & Debugging

### CloudWatch Logs
All execution steps are logged with JSON format:
```json
{
  "timestamp": "2024-06-10T10:30:00Z",
  "executionId": "exec-uuid",
  "step": "process_payment",
  "status": "completed",
  "duration": 150
}
```

### CloudWatch Metrics
Custom metrics published:
- `BookingCount`: Number of successful bookings
- `Duration`: Execution time per step
- `Revenue`: Total booking revenue
- `Errors`: Failed operations

### X-Ray Tracing
Enable X-Ray for distributed tracing:
```python
# Add to Lambda configuration
tracing_config = {
    'Mode': 'Active'
}
```

## Best Practices

1. **Idempotency**: Always use idempotency keys
   ```python
   idempotency_key = f"{user_id}-{room_id}-{check_in}"
   ```

2. **Step Granularity**: Keep steps focused and atomic
   ```python
   # Good: Single responsibility
   durable_context.step('validate_request', validate_fn, data)
   durable_context.step('check_availability', check_fn, room_id)
   
   # Bad: Too much in one step
   durable_context.step('do_everything', mega_fn, all_data)
   ```

3. **Error Handling**: Use try-catch within steps
   ```python
   def process_payment_step(booking_id, amount):
       try:
           # Payment logic
           return {'success': True}
       except PaymentError as e:
           return {'success': False, 'error': str(e)}
   ```

4. **Timeouts**: Set appropriate max_execution_time
   ```python
   # For workflows with long waits
   max_execution_time = 2592000  # 30 days
   
   # For quick workflows
   max_execution_time = 3600  # 1 hour
   ```

5. **Testing**: Test each step independently
   ```python
   def test_validate_booking_request():
       result = validate_booking_request(sample_body)
       assert result['userId'] == 'user123'
   ```

## Migration Path

To migrate existing EventBridge workflows to durable functions:

1. **Identify Workflow**: Map out current event-driven flow
2. **Extract Steps**: Convert each Lambda into a step function
3. **Add Orchestration**: Wrap in durable_handler
4. **Test Locally**: Use moto for DynamoDB mocking
5. **Deploy Gradually**: Run both systems in parallel
6. **Monitor**: Compare metrics and error rates
7. **Switch Traffic**: Update API Gateway routes
8. **Deprecate Old**: Remove EventBridge rules

## Additional Use Cases

Beyond hotel bookings, durable functions are perfect for:

1. **Order Processing**
   - Validate order → Process payment → Update inventory → Ship → Notify

2. **AI Workflows**
   - User query → Model inference → Human review → Response generation

3. **Multi-Step Approvals**
   - Submit request → Manager approval → Finance approval → Execute

4. **Scheduled Reminders**
   - Create event → Wait until reminder time → Send notification

## Resources

- [AWS Lambda Durable Functions Documentation](https://docs.aws.amazon.com/lambda/latest/dg/durable-functions.html)
- [Durable Execution SDK (Python)](https://github.com/aws/aws-lambda-durable-python)
- [Best Practices Guide](https://docs.aws.amazon.com/lambda/latest/dg/durable-functions-best-practices.html)
- [Monitoring Guide](https://docs.aws.amazon.com/lambda/latest/dg/durable-functions-monitoring.html)

## Next Steps

1. Review the implementation in `hotel-service/src/booking_orchestrator/app.py`
2. Deploy using Terraform: `cd terraform/hotel-service-durable && terraform apply`
3. Test the API endpoint with sample booking requests
4. Monitor execution in CloudWatch Logs
5. Consider migrating other workflows (order processing, payment flows)

---

For questions or issues, refer to the main project documentation or AWS support.
