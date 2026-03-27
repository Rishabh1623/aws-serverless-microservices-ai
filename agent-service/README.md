# AI Travel Agent Service

## Overview

AI-powered travel assistant using AWS Strands Agents SDK and Bedrock (Claude 3 Sonnet).

**Purpose:** Provide conversational travel planning experience with personalized hotel recommendations.

**Technology Stack:**
- AWS Strands Agents SDK
- AWS Bedrock (Claude 3 Sonnet)
- AWS Lambda (Python 3.11)
- API Gateway (HTTP API)

## Features

- Natural language hotel search
- Personalized travel recommendations
- Complete itinerary generation
- Context-aware responses
- Travel purpose detection (romantic, business, family, adventure)
- Natural language hotel search

## Architecture

```
Customer: "I want a romantic hotel in Bali for 3 nights"
    ↓
API Gateway: POST /agent
    ↓
Agent Lambda (Strands + Bedrock)
    ↓
Tools:
├─ TravelPlannerTools.search_hotels() → Hotel Service API
├─ TravelPlannerTools.get_recommendations() → AI Analysis
└─ TravelPlannerTools.create_booking() → Hotel Service API
    ↓
Response: "I found 3 romantic hotels in Bali..."
```

## API Endpoints

### POST /agent
Conversational interface for travel planning

**Request:**
```json
{
  "message": "I want a romantic hotel in Bali for 3 nights",
  "userId": "user123",
  "sessionId": "session-abc" // optional, for context
}
```

**Response:**
```json
{
  "response": "I found 3 romantic hotels in Bali: 1. Ocean View Resort - $180/night...",
  "toolsUsed": ["search_hotels", "suggest_room_upgrade"],
  "context": {
    "hotelsFound": 3,
    "travelPurpose": "romantic",
    "priceRange": "150-250"
  }
}
```

## Environment Variables

- `HOTEL_API_URL` - Hotel Service API endpoint
- `ORDER_API_URL` - Order Service API endpoint
- `PAYMENT_API_URL` - Payment Service API endpoint
- `BEDROCK_MODEL_ID` - Bedrock model (default: anthropic.claude-3-sonnet-20240229-v1:0)
- `SECRETS_ARN` - AWS Secrets Manager ARN for API configuration

## Cost

- Lambda: ~$2/month (1M requests free tier)
- Bedrock: ~$20-30/month (depends on usage)
  - Input: $3 per 1M tokens
  - Output: $15 per 1M tokens
  - Typical conversation: $0.01-0.05

## Deployment

See `terraform/agent-service/` for infrastructure as code.

```bash
# Deploy dev
cd terraform/agent-service/dev
terraform init
terraform apply

# Deploy prod
cd ../prod
terraform init
terraform apply
```

## Tools

### TravelPlannerTools
- `search_hotels()` - Search hotels by location, dates, preferences
- `get_hotel_details()` - Get detailed hotel information
- `create_booking()` - Create hotel reservation
- `generate_itinerary()` - Create day-by-day travel plan
- `suggest_extended_stay()` - Offer discounts for longer stays
- `suggest_premium_features()` - Ocean views, balconies, etc.
- `suggest_travel_protection()` - Insurance and cancellation coverage
