#!/bin/bash

# Fix the hotel booking workflow DynamoDB update issue

cd ~/aws-serverless-microservices-ai

# The issue is duplicate ExpressionAttributeValues in the ReserveRoom step
# We need to merge them into one and fix the timestamp reference

echo "Fixing workflow definition..."

# Pull latest
git pull origin main

# The fix has been pushed, now redeploy
cd terraform/workflows/hotel-booking
terraform apply -auto-approve

echo "Workflow updated! Test again with:"
echo "aws stepfunctions start-execution \\"
echo "  --state-machine-arn arn:aws:states:us-east-1:600105205879:stateMachine:travel-platform-hotel-booking-dev \\"
echo "  --input '{\"hotelId\":\"h123\",\"roomId\":\"r456\",\"userId\":\"u789\",\"checkIn\":\"2026-05-01\",\"checkOut\":\"2026-05-05\",\"guestName\":\"John Doe\",\"guestEmail\":\"john@example.com\"}'"
