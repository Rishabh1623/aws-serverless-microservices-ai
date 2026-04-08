# Cart Service Complete Fix

## Issues Found

1. EC2 has old code - `git pull` was not run
2. Lambda has old code with xray_recorder reference
3. API Gateway still has old `/{userId}` resource

## Complete Fix Steps

Run these commands on EC2 in order:

```bash
# Step 1: Pull latest code
cd ~/aws-serverless-microservices-ai
git pull

# Step 2: Verify the configuration is correct
cd terraform/cart-service/dev
cat main.tf | grep -A 10 "api_gateway_resources ="
# Should show only: cart, items, promo (NO cart_user)

# Step 3: Destroy and recreate to clear old resources
terraform destroy -auto-approve
terraform apply -auto-approve

# Step 4: Verify API Gateway structure
export API_ID=$(aws apigateway get-rest-apis --query "items[?name=='cart-service-dev'].id" --output text)
aws apigateway get-resources --rest-api-id $API_ID --query 'items[*].[path]' --output table
# Should show: /, /cart, /items, /promo (NO /{userId})

# Step 5: Test the API
API_URL=$(terraform output -raw api_gateway_url)
curl "$API_URL/cart?userId=user-123"
# Should return: {"userId": "user-123", "items": [], "itemCount": 0, ...}
```

## Expected Results

### API Gateway Paths
```
/
/cart
/items  
/promo
```

### API Endpoints
- GET /cart?userId=xxx - Get user's cart
- POST /items - Add item to cart
- DELETE /items - Remove item from cart
- POST /promo - Apply promo code

### Test Commands
```bash
# Get cart (empty initially)
curl "$API_URL/cart?userId=user-123"

# Add item
curl -X POST "$API_URL/items" -H "Content-Type: application/json" -d '{
  "userId": "user-123",
  "hotelId": "hotel-paris-001",
  "checkIn": "2026-06-01",
  "checkOut": "2026-06-05",
  "guests": 2,
  "roomType": "deluxe"
}'

# Get cart (should have 1 item)
curl "$API_URL/cart?userId=user-123"
```

## Why This Happened

1. Local changes were committed and pushed
2. EC2 didn't pull the changes (`git pull` was skipped)
3. Terraform deployed with old configuration
4. Lambda code wasn't updated

## Prevention

Always run `git pull` on EC2 before `terraform apply`!
