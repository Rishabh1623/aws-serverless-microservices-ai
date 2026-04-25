#!/bin/bash

# Add sample hotels to DynamoDB dev environment

echo "Adding hotels to hotel-service-hotels-dev..."

# Hotel 1: Grand Plaza Hotel
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h123"},
    "name": {"S": "Grand Plaza Hotel"},
    "location": {
      "M": {
        "city": {"S": "New York"},
        "country": {"S": "USA"},
        "address": {"S": "123 Manhattan Ave"}
      }
    },
    "category": {"S": "luxury"},
    "starRating": {"N": "5"},
    "basePricePerNight": {"N": "250"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Gym"},
      {"S": "Restaurant"},
      {"S": "Spa"}
    ]},
    "description": {"S": "Luxury 5-star hotel in Manhattan with stunning city views"}
  }'

echo "✓ Added Grand Plaza Hotel (h123)"

# Hotel 2: Beach Paradise Resort
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h124"},
    "name": {"S": "Beach Paradise Resort"},
    "location": {
      "M": {
        "city": {"S": "Miami"},
        "country": {"S": "USA"},
        "address": {"S": "456 Ocean Drive"}
      }
    },
    "category": {"S": "resort"},
    "starRating": {"N": "5"},
    "basePricePerNight": {"N": "300"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Beach Access"},
      {"S": "Pool"},
      {"S": "Water Sports"},
      {"S": "Restaurant"}
    ]},
    "description": {"S": "Beachfront resort with private beach access and water sports"}
  }'

echo "✓ Added Beach Paradise Resort (h124)"

# Hotel 3: Downtown Business Hotel
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h125"},
    "name": {"S": "Downtown Business Hotel"},
    "location": {
      "M": {
        "city": {"S": "San Francisco"},
        "country": {"S": "USA"},
        "address": {"S": "789 Market Street"}
      }
    },
    "category": {"S": "business"},
    "starRating": {"N": "4"},
    "basePricePerNight": {"N": "220"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Business Center"},
      {"S": "Gym"},
      {"S": "Meeting Rooms"}
    ]},
    "description": {"S": "Modern business hotel in downtown SF with conference facilities"}
  }'

echo "✓ Added Downtown Business Hotel (h125)"

echo ""
echo "✅ All hotels added successfully!"
echo ""
echo "Verify with:"
echo "aws dynamodb scan --table-name hotel-service-hotels-dev --max-items 5"
