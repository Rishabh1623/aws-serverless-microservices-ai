# 🚀 Quick Fix Commands

**Use these commands to fix the Shopping Agent issue quickly.**

---

## Problem

AI Shopping Assistant says: "Unfortunately the cart service does not seem to be responding properly right now."

**Root Cause:** Shopping Agent Lambda has placeholder environment variables ("yes" instead of real API URLs)

---

## Solution (Choose One)

### Option 1: Automated Fix (Recommended)

```bash
cd ~/aws-serverless-microservices-ai
chmod +x FIX_AGENT_ENV_VARS.sh
./FIX_AGENT_ENV_VARS.sh
```

**Time:** 2-3 minutes

### Option 2: Manual Fix

```bash
cd ~/aws-serverless-microservices-ai/terraform/agent-service/dev

export PRODUCT_API="https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev"
export CART_API="https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev"
export ORDER_API="https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev"
export PAYMENT_API="https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev"

terraform apply \
  -var="product_api_url=$PRODUCT_API" \
  -var="cart_api_url=$CART_API" \
  -var="order_api_url=$ORDER_API" \
  -var="payment_api_url=$PAYMENT_API" \
  -auto-approve
```

**Time:** 2-3 minutes

---

## Verify Fix

```bash
# Check environment variables
aws lambda get-function-configuration \
  --function-name agent-service-dev \
  --query 'Environment.Variables' \
  --output json
```

**Expected:** All API URLs should be real URLs (not "yes")

---

## Test

```bash
# Test via API
curl -X POST "https://tvrhm1ftqe.execute-api.us-east-1.amazonaws.com/agent" \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me products", "userId": "test"}' | jq '.'
```

**Expected:** Agent responds with product information

---

## Optional: Add Sample Products

```bash
cd ~/aws-serverless-microservices-ai
chmod +x ADD_SAMPLE_PRODUCTS.sh
./ADD_SAMPLE_PRODUCTS.sh
```

Adds 3 sample laptops for testing.

---

## All API Endpoints

```
Product:   https://8s9xp3ko0d.execute-api.us-east-1.amazonaws.com/dev
Cart:      https://si0hbmhjk8.execute-api.us-east-1.amazonaws.com/dev
Order:     https://l7n8ar63w6.execute-api.us-east-1.amazonaws.com/dev
Payment:   https://80znv63zqa.execute-api.us-east-1.amazonaws.com/dev
Agent:     https://tvrhm1ftqe.execute-api.us-east-1.amazonaws.com
Frontend:  http://serverless-microservices-frontend-543927035352.s3-website-us-east-1.amazonaws.com
```

---

## After Fix

Test in frontend:
1. Open frontend URL
2. Click "AI Assistant"
3. Type: "Show me laptops under $1000"
4. Type: "Add the Dell laptop"
5. Type: "Create my order"

**Should work end-to-end!** ✅
