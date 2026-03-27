@echo off
REM Start all microservices locally using SAM CLI
REM Each service runs on a different port

echo 🚀 Starting Local Microservices...
echo.

REM Check if SAM CLI is installed
where sam >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ SAM CLI not found. Please install it first:
    echo    https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker is not running. Please start Docker Desktop.
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

REM Get project root directory
set PROJECT_ROOT=%~dp0..

echo 📦 Starting product-service on port 3001...
cd /d "%PROJECT_ROOT%\product-service"
if not exist ".aws-sam" (
    echo    Building product-service...
    call sam build --quiet
)
start /B cmd /c "sam local start-api --port 3001 --warm-containers EAGER > product-service.log 2>&1"
echo.

echo 📦 Starting cart-service on port 3002...
cd /d "%PROJECT_ROOT%\cart-service"
if not exist ".aws-sam" (
    echo    Building cart-service...
    call sam build --quiet
)
start /B cmd /c "sam local start-api --port 3002 --warm-containers EAGER > cart-service.log 2>&1"
echo.

echo 📦 Starting order-service on port 3003...
cd /d "%PROJECT_ROOT%\order-service"
if not exist ".aws-sam" (
    echo    Building order-service...
    call sam build --quiet
)
start /B cmd /c "sam local start-api --port 3003 --warm-containers EAGER > order-service.log 2>&1"
echo.

echo 📦 Starting payment-service on port 3004...
cd /d "%PROJECT_ROOT%\payment-service"
if not exist ".aws-sam" (
    echo    Building payment-service...
    call sam build --quiet
)
start /B cmd /c "sam local start-api --port 3004 --warm-containers EAGER > payment-service.log 2>&1"
echo.

echo ⏳ Waiting for services to start (30 seconds)...
timeout /t 30 /nobreak >nul

echo.
echo ✅ All services started!
echo.
echo 📍 Service Endpoints:
echo    Product Service:  http://localhost:3001
echo    Cart Service:     http://localhost:3002
echo    Order Service:    http://localhost:3003
echo    Payment Service:  http://localhost:3004
echo.
echo 📋 Logs are in each service directory:
echo    product-service\product-service.log
echo    cart-service\cart-service.log
echo    order-service\order-service.log
echo    payment-service\payment-service.log
echo.
echo 🧪 Test endpoints:
echo    curl http://localhost:3001/products
echo    curl http://localhost:3002/cart/user123
echo.
echo Press any key to stop all services...
pause >nul

REM Stop services
echo.
echo 🛑 Stopping services...
taskkill /F /FI "WINDOWTITLE eq sam*" >nul 2>nul
echo ✅ Services stopped!
