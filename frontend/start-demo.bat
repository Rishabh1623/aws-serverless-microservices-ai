@echo off
echo ========================================
echo AWS Serverless Microservices Frontend
echo ========================================
echo.

echo Installing dependencies...
call npm install

echo.
echo Starting development server...
echo.
echo Frontend will be available at:
echo http://localhost:5173
echo.
echo Press Ctrl+C to stop the server
echo.

call npm run dev
