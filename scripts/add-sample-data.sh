#!/bin/bash

# Add Sample Data to DynamoDB Tables
# This script populates the database with test data
# No Terraform needed - just AWS CLI

set -e

echo "Adding sample data to DynamoDB tables..."

# Hotel 1: Grand Hotel Paris
echo "Adding Grand Hotel Paris..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "hotel-001"},
    "name": {"S": "Grand Hotel Paris"},
    "location": {"M": {
      "city": {"S": "Paris"},
      "country": {"S": "France"},
      "address": {"S": "123 Champs-Élysées"}
    }},
    "description": {"S": "Luxury 5-star hotel in the heart of Paris with stunning views of the Eiffel Tower"},
    "starRating": {"N": "5"},
    "basePricePerNight": {"N": "250"},
    "category": {"S": "luxury"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Spa"},
      {"S": "Restaurant"},
      {"S": "Bar"},
      {"S": "Gym"}
    ]},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb"},
    "availableRooms": {"N": "50"}
  }'

# Hotel 2: Tokyo Bay Hotel
echo "Adding Tokyo Bay Hotel..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "hotel-002"},
    "name": {"S": "Tokyo Bay Hotel"},
    "location": {"M": {
      "city": {"S": "Tokyo"},
      "country": {"S": "Japan"},
      "address": {"S": "456 Shibuya District"}
    }},
    "description": {"S": "Modern hotel with panoramic views of Tokyo Bay and Mount Fuji"},
    "starRating": {"N": "4"},
    "basePricePerNight": {"N": "180"},
    "category": {"S": "business"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Restaurant"},
      {"S": "Bar"},
      {"S": "Gym"},
      {"S": "Business Center"}
    ]},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4"},
    "availableRooms": {"N": "75"}
  }'

# Hotel 3: New York Plaza
echo "Adding New York Plaza..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "hotel-003"},
    "name": {"S": "New York Plaza"},
    "location": {"M": {
      "city": {"S": "New York"},
      "country": {"S": "USA"},
      "address": {"S": "789 Fifth Avenue"}
    }},
    "description": {"S": "Iconic luxury hotel in Manhattan with world-class service"},
    "starRating": {"N": "5"},
    "basePricePerNight": {"N": "350"},
    "category": {"S": "luxury"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Spa"},
      {"S": "Restaurant"},
      {"S": "Bar"},
      {"S": "Gym"},
      {"S": "Concierge"}
    ]},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa"},
    "availableRooms": {"N": "100"}
  }'

# Hotel 4: London Bridge Inn
echo "Adding London Bridge Inn..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "hotel-004"},
    "name": {"S": "London Bridge Inn"},
    "location": {"M": {
      "city": {"S": "London"},
      "country": {"S": "UK"},
      "address": {"S": "321 Tower Bridge Road"}
    }},
    "description": {"S": "Charming boutique hotel near Tower Bridge with traditional English hospitality"},
    "starRating": {"N": "4"},
    "basePricePerNight": {"N": "200"},
    "category": {"S": "boutique"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Restaurant"},
      {"S": "Bar"},
      {"S": "Tea Room"}
    ]},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1566073771259-6a8506099945"},
    "availableRooms": {"N": "30"}
  }'

# Hotel 5: Dubai Oasis Resort
echo "Adding Dubai Oasis Resort..."
aws dynamodb put-item \
  --table-name hotel-service-hotels-dev \
  --item '{
    "hotelId": {"S": "hotel-005"},
    "name": {"S": "Dubai Oasis Resort"},
    "location": {"M": {
      "city": {"S": "Dubai"},
      "country": {"S": "UAE"},
      "address": {"S": "555 Palm Jumeirah"}
    }},
    "description": {"S": "Luxurious beachfront resort with private beach and world-class amenities"},
    "starRating": {"N": "5"},
    "basePricePerNight": {"N": "400"},
    "category": {"S": "resort"},
    "amenities": {"L": [
      {"S": "WiFi"},
      {"S": "Pool"},
      {"S": "Private Beach"},
      {"S": "Spa"},
      {"S": "Restaurant"},
      {"S": "Bar"},
      {"S": "Gym"},
      {"S": "Water Sports"}
    ]},
    "imageUrl": {"S": "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b"},
    "availableRooms": {"N": "200"}
  }'

echo ""
echo "✅ Sample data added successfully!"
echo ""
echo "Verify by searching hotels:"
echo "curl 'https://zttuy6f8bj.execute-api.us-east-1.amazonaws.com/dev/hotels?destination=Paris'"
