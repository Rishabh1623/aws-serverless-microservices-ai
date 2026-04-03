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
│   └── agent-service/               # AI Travel Assistant
│       ├── src/agent_handler/
│       │   ├── app.py               # Main agent logic
│       │   ├── conversation_manager.py
│       │   └── tools/
│       │       └── travel_planner_tools.py  # Hotel search, recommendations
│       ├── tests/
│       ├── requirements.txt
│       └── README.md
│
├── 🎨 Frontend
│   ├── frontend/                    # React UI (Vite + Tailwind)
│   │   ├── src/
│   │   │   ├── pages/
│   │   │   │   ├── Home.jsx
│   │   │   │   ├── Hotels.jsx       # Hotel listings
│   │   │   │   ├── TripPlanner.jsx  # Trip planning
│   │   │   │   ├── Bookings.jsx     # Booking history
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
│   │   ├── hotel-service/        # Hotel service infra
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
4. **Frontend** - React UI (optional)

## File Count Summary

- **Services**: 2 (hotel, agent)
- **Lambda Functions**: 5
- **Terraform Modules**: 13
- **DynamoDB Tables**: 4
- **API Gateways**: 2
- **Documentation Files**: 5+

## What's NOT Included

❌ Legacy e-commerce code  
❌ Shopping cart functionality  
❌ Product catalog (replaced with hotel search)  

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
