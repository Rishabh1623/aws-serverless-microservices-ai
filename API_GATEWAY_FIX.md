# API Gateway Integration Fix

## Issue
The durable function Terraform configurations had an error when trying to look up API Gateway by name:
```
Error: Missing required argument
  on main.tf line 178, in data "aws_apigatewayv2_api" "main":
 178: data "aws_apigatewayv2_api" "main" {

The argument "api_id" is required, but no definition was found.
```

## Root Cause
The `aws_apigatewayv2_api` data source doesn't support lookup by `name` - it requires `api_id` to be provided.

## Solution
Made API Gateway integration **optional** in all three durable function deployments:
- `terraform/hotel-service-durable/main.tf`
- `terraform/order-service-durable/main.tf`
- `terraform/payment-service-durable/main.tf`

### Changes Made
1. Added `api_gateway_id` variable (defaults to empty string)
2. Made API Gateway resources conditional using `count`
3. Updated outputs to show "Not configured" when API Gateway is skipped

## Deployment

### Option 1: Deploy Without API Gateway (Recommended for Initial Setup)
```bash
cd terraform/hotel-service-durable
terraform init
terraform plan
terraform apply
```

The Lambda functions will be created and can be invoked directly via AWS SDK or CLI.

### Option 2: Deploy With API Gateway Integration
If you have an existing API Gateway v2 HTTP API, provide its ID:

```bash
cd terraform/hotel-service-durable
terraform init
terraform plan -var="api_gateway_id=abc123xyz"
terraform apply -var="api_gateway_id=abc123xyz"
```

Or create a `terraform.tfvars` file:
```hcl
api_gateway_id = "abc123xyz"
```

## Invoking Durable Functions

### Direct Lambda Invocation (No API Gateway)
```bash
aws lambda invoke \
  --function-name travel-platform-booking-orchestrator-dev \
  --payload '{"hotelId":"hotel-123","roomId":"room-456","userId":"user-789","checkIn":"2026-05-01","checkOut":"2026-05-05"}' \
  response.json
```

### Via API Gateway (If Configured)
```bash
curl -X POST https://abc123xyz.execute-api.us-east-1.amazonaws.com/bookings/orchestrated \
  -H "Content-Type: application/json" \
  -d '{"hotelId":"hotel-123","roomId":"room-456","userId":"user-789","checkIn":"2026-05-01","checkOut":"2026-05-05"}'
```

## Why This Approach?

1. **Simpler Initial Deployment**: No need to create or reference API Gateway
2. **Flexibility**: Each service can use its own API Gateway or share one
3. **Direct Invocation**: Durable functions can be called from other services via Lambda SDK
4. **Optional Integration**: Add API Gateway later when needed

## Next Steps

1. Deploy all three durable functions without API Gateway:
   ```bash
   # Hotel service
   cd terraform/hotel-service-durable
   terraform init && terraform apply -auto-approve
   
   # Order service
   cd ../order-service-durable
   terraform init && terraform apply -auto-approve
   
   # Payment service
   cd ../payment-service-durable
   terraform init && terraform apply -auto-approve
   ```

2. Test Lambda functions directly using AWS CLI or SDK

3. (Optional) Create a shared API Gateway and integrate all services:
   ```bash
   # Create API Gateway v2 HTTP API
   aws apigatewayv2 create-api \
     --name travel-platform-api-dev \
     --protocol-type HTTP
   
   # Get the API ID and update terraform.tfvars
   # Then re-apply with api_gateway_id variable
   ```

## Commit
Fixed API Gateway data source error by making integration optional. All durable functions can now be deployed without requiring an existing API Gateway.
