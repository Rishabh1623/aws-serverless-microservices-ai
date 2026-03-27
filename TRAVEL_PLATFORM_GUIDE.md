# 🏨 Travel Platform - Complete Guide

## Overview

This is a production-grade serverless travel booking platform with AI-powered personalization.

## What's Built

### Services (8 Total)

1. **Hotel Service** - Search, details, room availability
2. **Booking Service** - Reservations, cancellations
3. **Payment Service** - Payment processing
4. **Agent Service** - AI Travel Planner
5. **Troubleshooting Agent** - DevOps AI
6. **MCP Server** - Observability tools
7. **Product Service** - (Legacy, can be repurposed)
8. **Cart/Order Services** - (Legacy, can be repurposed)

### AI Features

**Travel Planner Tools:**
- `recommend_hotels()` - Personalized hotel suggestions
- `create_itinerary()` - Complete travel plans
- `suggest_packages()` - Bundle deals
- `compare_hotels()` - Side-by-side analysis

**Personalization:**
- User travel profiles
- Loyalty tiers (Bronze/Silver/Gold/Platinum)
- Conversation history
- Preference learning

**Dynamic Pricing:**
- Occupancy-based (80%+ = 20% increase)
- Seasonal multipliers
- Weekend premiums
- Early bird discounts (30+ days = 10% off)
- Event-based pricing

## Quick Start

### Option 1: Local Testing with SAM CLI

```bash
# 1. Start Hotel Service
cd hotel-service
sam build
sam local start-api --port 3000

# 2. Start DynamoDB Local (separate terminal)
docker run -p 8000:8000 amazon/dynamodb-local

# 3. Add Sample Hotels
bash scripts/add-sample-hotels.sh

# 4. Test
curl "http://localhost:3000/hotels?destination=Paris"
```

### Option 2: Deploy to AWS

```bash
# 1. Bootstrap Terraform State
cd terraform/bootstrap
terraform init
terraform apply

# 2. Deploy Hotel Service
cd ../hotel-service/dev
terraform init
terraform apply

# 3. Deploy Agent Service (with Travel Planner)
cd ../agent-service/dev
terraform init
terraform apply
```

## Example Use Cases

### 1. Romantic Getaway

**User:** "Plan a romantic 5-day trip to Paris for 2, budget $3000"

**AI Response:**
```json
{
  "itinerary": {
    "destination": "Paris",
    "duration": 5,
    "hotel": {
      "name": "Le Grand Paris",
      "category": "luxury",
      "pricePerNight": 350,
      "totalNights": 5,
      "loyaltyDiscount": 52.50,
      "finalPrice": 1697.50
    },
    "activities": [
      {"day": 1, "activity": "Eiffel Tower at sunset", "cost": 30},
      {"day": 2, "activity": "Louvre Museum", "cost": 20},
      {"day": 3, "activity": "Seine River cruise", "cost": 50},
      {"day": 4, "activity": "Versailles Palace", "cost": 40},
      {"day": 5, "activity": "Montmartre walking tour", "cost": 25}
    ],
    "dining": [
      {"restaurant": "Le Jules Verne", "type": "Fine Dining", "cost": 200},
      {"restaurant": "Café de Flore", "type": "Bistro", "cost": 80}
    ],
    "totalCost": 2862.50,
    "savings": 137.50
  }
}
```

### 2. Business Trip

**User:** "Need hotel in Tokyo for 3 nights, business trip, near conference center"

**AI Response:**
```json
{
  "recommendations": [
    {
      "hotelId": "hotel-002",
      "name": "Tokyo Business Center",
      "starRating": 4,
      "pricePerNight": 180,
      "totalPrice": 540,
      "reason": "Perfect for business travelers with meeting rooms, fast wifi, and airport shuttle",
      "highlights": [
        "5 min walk to Tokyo Conference Center",
        "Business center with printing/scanning",
        "Express check-in/out",
        "Complimentary breakfast"
      ],
      "loyaltyPoints": 150
    }
  ]
}
```

### 3. Family Vacation

**User:** "Family of 4, beach vacation, 7 nights, kids ages 6 and 9"

**AI Response:**
```json
{
  "package": {
    "name": "Bali Family Beach Package",
    "hotel": "Bali Beach Resort",
    "duration": 7,
    "included": [
      "7 nights accommodation (2 rooms)",
      "Kids club access",
      "Water park tickets",
      "Family cooking class",
      "Snorkeling tour",
      "All meals included"
    ],
    "priceBreakdown": {
      "basePrice": 2800,
      "groupDiscount": 420,
      "loyaltyDiscount": 238,
      "finalPrice": 2142,
      "savings": 658
    }
  }
}
```

## API Endpoints

### Hotel Service

```bash
# Search Hotels
GET /hotels?destination=Paris&checkIn=2024-06-15&checkOut=2024-06-20&guests=2

# Get Hotel Details
GET /hotels/{hotelId}

# Create Booking
POST /bookings
{
  "userId": "user123",
  "hotelId": "hotel-001",
  "roomId": "room-001",
  "checkIn": "2024-06-15",
  "checkOut": "2024-06-20",
  "guests": 2,
  "guestDetails": {
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  }
}
```

### AI Travel Planner

```bash
# Get Hotel Recommendations
POST /agent
{
  "message": "Recommend hotels in Paris for romantic getaway, 5 nights, budget $2000",
  "userId": "user123"
}

# Create Complete Itinerary
POST /agent
{
  "message": "Create 7-day itinerary for Tokyo, interested in culture and food",
  "userId": "user123"
}

# Compare Hotels
POST /agent
{
  "message": "Compare Le Grand Paris vs Manhattan Boutique vs Bali Beach Resort",
  "userId": "user123"
}
```

