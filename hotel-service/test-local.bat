@echo off
REM Quick SAM local testing script for Windows

echo 🏨 Hotel Service - SAM Local Testing
echo ====================================
echo.

REM Check if SAM is installed
where sam >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ SAM CLI not found. Please install it first:
    echo    https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
    exit /b 1
)

echo ✅ SAM CLI found
sam --version
echo.

REM Build
echo 📦 Building Lambda functions...
sam build
echo.

REM Test functions
echo 🧪 Testing Lambda functions...
echo.

echo 1️⃣  Testing SearchHotelsFunction...
sam local invoke SearchHotelsFunction -e events/search-hotels.json --no-event
echo.

echo 2️⃣  Testing GetHotelFunction...
sam local invoke GetHotelFunction -e events/get-hotel.json --no-event
echo.

echo 3️⃣  Testing CreateBookingFunction...
sam local invoke CreateBookingFunction -e events/create-booking.json --no-event
echo.

echo ✅ All tests completed!
echo.
echo 💡 To start local API:
echo    sam local start-api --port 3001
