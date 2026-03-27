@echo off
REM Test all locally running microservices

echo 🧪 Testing Local Microservices...
echo.

echo 1️⃣  Product Service Tests
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Testing List Products...
curl -s http://localhost:3001/products
echo.
echo Testing Get Product...
curl -s http://localhost:3001/products/PROD001
echo.
echo Testing Filter by Category...
curl -s "http://localhost:3001/products?category=Electronics"
echo.
echo.

echo 2️⃣  Cart Service Tests
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Testing Add to Cart...
curl -s -X POST http://localhost:3002/cart/add ^
  -H "Content-Type: application/json" ^
  -d "{\"userId\":\"test-user\",\"productId\":\"PROD001\",\"quantity\":2}"
echo.
echo Testing Get Cart...
curl -s http://localhost:3002/cart/test-user
echo.
echo Testing Remove from Cart...
curl -s -X POST http://localhost:3002/cart/remove ^
  -H "Content-Type: application/json" ^
  -d "{\"userId\":\"test-user\",\"productId\":\"PROD001\"}"
echo.
echo.

echo 3️⃣  Order Service Tests
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Testing Create Order...
curl -s -X POST http://localhost:3003/orders ^
  -H "Content-Type: application/json" ^
  -d "{\"userId\":\"test-user\",\"items\":[{\"productId\":\"PROD001\",\"quantity\":1,\"price\":999.99}],\"total\":999.99}"
echo.
echo Testing List User Orders...
curl -s http://localhost:3003/orders/user/test-user
echo.
echo.

echo 4️⃣  Payment Service Tests
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Testing Process Payment...
curl -s -X POST http://localhost:3004/payments ^
  -H "Content-Type: application/json" ^
  -d "{\"orderId\":\"ORDER123\",\"amount\":999.99,\"paymentMethod\":\"credit_card\"}"
echo.
echo.

echo ✅ Testing Complete!
echo.
pause
