# 📁 Project Structure

## Overview

Clean, production-ready serverless travel platform with only essential services.

```
serverless-microservices/
│
├── 📖 Documentation
│   ├── README.md                    # Project overview
│   ├── GETTING_STARTED.md           # Complete deployment guide
│   ├── PROJECT_STRUCTURE.md         # This file
│   └── LICENSE                      # MIT License
│
├── 🏨 Core Services (Travel Platform)
│   ├── hotel-service/               # Hotel search & booking
│   │   ├── src/
│   │   │   ├── search_hotels/       # Search hotels by location
│   │   │   ├── get_hotel/           # Get hotel details
│   │   │   ├── create_booking/      # Create reservation (with transactions)
│   │   │   └── booking_notification/# Send email confirmations
│   │   ├── tests/
│   │   ├── requirements.txt
│   │   └── README.md
│   │
│   ├── agent-service/               # AI Travel Assistant
│   │   ├── src/agent_handler/
│   │   │   ├── app.py               # Main agent logic
│   │   │   ├── conversation_manager.py
│   │   │   └── tools/
│   │   │       └── travel_planner_tools.py  # Hotel search, recommendations
│   │   ├── tests/
│   │   ├── requirements.txt
│   │   └── README.md
│   │
│   ├── order-service/               # Order management
│   │   ├── src/
│   │   │   ├── create_order/
│   │   │   ├── get_order/
│   │   │   └── list_user_orders/
│   │   ├── requirements.txt
│   │   └── template.yaml
│   │
│   └── payment-service/             # Payment processing
│       ├── src/
│       │   ├── process_payment/
│       │   └── get_payment/
│       ├── requirements.txt
│       └── template.yaml
│
├── 🎨 Frontend
│   ├── frontend/                    # React UI (Vite + Tailwind)
│   │   ├── src/
│   │   │   ├── pages/
│   │   │   │   ├── Home.jsx
│   │   │   │   ├── Products.jsx     # Hotel listings
│   │   │   │   ├── Cart.jsx         # Booking cart
│   │   │   │   ├── Orders.jsx       # Order history
│   │   │   │   ├── AIAssistant.jsx  # AI chat interface
│   │   │   │   └── AdminDashboard.jsx
│   │   │   ├── components/
│   │   │   ├── App.jsx
│   │   │   └── main.jsx
│   │   ├── package.json
│   │   └── README.md
│
├── 🏗️ Infrastructure (Terraform)
│   ├── terraform/
│   │   ├── bootstrap/               # Terraform state backend
│   │   │   ├── main.tf              # S3 + DynamoDB for state
│   │   │   └── README.md
│   │   │
│   │   ├── modules/                 # Reusable Terraform modules
│   │   │   ├── lambda-service/      # Lambda + API Gateway + DynamoDB
│   │   │   ├── cognito-auth/        # Cognito User Pool
│   │   │   ├── secrets-manager/     # AWS Secrets Manager
│   │   │   ├── event-driven/        # EventBridge + SNS + SQS
│   │   │   ├── dynamodb-backup/     # AWS Backup
│   │   │   ├── ses-notifications/   # Amazon SES
│   │   │   ├── api-gateway-authorizer/
│   │   │   ├── cloudwatch-dashboard/
│   │   │   ├── dax-cache/
│   │   │   ├── idempotency-table/
│   │   │   ├── lambda-layer/
│   │   │   ├── monitoring-dashboard/
│   │   │   └── cicd-pipeline/
│   │   │
│   │   ├── hotel-service/           # Hotel service infrastructure
│   │   │   ├── dev/
│   │   │   │   ├── main.tf          # All production modules integrated
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── providers.tf
│   │   │   │   ├── terraform.tf
│   │   │   │   └── lambda_layer.tf  # Shared libraries
│   │   │   ├── prod/
│   │   │   └── pipeline/
│   │   │
│   │   ├── agent-service/           # Agent service infrastructure
│   │   │   ├── dev/
│   │   │   ├── prod/
│   │   │   └── pipeline/
│   │   │
│   │   ├── order-service/           # Order service infrastructure
│   │   │   └── dev/
│   │   │
│   │   ├── payment-service/         # Payment service infrastructure
│   │   │   └── dev/
│   │   │
│   │   ├── mcp-servers/             # MCP observability server
│   │   │   └── main.tf
│   │   │
│   │   ├── buildspecs/              # CI/CD build specs
│   │   │   ├── terraform-apply-dev.yml
│   │   │   └── terraform-apply-prod.yml
│   │   │
│   │   └── README.md
│
├── 🔧 Shared Utilities
│   ├── shared/python/
│   │   ├── dynamodb_transactions.py # Atomic transactions, idempotency
│   │   ├── resilience.py            # Circuit breaker, retry, bulkhead
│   │   └── secrets_helper.py        # Secrets Manager helper
│
├── 📊 Observability (Optional)
│   ├── mcp-servers/
│   │   └── aws-observability/       # MCP server for AWS monitoring
│   │       ├── server.py
│   │       ├── requirements.txt
│   │       └── README.md
│
└── 🛠️ Scripts
    └── scripts/
        ├── add-sample-hotels.sh     # Populate sample data
        ├── start-local-services.sh  # Local testing with SAM
        ├── stop-local-services.sh
        └── test-local-services.sh
```

