# 🏨 AWS Serverless Travel Platform with AI Travel Planner

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Production-grade serverless travel booking platform with AI-powered travel planner, personalized recommendations, and dynamic pricing, built on AWS using Bedrock, Lambda, and the Model Context Protocol (MCP).

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Technologies Used](#technologies-used)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Cost Estimation](#cost-estimation)
- [Documentation](#documentation)
- [Demo](#demo)
- [Contributing](#contributing)

## 🎯 Overview

This project demonstrates a **production-grade serverless travel booking platform** on AWS, featuring:

- **8 Independent Microservices** with separate CI/CD pipelines
- **AI Travel Planner** powered by AWS Bedrock (Claude 3)
- **Personalized Recommendations** based on user preferences and travel history
- **Dynamic Pricing Engine** (occupancy, season, events, advance booking)
- **Complete Infrastructure as Code** using Terraform
- **Production Features**: DLQ, CloudWatch Alarms, X-Ray Tracing, SNS Alerts, State Locking

**Perfect for:** Portfolio projects, learning AWS serverless, travel tech interviews, production reference architecture

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TRAVEL PLATFORM                           │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    Hotel     │    │   Booking    │    │   Payment    │
│   Service    │◀───│   Service    │◀───│   Service    │
│              │    │              │    │              │
│ - Search     │    │ - Create     │    │ - Process    │
│ - Details    │    │ - Manage     │    │ - Verify     │
│ - Rooms      │    │ - Cancel     │    │ - Refund     │
└──────────────┘    └──────────────┘    └──────────────┘
        │
        ▼
┌──────────────┐
│   Dynamic    │
│   Pricing    │
│   Engine     │
└──────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   AI TRAVEL PLANNER                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Personalized hotel recommendations              │    │
│  │  • Complete itinerary generation                   │    │
│  │  • Package deals with discounts                    │    │
│  │  • Hotel comparison & analysis                     │    │
│  │  • User preference learning                        │    │
│  │  • Loyalty rewards (Bronze/Silver/Gold/Platinum)   │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```



## ✨ Key Features

### 🏨 Travel Platform
- **Hotel Search & Booking**: Search hotels by location, dates, price, amenities
- **Dynamic Pricing**: Occupancy-based, seasonal, event-driven, early bird discounts
- **Availability Management**: Real-time room availability with conflict detection
- **Booking System**: Complete reservation flow with confirmation

### 🤖 AI Travel Planner
- **Personalized Recommendations**: Hotels matched to travel purpose and preferences
- **Complete Itineraries**: Day-by-day travel plans with activities and dining
- **Package Deals**: Bundled hotel + activities with group discounts
- **Hotel Comparison**: AI-powered side-by-side analysis
- **Smart Suggestions**: Context-aware recommendations based on conversation

### 👤 Personalization Engine
- **User Profiles**: Track preferences, budget, past trips, dietary needs
- **Loyalty Program**: Bronze/Silver/Gold/Platinum tiers (0-15% discounts)
- **Conversation Memory**: Remember user preferences across sessions
- **Intent Detection**: Understand travel purpose (business, romantic, family, adventure)
- **Preference Learning**: AI learns from user behavior and feedback

### 🏭 Production-Grade Features
- ✅ Dead Letter Queues (DLQ)
- ✅ CloudWatch Alarms & Monitoring
- ✅ X-Ray Distributed Tracing
- ✅ SNS Email Alerts
- ✅ API Gateway Throttling
- ✅ Reserved Concurrency
- ✅ Cost Alarms
- ✅ State Locking (S3 + DynamoDB)

### 🛠️ Infrastructure as Code
- **Terraform**: Complete infrastructure automation
- **Modular Design**: Reusable Terraform modules
- **State Management**: S3 backend with DynamoDB locking
- **Multi-Environment**: Separate dev/prod configurations
- **CI/CD Pipelines**: Automated testing and deployment

## 🔧 Technologies Used

### Cloud & Infrastructure
- **AWS Lambda** - Serverless compute
- **AWS API Gateway** - RESTful APIs
- **AWS DynamoDB** - NoSQL database
- **AWS Bedrock** - AI/ML models (Claude 3)
- **AWS CloudWatch** - Monitoring & logging
- **AWS X-Ray** - Distributed tracing
- **AWS SNS/SQS** - Notifications & queuing
- **AWS Secrets Manager** - Secrets management
- **Terraform** - Infrastructure as Code

### Development
- **Python 3.11** - Lambda runtime
- **Strands Agents SDK** - AI agent framework
- **Model Context Protocol (MCP)** - Operational AI
- **Boto3** - AWS SDK for Python

### CI/CD
- **AWS CodePipeline** - Continuous delivery
- **AWS CodeBuild** - Build automation
- **GitHub** - Source control

## 🚀 Quick Start

### Option 1: Frontend Demo (No AWS!)

```bash
cd frontend
npm install
npm run dev
```
Open http://localhost:5173 - Full UI with 40 demo products!

### Option 2: Test Locally with SAM CLI

**Prerequisites:** Install [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html) and [Docker](https://www.docker.com/products/docker-desktop)

```bash
# Start all services
bash scripts/start-local-services.sh

# Test
bash scripts/test-local-services.sh
```

**Services:**
- Product: http://localhost:3001
- Cart: http://localhost:3002
- Order: http://localhost:3003
- Payment: http://localhost:3004

### Option 3: Deploy to AWS

See [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 📁 Project Structure

```
serverless-microservices/
├── frontend/              # React app (Vite + Tailwind)
├── product-service/       # Product catalog API
├── cart-service/          # Shopping cart API
├── order-service/         # Order management API
├── payment-service/       # Payment processing API
├── agent-service/         # AI shopping assistant (Bedrock)
├── troubleshooting-agent/ # DevOps AI agent
├── mcp-servers/           # Observability tools
├── terraform/             # Infrastructure as Code
├── shared/                # Shared Python utilities
└── scripts/               # Helper scripts
```

**Each service has:**
- `src/` - Lambda function code
- `tests/` - Unit tests
- `requirements.txt` - Python dependencies
- `template.yaml` - SAM template for local testing

## 💰 Cost Estimation

**Demo (3 days):** ~$1-5  
**Monthly:** ~$73-110/month

- Lambda: ~$2/month (free tier eligible)
- DynamoDB: ~$6/month
- API Gateway: ~$3.50/month
- Bedrock (AI): ~$20-30/month

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Deploy to AWS
- [Terraform Structure](terraform/STRUCTURE.md) - Infrastructure organization
- Service READMEs in each service folder

## 🎥 Demo Examples

**Shopping Agent:**
```bash
curl -X POST "$AGENT_API/agent" \
  -d '{"message": "I want to buy a laptop under $1000", "userId": "user123"}'
```

**Troubleshooting Agent:**
```bash
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -d '{"question": "Why is the cart service failing?", "service": "cart-service-dev"}'
```

## 🎓 What This Demonstrates

- AWS Serverless Architecture (Lambda, API Gateway, DynamoDB)
- Microservices Design Patterns
- Infrastructure as Code (Terraform)
- AI/ML Integration (AWS Bedrock)
- CI/CD Automation
- Production Monitoring (CloudWatch, X-Ray)
- Model Context Protocol (MCP)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Rishabh**
- GitHub: [@Rishabh1623](https://github.com/Rishabh1623)
- Project: [aws-serverless-microservices-ai](https://github.com/Rishabh1623/aws-serverless-microservices-ai)

## 🙏 Acknowledgments

- AWS for Bedrock and Strands Agents SDK
- HashiCorp for Terraform
- Anthropic for Claude AI models
- Model Context Protocol community

## 📊 Project Stats

- 7 Microservices
- 15+ Lambda Functions
- 5 DynamoDB Tables
- 7 API Gateways
- 6 CI/CD Pipelines

---

⭐ Star this repo if you find it helpful!

📧 Questions? Open an issue or reach out!
