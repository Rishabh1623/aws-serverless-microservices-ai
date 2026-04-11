@echo off
REM Deploy Hotel Booking Durable Function (Windows)
REM This script handles the complete deployment process

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "LAMBDA_DIR=%PROJECT_ROOT%\hotel-service\src\booking_orchestrator"
set "TERRAFORM_DIR=%PROJECT_ROOT%\terraform\hotel-service-durable"

echo ==========================================
echo Deploying Hotel Booking Durable Function
echo ==========================================

REM Step 1: Install Lambda dependencies
echo.
echo Step 1: Installing Lambda dependencies...
cd /d "%LAMBDA_DIR%"

REM Create a clean package directory
if exist "package" rmdir /s /q package
mkdir package

REM Install dependencies to package directory
pip install -r requirements.txt -t package

REM Copy Lambda code to package
copy app.py package\

echo [32m✓ Dependencies installed[0m

REM Step 2: Validate Terraform configuration
echo.
echo Step 2: Validating Terraform configuration...
cd /d "%TERRAFORM_DIR%"

terraform init -upgrade
terraform validate

if errorlevel 1 (
    echo [31mTerraform validation failed![0m
    exit /b 1
)

echo [32m✓ Terraform configuration valid[0m

REM Step 3: Plan deployment
echo.
echo Step 3: Planning deployment...
terraform plan -out=tfplan

echo.
echo ==========================================
echo Review the plan above.
echo ==========================================
set /p confirm="Do you want to apply this plan? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Deployment cancelled.
    if exist tfplan del tfplan
    exit /b 0
)

REM Step 4: Apply deployment
echo.
echo Step 4: Applying deployment...
terraform apply tfplan
if exist tfplan del tfplan

echo.
echo ==========================================
echo [32m✓ Deployment Complete![0m
echo ==========================================

REM Get outputs
for /f "delims=" %%i in ('terraform output -raw api_endpoint 2^>nul') do set "API_ENDPOINT=%%i"
for /f "delims=" %%i in ('terraform output -raw function_name 2^>nul') do set "FUNCTION_NAME=%%i"

echo.
echo Deployment Details:
echo   Function Name: %FUNCTION_NAME%
echo   API Endpoint:  %API_ENDPOINT%
echo.
echo Test the endpoint:
echo   curl -X POST %API_ENDPOINT% ^
echo     -H "Content-Type: application/json" ^
echo     -d "{\"userId\":\"user123\",\"hotelId\":\"hotel-001\",\"roomId\":\"room-001\",\"checkIn\":\"2024-06-15\",\"checkOut\":\"2024-06-20\",\"guests\":2,\"guestDetails\":{\"name\":\"John Doe\",\"email\":\"john@example.com\"}}"
echo.
echo Monitor logs:
echo   aws logs tail /aws/lambda/%FUNCTION_NAME% --follow
echo.

endlocal
