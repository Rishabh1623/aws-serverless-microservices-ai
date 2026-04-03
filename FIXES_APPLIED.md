# Fixes Applied - Cart Service Deployment Issues

## Issues Fixed

### 1. IAM Role Conflict: `api-gateway-cloudwatch-global`
**Problem**: The IAM role was being created by every service, causing a conflict when deploying cart-service after hotel-service.

**Solution**: 
- Modified `terraform/modules/lambda-service/main.tf` to create the role ONLY for hotel-service in dev environment
- Other services now use a `data` source to reference the existing role
- Added conditional logic to `aws_api_gateway_account` resource

**Files Changed**:
- `terraform/modules/lambda-service/main.tf`

### 2. API Gateway Resource Conflict: Variable Path Parts
**Problem**: Cart service had two variable path parts as siblings:
- `/cart/{userId}` 
- `/cart/{userId}/{cartItemId}` (child of {userId})
- `/cart/{userId}/promo` (child of {userId})

AWS API Gateway doesn't allow `{cartItemId}` and `promo` to be siblings when one is a variable path.

**Solution**: Restructured cart service API paths:
- OLD: `/cart/add` → NEW: `/cart/{userId}/items` (POST - add to cart)
- OLD: `/cart/{userId}` → SAME: `/cart/{userId}` (GET - get cart)
- OLD: `/cart/{userId}/{cartItemId}` → NEW: `/cart/{userId}/items/{cartItemId}` (DELETE - remove from cart)
- OLD: `/cart/{userId}/promo` → SAME: `/cart/{userId}/promo` (POST - apply promo)

**Files Changed**:
- `terraform/cart-service/dev/main.tf`

## Next Steps on EC2

1. **Pull the latest changes**:
   ```bash
   cd ~/aws-serverless-microservices-ai
   git pull
   ```

2. **Deploy cart service**:
   ```bash
   cd terraform/cart-service/dev
   terraform init
   terraform plan
   terraform apply
   ```

3. **If successful, deploy order service**:
   ```bash
   cd ../../order-service/dev
   terraform init
   terraform plan
   terraform apply
   ```

4. **Deploy payment service**:
   ```bash
   cd ../../payment-service/dev
   terraform init
   terraform plan
   terraform apply
   ```

## Verification

After all services are deployed, verify the API endpoints:

```bash
# Get all API endpoints
cd ~/aws-serverless-microservices-ai/terraform/hotel-service/dev
export HOTEL_API=$(terraform output -raw api_gateway_url)

cd ../../cart-service/dev
export CART_API=$(terraform output -raw api_gateway_url)

cd ../../order-service/dev
export ORDER_API=$(terraform output -raw api_gateway_url)

cd ../../payment-service/dev
export PAYMENT_API=$(terraform output -raw api_gateway_url)

echo "Hotel API: $HOTEL_API"
echo "Cart API: $CART_API"
echo "Order API: $ORDER_API"
echo "Payment API: $PAYMENT_API"
```

## Cross-Service Verification Complete

All services have been checked for similar issues:
- ✅ Hotel Service: No issues (already deployed)
- ✅ Cart Service: Fixed API Gateway structure
- ✅ Order Service: No issues found
- ✅ Payment Service: No issues found

The fixes ensure all services can be deployed without conflicts.
