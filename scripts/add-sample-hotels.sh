#!/bin/bash

# Add sample hotels to DynamoDB for testing

echo "🏨 Adding Sample Hotels to DynamoDB..."
echo ""

# Hotel 1: Luxury Hotel in Paris
aws dynamodb put-item \
  --table-name hotels-local \
  --item '{
    "hotelId": {"S": "hotel-001"},
    "name": {"S": "Le Grand Paris"},
    "location": {"M": {
      "city": {"S": "Paris"},
      "country": {"S": "France"},
      "address": {"S": "123 Champs-Élysées"},
      "lat": {"N": "48.8566"},
      "lng": {"N": "2.3522"}
    }},
    "category": {"S": "luxury"},
    "starRating": {"N": "5"},
    "description": {"S": "Luxury 5-star hotel in the heart of Paris with stunning Eiffel Tower views"},
    "amenities": {"L": [
      {"S": "wifi"},
      {"S": "pool"},
      {"S": "gym"},
      {"S": "spa"},
      {"S": "restaurant"},
      {"S": "bar"}
    ]},
    "basePricePerNight": {"N": "350"},
    "totalRooms": {"N": "150"},
    "images": {"L": [
      {"S": "https://example.com/hotel1-1.jpg"},
      {"S": "https://example.com/hotel1-2.jpg"}
    ]}
  }' \
  --endpoint-url http://localhost:8000

echo "✅ Added Le Grand Paris"

# Hotel 2: Business Hotel in Tokyo
aws dynamodb put-item \
  --table-name hotels-local \
  --item '{
    "hotelId": {"S": "hotel-002"},
    "name": {"S": "Tokyo Business Center"},
    "location": {"M": {
      "city": {"S": "Tokyo"},
      "country": {"S": "Japan"},
      "address": {"S": "456 Shibuya"},
      "lat": {"N": "35.6762"},
      "lng": {"N": "139.6503"}
    }},
    "category": {"S": "business"},
    "starRating": {"N": "4"},
    "description": {"S": "Modern business hotel near Tokyo Station with conference facilities"},
    "amenities": {"L": [
      {"S": "wifi"},
      {"S": "gym"},
      {"S": "business_center"},
      {"S": "restaurant"},
      {"S": "airport_shuttle"}
    ]},
    "basePricePerNight": {"N": "180"},
    "totalRooms": {"N": "200"},
    "images": {"L": [
      {"S": "https://example.com/hotel2-1.jpg"}
    ]}
  }' \
  --endpoint-url http://localhost:8000

echo "✅ Added Tokyo Business Center"

# Hotel 3: Beach Resort in Bali
aws dynamodb put-item \
  --table-name hotels-local \
  --item '{
    "hotelId": {"S": "hotel-003"},
    "name": {"S": "Bali Beach Resort"},
    "location": {"M": {
      "city": {"S": "Bali"},
      "country": {"S": "Indonesia"},
      "address": {"S": "789 Seminyak Beach"},
      "lat": {"N": "-8.6705"},
      "lng": {"N": "115.2126"}
    }},
    "category": {"S": "resort"},
    "starRating": {"N": "5"},
    "description": {"S": "Tropical paradise resort with private beach access and spa"},
    "amenities": {"L": [
      {"S": "wifi"},
      {"S": "pool"},
      {"S": "spa"},
      {"S": "beach_access"},
      {"S": "restaurant"},
      {"S": "bar"}
    ]},
    "basePricePerNight": {"N": "280"},
    "totalRooms": {"N": "100"},
    "images": {"L": [
      {"S": "https://example.com/hotel3-1.jpg"},
      {"S": "https://example.com/hotel3-2.jpg"},
      {"S": "https://example.com/hotel3-3.jpg"}
    ]}
  }' \
  --endpoint-url http://localhost:8000

echo "✅ Added Bali Beach Resort"

# Hotel 4: Budget Hotel in London
aws dynamodb put-item \
  --table-name hotels-local \
  --item '{
    "hotelId": {"S": "hotel-004"},
    "name": {"S": "London Budget Inn"},
    "location": {"M": {
      "city": {"S": "London"},
      "country": {"S": "UK"},
      "address": {"S": "321 Oxford Street"},
      "lat": {"N": "51.5074"},
      "lng": {"N": "-0.1278"}
    }},
    "category": {"S": "budget"},
    "starRating": {"N": "3"},
    "description": {"S": "Affordable accommodation in central London"},
    "amenities": {"L": [
      {"S": "wifi"},
      {"S": "parking"}
    ]},
    "basePricePerNight": {"N": "85"},
    "totalRooms": {"N": "80"},
    "images": {"L": [
      {"S": "https://example.com/hotel4-1.jpg"}
    ]}
  }' \
  --endpoint-url http://localhost:8000

echo "✅ Added London Budget Inn"

# Hotel 5: Boutique Hotel in New York
aws dynamodb put-item \
  --table-name hotels-local \
  --item '{
    "hotelId": {"S": "hotel-005"},
    "name": {"S": "Manhattan Boutique"},
    "location": {"M": {
      "city": {"S": "New York"},
      "country": {"S": "USA"},
      "address": {"S": "555 5th Avenue"},
      "lat": {"N": "40.7128"},
      "lng": {"N": "-74.0060"}
    }},
    "category": {"S": "boutique"},
    "starRating": {"N": "4"},
    "description": {"S": "Stylish boutique hotel in the heart of Manhattan"},
    "amenities": {"L": [
      {"S": "wifi"},
      {"S": "gym"},
      {"S": "restaurant"},
      {"S": "bar"}
    ]},
    "basePricePerNight": {"N": "220"},
    "totalRooms": {"N": "50"},
    "images": {"L": [
      {"S": "https://example.com/hotel5-1.jpg"},
      {"S": "https://example.com/hotel5-2.jpg"}
    ]}
  }' \
  --endpoint-url http://localhost:8000

echo "✅ Added Manhattan Boutique"

echo ""
echo "🎉 Successfully added 5 sample hotels!"
echo ""
echo "Test with:"
echo "  curl http://localhost:3000/hotels?destination=Paris"
echo ""
