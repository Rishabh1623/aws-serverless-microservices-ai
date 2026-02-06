# Shopping Agent Service

## Overview

AI-powered shopping assistant using AWS Strands Agents SDK and Bedrock (Claude 3 Sonnet).

**Purpose:** Provide conversational shopping experience that orchestrates all microservices.

**Technology Stack:**
- AWS Strands Agents SDK
- AWS Bedrock (Claude 3 Sonnet)
- AWS Lambda (Python 3.11)
- API Gateway (HTTP API)

## Features

- Natural language product search
- Conversational cart management
- Intelligent order creation
- Order status tracking
- Context-aware responses

## Architecture

```
Customer: "I want to buy a laptop under $1000"
    ↓
API Gateway: POST /agent
    ↓
Agent Lambda (Strands + Bedrock)
    ↓
Tools:
├─ ProductTools.search_products() → Product Service API
├─ CartTools.add_to_cart() → Cart Service API
├─ OrderTools.create_order() → Order Service API
└─ PaymentTools.get_status() → Payment Service API
    ↓
Response: "I found 2 laptops under $1000..."
```

## API Endpoints

### POST /agent
Conversational interface for shopping

**Request:**
```json
{
  "message": "I want to buy a laptop under $1000",
  "userId": "user123",
  "sessionId": "session-abc" // optional, for context
}
```

**Response:**
```json
{
  "response": "I found 2 laptops under $1000: 1. Dell Laptop - $899...",
  "toolsUsed": ["search_products"],
  "context": {
    "productsFound": 2,
    "priceRange": "0-1000"
  }
}
```

## Environment Variables

- `PRODUCT_API_URL` - Product Service API endpoint
- `CART_API_URL` - Cart Service API endpoint
- `ORDER_API_URL` - Order Service API endpoint
- `PAYMENT_API_URL` - Payment Service API endpoint
- `BEDROCK_MODEL_ID` - Bedrock model (default: anthropic.claude-3-sonnet-20240229-v1:0)

## Cost

- Lambda: ~$2/month (1M requests free tier)
- Bedrock: ~$25/month (depends on usage)
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

# Deploy pipeline
cd ../pipeline
terraform init
terraform apply
```
