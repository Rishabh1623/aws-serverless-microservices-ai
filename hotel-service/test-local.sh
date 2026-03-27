#!/bin/bash
# Quick SAM local testing script

set -e

echo "🏨 Hotel Service - SAM Local Testing"
echo "===================================="
echo ""

# Check if SAM is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install it first:"
    echo "   https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

echo "✅ SAM CLI found: $(sam --version)"
echo ""

# Build
echo "📦 Building Lambda functions..."
sam build
echo ""

# Test functions
echo "🧪 Testing Lambda functions..."
echo ""

echo "1️⃣  Testing SearchHotelsFunction..."
sam local invoke SearchHotelsFunction -e events/search-hotels.json --no-event
echo ""

echo "2️⃣  Testing GetHotelFunction..."
sam local invoke GetHotelFunction -e events/get-hotel.json --no-event
echo ""

echo "3️⃣  Testing CreateBookingFunction..."
sam local invoke CreateBookingFunction -e events/create-booking.json --no-event
echo ""

echo "✅ All tests completed!"
echo ""
echo "💡 To start local API:"
echo "   sam local start-api --port 3001"
