# API Gateway Resource Hierarchy Fix

## Problem Summary

The Cart Service API Gateway has stale resources in Terraform state causing incorrect path structure:

**Current (Incorrect):**
```
/cart
/remove
/{userId}
/items
/apply
/add
/
/promo
```

**Expected (Correct):**
```
/
/cart
/cart/{userId}
/items
/promo
```

## Root Cause

The Terraform state contains old resource definitions (`items_add`, `items_remove`, `promo_apply`) that no longer exist in the configuration. These were likely from an earlier version where each endpoint had its own resource path.

The current configuration correctly defines:
- `/cart/{userId}` - GET cart by user
- `/items` - POST (add) and DELETE (remove) operations
- `/promo` - POST apply promo code

Multiple HTTP methods should be on the same resource, not separate paths.

## Solution

Destroy and recreate the cart service to clear stale state.

### Step 1: Run the Fix Script

```bash
cd ~/aws-serverless-microservices-ai
chmod +x scripts/fix-cart-api-gateway.sh
./scripts/fix-cart-api-gateway.sh
```

### Step 2: Verify the Fix

After running the script, verify the API structure:

```bash
cd ~/aws-serverless-microservices-ai/terraform/cart-service/dev

# Get API ID
export API_ID=$(aws apigateway get-rest-apis --query "items[?name=='cart-service-dev'].id" --output text)

# Check resources
aws apigateway get-resources --rest-api-id $API_ID --query 'items[*].[path,id]' --output table

# Check methods on each resource
aws apigateway get-resources --rest-api-id $API_ID --query 'items[*].[path,resourceMethods]' --output json
```

Expected output should show:
- `/cart/{userId}` with GET method
- `/items` with POST and DELETE methods
- `/promo` with POST method

### Step 3: Test the API

```bash
API_URL=$(cd ~/aws-serverless-microservices-ai/terraform/cart-service/dev && terraform output -raw api_gateway_url)

# Test GET cart
curl "$API_URL/cart/user-123"

# Test POST add to cart
curl -X POST "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-123",
    "hotelId": "hotel-paris-001",
    "checkIn": "2026-06-01",
    "checkOut": "2026-06-05",
    "guests": 2,
    "roomType": "deluxe"
  }'

# Test DELETE remove from cart
curl -X DELETE "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-123",
    "cartItemId": "CART_ITEM_ID_FROM_PREVIOUS_RESPONSE"
  }'

# Test POST apply promo
curl -X POST "$API_URL/promo" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-123",
    "promoCode": "SAVE10"
  }'
```

## Why This Happened

The Terraform state got out of sync with the configuration. This can happen when:
1. Configuration is changed without proper state migration
2. Manual AWS console changes conflict with Terraform
3. Failed `terraform state rm` commands (as seen in the user's terminal)

## Prevention

To avoid this in the future:
1. Always use `terraform plan` before `apply` to review changes
2. Use `terraform state list` to verify state matches configuration
3. For major structural changes, consider `terraform destroy` and recreate
4. Never manually modify AWS resources managed by Terraform

## Module Logic Verification

The lambda-service module correctly implements 3-level resource hierarchy:

```hcl
# Level 1: Root resources (no parent_key)
root_level_resources = resources where parent_key == null

# Level 2: Children of root (parent_key points to root resource)
level2_resources = resources where parent_key exists in root_level_resources

# Level 3: Children of level 2 (parent_key points to level2 resource)
level3_resources = resources where parent_key exists in level2_resources
```

This logic is sound and working correctly in the hotel-service.

## Next Steps After Fix

1. Apply the same fix to order-service and payment-service if they have similar issues
2. Test all cart service endpoints thoroughly
3. Move on to fixing the agent-service Lambda packaging issue
4. Complete end-to-end testing of the entire microservices architecture
