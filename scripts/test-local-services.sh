#!/bin/bash

# Test all locally running microservices

echo "🧪 Testing Local Microservices..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    local data=$4
    
    echo -n "Testing $name... "
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        echo "   Response: $body"
    fi
}

echo "1️⃣  Product Service Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "List Products" "http://localhost:3001/products"
test_endpoint "Get Product" "http://localhost:3001/products/PROD001"
test_endpoint "Filter by Category" "http://localhost:3001/products?category=Electronics"
echo ""

echo "2️⃣  Cart Service Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "Add to Cart" "http://localhost:3002/cart/add" "POST" \
    '{"userId":"test-user","productId":"PROD001","quantity":2}'
test_endpoint "Get Cart" "http://localhost:3002/cart/test-user"
test_endpoint "Remove from Cart" "http://localhost:3002/cart/remove" "POST" \
    '{"userId":"test-user","productId":"PROD001"}'
echo ""

echo "3️⃣  Order Service Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "Create Order" "http://localhost:3003/orders" "POST" \
    '{"userId":"test-user","items":[{"productId":"PROD001","quantity":1,"price":999.99}],"total":999.99}'
test_endpoint "List User Orders" "http://localhost:3003/orders/user/test-user"
echo ""

echo "4️⃣  Payment Service Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "Process Payment" "http://localhost:3004/payments" "POST" \
    '{"orderId":"ORDER123","amount":999.99,"paymentMethod":"credit_card"}'
echo ""

echo "✅ Testing Complete!"
echo ""
