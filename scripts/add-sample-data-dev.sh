#!/bin/bash

# Add sample hotels and rooms to DynamoDB dev environment

echo "🏨 Adding Sample Hotels and Rooms to DynamoDB (dev)..."
echo ""

# Hotel h123 with rooms
echo "Adding Hotel h123..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h123"},
    "name": {"S": "Grand Plaza Hotel"},
    "location": {"M": {
      "city": {"S": "New York"},
      "country": {"S": "USA"},
      "address": {"S": "123 Broadway"},
      "lat": {"N": "40.7128"},
      "lng": {"N": "-74.0060"}
    }},
    "category": {"S": "luxury"},
    "starRating": {"N": "5"},
    "description": {"S": "Luxury 5-star hotel in Manhattan with stunning city views"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Gym"},
      {"S": "Spa"},
      {"S": "Restaurant"},
      {"S": "Bar"}
    ]},
    "basePricePerNight": {"N": "350"},
    "totalRooms": {"N": "100"},
    "images": {"L": [
      {"S": "https://images.unsplash.com/photo-1566073771259-6a8506099945"}
    ]}
  }'

echo "✅ Added Grand Plaza Hotel"

# Add rooms for h123
echo "Adding rooms for h123..."

# Room r456 - Deluxe Suite (AVAILABLE)
aws dynamodb put-item \
  --table-name hotel-service-rooms-dev \
  --item '{
    "hotelId": {"S": "h123"},
    "roomId": {"S": "r456"},
    "roomType": {"S": "Deluxe Suite"},
    "basePrice": {"N": "250"},
    "capacity": {"N": "2"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "TV"},
      {"S": "Mini Bar"}
    ]},
    "available": {"BOOL": true}
  }'

echo "✅ Added room r456 (Deluxe Suite - Available)"

# Room r457 - Executive Suite (AVAILABLE)
aws dynamodb put-item \
  --table-name hotel-service-rooms-dev \
  --item '{
    "hotelId": {"S": "h123"},
    "roomId": {"S": "r457"},
    "roomType": {"S": "Executive Suite"},
    "basePrice": {"N": "350"},
    "capacity": {"N": "3"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "TV"},
      {"S": "Mini Bar"},
      {"S": "Balcony"}
    ]},
    "available": {"BOOL": true}
  }'

echo "✅ Added room r457 (Executive Suite - Available)"

# Room r458 - Standard Room (AVAILABLE)
aws dynamodb put-item \
  --table-name hotel-service-rooms-dev \
  --item '{
    "hotelId": {"S": "h123"},
    "roomId": {"S": "r458"},
    "roomType": {"S": "Standard Room"},
    "basePrice": {"N": "150"},
    "capacity": {"N": "2"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "TV"}
    ]},
    "available": {"BOOL": true}
  }'

echo "✅ Added room r458 (Standard Room - Available)"

# Hotel h124
echo ""
echo "Adding Hotel h124..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h124"},
    "name": {"S": "Beach Paradise Resort"},
    "location": {"M": {
      "city": {"S": "Miami"},
      "country": {"S": "USA"},
      "address": {"S": "456 Ocean Drive"},
      "lat": {"N": "25.7617"},
      {"N": "-80.1918"}
    }},
    "category": {"S": "resort"},
    "starRating": {"N": "5"},
    "description": {"S": "Beachfront resort with private beach access"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Beach Access"},
      {"S": "Spa"},
      {"S": "Restaurant"}
    ]},
    "basePricePerNight": {"N": "280"},
    "totalRooms": {"N": "80"},
    "images": {"L": [
      {"S": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4"}
    ]}
  }'

echo "✅ Added Beach Paradise Resort"

# Add rooms for h124
echo "Adding rooms for h124..."

aws dynamodb put-item \
  --table-name hotel-service-rooms-dev \
  --item '{
    "hotelId": {"S": "h124"},
    "roomId": {"S": "r501"},
    "roomType": {"S": "Ocean View Suite"},
    "basePrice": {"N": "300"},
    "capacity": {"N": "2"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "TV"},
      {"S": "Balcony"},
      {"S": "Ocean View"}
    ]},
    "available": {"BOOL": true}
  }'

echo "✅ Added room r501 (Ocean View Suite - Available)"

# Hotel h125
echo ""
echo "Adding Hotel h125..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "h125"},
    "name": {"S": "Downtown Business Hotel"},
    "location": {"M": {
      "city": {"S": "San Francisco"},
      "country": {"S": "USA"},
      "address": {"S": "789 Market Street"},
      "lat": {"N": "37.7749"},
      "lng": {"N": "-122.4194"}
    }},
    "category": {"S": "business"},
    "starRating": {"N": "4"},
    "description": {"S": "Modern business hotel in downtown SF"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Gym"},
      {"S": "Business Center"},
      {"S": "Restaurant"}
    ]},
    "basePricePerNight": {"N": "200"},
    "totalRooms": {"N": "120"},
    "images": {"L": [
      {"S": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa"}
    ]}
  }'

echo "✅ Added Downtown Business Hotel"

# Add rooms for h125
echo "Adding rooms for h125..."

aws dynamodb put-item \
  --table-name hotel-service-rooms-dev \
  --item '{
    "hotelId": {"S": "h125"},
    "roomId": {"S": "r601"},
    "roomType": {"S": "Business Suite"},
    "basePrice": {"N": "220"},
    "capacity": {"N": "2"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "TV"},
      {"S": "Desk"},
      {"S": "Coffee Maker"}
    ]},
    "available": {"BOOL": true}
  }'

echo "✅ Added room r601 (Business Suite - Available)"

echo ""
echo "🎉 Successfully added 3 hotels with 5 rooms!"
echo ""
echo "Test booking with:"
echo "  curl -X POST https://w2t61gs2lj.execute-api.us-east-1.amazonaws.com/dev/workflows/hotel-booking \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"hotelId\":\"h123\",\"roomId\":\"r456\",\"userId\":\"u999\",\"checkIn\":\"2026-08-01\",\"checkOut\":\"2026-08-05\",\"guestName\":\"Test User\",\"guestEmail\":\"test@example.com\"}'"
echo ""