## Service Breakdown

### Hotel Service (Core)
**Purpose**: Hotel search, booking, and notifications  
**Tech**: Lambda + DynamoDB + EventBridge + SES  
**Features**:
- Search hotels by location, dates, price
- Get hotel details and room availability
- Create bookings with atomic transactions
- Send email confirmations via EventBridge

**Production Features**:
- ✅ DynamoDB transactions (prevents double-booking)
- ✅ Idempotency keys (prevents duplicates)
- ✅ Event-driven notifications
- ✅ Automated backups (30-day retention)
- ✅ Point-in-Time Recovery
- ✅ Lambda layer with shared libraries

### Agent Service (AI)
**Purpose**: AI-powered travel assistant  
**Tech**: Lambda + Bedrock (Claude 3) + Secrets Manager  
**Features**:
- Natural language hotel search
- Personalized recommendations
- Complete itinerary generation
- Context-aware responses

**Production Features**:
- ✅ Secure secret storage
- ✅ X-Ray distributed tracing
- ✅ CloudWatch alarms

### Order Service
**Purpose**: Order management and tracking  
**Tech**: Lambda + DynamoDB  
**Features**:
- Create orders
- Get order details
- List user orders

### Payment Service
**Purpose**: Payment processing  
**Tech**: Lambda + DynamoDB  
**Features**:
- Process payments
- Get payment status
- Handle refunds

## Key Files

### Documentation
- `README.md` - Project overview, quick start
- `GETTING_STARTED.md` - Complete deployment guide (prerequisites → deployment → testing)
- `PROJECT_STRUCTURE.md` - This file

### Configuration
- `.gitignore` - Git ignore rules
- `LICENSE` - MIT License

### Shared Libraries
- `shared/python/dynamodb_transactions.py` - Atomic operations
- `shared/python/resilience.py` - Circuit breaker, retry patterns
- `shared/python/secrets_helper.py` - Secrets Manager integration

## Infrastructure Modules

### Production Modules (Integrated)
1. **lambda-service** - Lambda + API Gateway + DynamoDB
2. **cognito-auth** - User authentication
3. **secrets-manager** - Secure credentials
4. **event-driven** - EventBridge + SNS + SQS
5. **dynamodb-backup** - Automated backups
6. **ses-notifications** - Email service
7. **api-gateway-authorizer** - JWT validation
8. **cloudwatch-dashboard** - Monitoring
9. **cicd-pipeline** - Automated deployments

## Deployment Order

1. **Bootstrap** - Terraform state backend
2. **Hotel Service** - Core booking functionality
3. **Agent Service** - AI assistant
4. **Order Service** - Order management
5. **Payment Service** - Payment processing
6. **Frontend** - React UI (optional)

## File Count Summary

- **Services**: 4 (hotel, agent, order, payment)
- **Lambda Functions**: 10+
- **Terraform Modules**: 13
- **DynamoDB Tables**: 6
- **API Gateways**: 4
- **Documentation Files**: 3

## What's NOT Included

❌ Cart service (legacy e-commerce)  
❌ Product service (legacy e-commerce)  
❌ Shopping-related code  
❌ E-commerce examples  

## What IS Included

✅ Complete travel booking platform  
✅ AI travel assistant  
✅ Production-grade features  
✅ Infrastructure as Code  
✅ Comprehensive documentation  
✅ Monitoring & observability  
✅ CI/CD pipelines  

---

**Status**: Production-ready  
**Last Updated**: 2024  
**Version**: 1.0.0