## Data Models

### Hotel
```python
{
  "hotelId": "hotel-001",
  "name": "Le Grand Paris",
  "location": {
    "city": "Paris",
    "country": "France",
    "address": "123 Champs-Élysées",
    "lat": 48.8566,
    "lng": 2.3522
  },
  "category": "luxury",
  "starRating": 5,
  "amenities": ["wifi", "pool", "gym", "spa"],
  "basePricePerNight": 350,
  "totalRooms": 150
}
```

### User Travel Profile
```python
{
  "userId": "user123",
  "preferredDestinations": ["Paris", "Tokyo", "Bali"],
  "preferredHotelCategories": ["luxury", "boutique"],
  "budgetRange": {"min": 100, "max": 500},
  "travelPurposes": ["leisure", "romantic"],
  "preferredAmenities": ["wifi", "pool", "spa"],
  "loyaltyTier": "gold",
  "loyaltyDiscount": 0.10,
  "pastBookings": ["booking-001", "booking-002"]
}
```

### Booking
```python
{
  "bookingId": "booking-001",
  "userId": "user123",
  "hotelId": "hotel-001",
  "roomId": "room-001",
  "checkIn": "2024-06-15",
  "checkOut": "2024-06-20",
  "guests": 2,
  "totalPrice": 1750,
  "status": "confirmed",
  "paymentStatus": "paid"
}
```

## Dynamic Pricing Algorithm

```python
def calculate_dynamic_price(
    base_price: float,
    check_in: date,
    check_out: date,
    occupancy_rate: float,
    season_multiplier: float = 1.0,
    event_multiplier: float = 1.0
) -> float:
    nights = (check_out - check_in).days
    total = base_price * nights
    
    # Occupancy-based pricing
    if occupancy_rate > 0.8:
        total *= 1.2  # 20% increase
    elif occupancy_rate > 0.6:
        total *= 1.1  # 10% increase
    elif occupancy_rate < 0.3:
        total *= 0.9  # 10% discount
    
    # Season multiplier
    total *= season_multiplier
    
    # Event multiplier
    total *= event_multiplier
    
    # Weekend premium
    weekend_nights = count_weekend_nights(check_in, nights)
    if weekend_nights > 0:
        total *= 1.05
    
    # Early bird discount
    days_advance = (check_in - date.today()).days
    if days_advance >= 30:
        total *= 0.9  # 10% discount
    
    return round(total, 2)
```

## Loyalty Program

| Tier | Bookings Required | Discount | Benefits |
|------|------------------|----------|----------|
| Bronze | 0-5 | 0% | Basic support |
| Silver | 6-15 | 5% | Priority support, late checkout |
| Gold | 16-30 | 10% | Room upgrades, free breakfast |
| Platinum | 31+ | 15% | All above + concierge, lounge access |

## Personalization Features

### Intent Detection
```python
INTENT_KEYWORDS = {
    'business': ['meeting', 'conference', 'work', 'professional'],
    'romantic': ['honeymoon', 'anniversary', 'couple', 'romantic'],
    'family': ['kids', 'children', 'family', 'playground'],
    'adventure': ['hiking', 'skiing', 'diving', 'adventure'],
    'wellness': ['spa', 'yoga', 'meditation', 'wellness']
}
```

### Complementary Suggestions
```python
COMPLEMENTARY_PRODUCTS = {
    'luxury_hotel': ['spa_package', 'fine_dining', 'private_tour'],
    'beach_resort': ['water_sports', 'snorkeling', 'sunset_cruise'],
    'business_hotel': ['meeting_room', 'airport_transfer', 'express_laundry']
}
```

## Testing

### Unit Tests
```bash
cd hotel-service
pytest tests/
```

### Integration Tests
```bash
# Start services locally
bash scripts/start-local-services.sh

# Run tests
bash scripts/test-local-services.sh
```

### Load Testing
```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:3000/hotels?destination=Paris
```

## Monitoring

### CloudWatch Metrics
- Hotel search requests/min
- Booking success rate
- Average booking value
- AI recommendation accuracy
- Dynamic pricing adjustments

### Alarms
- High error rate (>5%)
- Slow response time (>2s)
- Low availability (<99%)
- Cost anomalies

## Cost Estimation

### Monthly Costs (Production)

**Compute:**
- Lambda: ~$5/month (1M requests)
- API Gateway: ~$3.50/month

**Storage:**
- DynamoDB: ~$10/month (10GB, 1M reads/writes)
- S3 (state): ~$0.02/month

**AI:**
- Bedrock (Claude 3): ~$30/month (10K requests)

**Total: ~$50/month** for moderate traffic

### Per Booking Costs
- Lambda execution: $0.0001
- DynamoDB write: $0.00125
- Bedrock AI call: $0.003
- **Total per booking: ~$0.005**

## Security

- ✅ IAM least-privilege roles
- ✅ Encryption at rest (DynamoDB, S3)
- ✅ Encryption in transit (HTTPS)
- ✅ API Gateway throttling
- ✅ Input validation
- ✅ PII data protection
- ✅ Audit logging

## Next Steps

1. **Frontend** - React components for hotel search/booking
2. **Payment Integration** - Stripe/PayPal
3. **Email Notifications** - SES for confirmations
4. **Reviews & Ratings** - User feedback system
5. **Mobile App** - React Native
6. **Analytics Dashboard** - Booking trends, revenue

## Support

For issues or questions:
1. Check service logs in CloudWatch
2. Review Terraform state
3. Test locally with SAM CLI
4. Open GitHub issue

---

**Built with ❤️ using AWS Serverless + AI**
