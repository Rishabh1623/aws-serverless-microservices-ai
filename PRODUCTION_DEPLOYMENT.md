# Production Deployment Guide - All-in-One Architecture

## Overview
The durable functions have been merged into the base service deployments for production-ready, single-deployment architecture.

## Architecture Changes

### Before (Separate Deployments)
```
terraform/hotel-service/dev/        → Base CRUD operations
terraform/hotel-service-durable/    → Orchestration workflows
```

### After (All-in-One)
```
terraform/hotel-service/dev/        → Base + Orchestration (everything)
```

## What's Included

Each service now includes both simple and orchestrated endpoints:

### Hotel Service
- **GET /hotels** - Search hotels (simple)
- **GET /hotels/{id}** - Get hotel details (simple)
- **POST /bookings** - Create booking (simple, fast)
- **PUT /bookings** - Create booking with orchestration (complex workflow)

### Order Service
- **POST /orders** - Create order (simple)
- **GET /orders** - List user orders (simple)
- **DELETE /orders** - Cancel order (simple)
- **PUT /orders** - Create order with orchestration (complex workflow)

### Payment Service
- **POST /payments** - Process payment (simple)
- **GET /payments** - Get payment details (simple)
- **DELETE /payments** - Refund payment (simple)
- **PUT /payments** - Process payment with orchestration (complex workflow)

## Deployment Steps

### 1. Deploy Hotel Service (with orchestrator)
```bash
cd terraform/hotel-service/dev
terraform init
terraform plan
terraform apply
```

### 2. Deploy Order Service (with orchestrator)
```bash
cd ../../order-service/dev
terraform init
terraform plan
terraform apply
```

### 3. Deploy Payment Service (with orchestrator)
```bash
cd ../../payment-service/dev
terraform init
terraform plan
terraform apply
```

### 4. Deploy Cart Service (no orchestrator needed)
```bash
cd ../../cart-service/dev
terraform init
terraform plan
terraform apply
```

## Benefits of All-in-One Approach

1. **Single Deployment** - One terraform apply per service
2. **Simpler Management** - No separate orchestrator deployments
3. **Consistent State** - Single Terraform state file
4. **Easier Rollback** - Rollback everything together
5. **Better CI/CD** - Single pipeline per service
6. **Cost Efficient** - No duplicate infrastructure

## When to Use Each Endpoint

### Use Simple Endpoints (POST) When:
- Quick operations needed
- No complex workflows required
- Immediate response expected
- Testing or development

### Use Orchestrated Endpoints (PUT) When:
- Multi-step workflows needed
- Payment processing with retries
- Email notifications required
- Rollback capability needed
- Production bookings/orders

## API Examples

### Simple Booking (Fast)
```bash
curl -X POST https://api.example.com/bookings \
  -H "Content-Type: application/json" \
  -d '{"hotelId":"h123","roomId":"r456","userId":"u789"}'
```

### Orchestrated Booking (Robust)
```bash
curl -X PUT https://api.example.com/bookings \
  -H "Content-Type: application/json" \
  -d '{"hotelId":"h123","roomId":"r456","userId":"u789","checkIn":"2026-05-01","checkOut":"2026-05-05"}'
```

## Monitoring

All orchestrators include CloudWatch metrics:
- Execution duration
- Success/failure rates
- Retry attempts
- Step-by-step timing

View in CloudWatch:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=hotel-service-booking-orchestrator-dev \
  --start-time 2026-04-11T00:00:00Z \
  --end-time 2026-04-11T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum
```

## Rollback Strategy

If issues occur, rollback the entire service:
```bash
cd terraform/hotel-service/dev
terraform apply -target=module.hotel_service -auto-approve
```

Or rollback to previous git commit:
```bash
git revert HEAD
terraform apply
```

## Migration from Separate Deployments

If you already deployed separate durable functions:

1. **Destroy separate deployments:**
```bash
cd terraform/hotel-service-durable
terraform destroy

cd ../order-service-durable
terraform destroy

cd ../payment-service-durable
terraform destroy
```

2. **Deploy all-in-one:**
```bash
cd ../hotel-service/dev
terraform apply

cd ../../order-service/dev
terraform apply

cd ../../payment-service/dev
terraform apply
```

## Cost Comparison

### Separate Deployments
- 3 base services + 3 orchestrators = 6 deployments
- 6 Lambda functions for orchestration
- 6 CloudWatch log groups
- More complex state management

### All-in-One
- 3 services = 3 deployments
- 3 Lambda functions for orchestration
- 3 CloudWatch log groups
- Simpler state management

**Estimated savings:** 30-40% reduction in management overhead

## Next Steps

1. Deploy all services using the steps above
2. Test both simple and orchestrated endpoints
3. Monitor CloudWatch metrics
4. Set up alarms for orchestrator failures
5. Configure auto-scaling if needed

## Support

For issues or questions:
- Check CloudWatch logs: `/aws/lambda/<function-name>`
- Review Terraform state: `terraform show`
- Validate configuration: `terraform validate`
