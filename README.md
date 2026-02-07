# 🚀 AWS Serverless Microservices with AI Agents

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Production-grade serverless microservices platform with AI-powered shopping assistant and DevOps troubleshooting agent, built on AWS using Bedrock, Lambda, and the Model Context Protocol (MCP).

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

This project demonstrates a **production-grade serverless microservices architecture** on AWS, featuring:

- **7 Independent Microservices** with separate CI/CD pipelines
- **2 AI Agents** powered by AWS Bedrock (Claude 3)
- **Unified MCP Server** for operational observability
- **Complete Infrastructure as Code** using Terraform
- **Production Features**: DLQ, CloudWatch Alarms, X-Ray Tracing, SNS Alerts

**Perfect for:** Portfolio projects, learning AWS serverless, interview preparation, production reference architecture

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT APPLICATIONS                       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Product    │    │     Cart     │    │    Order     │
│   Service    │◀───│   Service    │◀───│   Service    │
│              │    │              │    │      │       │
│ - List       │    │ - Add        │    │ - Create     │
│ - Get        │    │ - Remove     │    │ - Get        │
│ - Search     │    │ - Update     │    │ - List       │
└──────────────┘    └──────────────┘    └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │   Payment    │
                                        │   Service    │
                                        │ - Process    │
                                        │ - Get        │
                                        └──────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      AI AGENTS LAYER                         │
│                                                              │
│  ┌────────────────────┐         ┌────────────────────┐     │
│  │ Shopping Agent     │         │ Troubleshooting    │     │
│  │ (Bedrock + Strands)│         │ Agent (MCP)        │     │
│  │                    │         │                    │     │
│  │ Natural language   │         │ DevOps automation  │     │
│  │ shopping assistant │         │ using MCP tools    │     │
│  └────────────────────┘         └────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## ✨ Key Features

### 🎯 Microservices Architecture
- **4 Core Services**: Product, Cart, Payment, Order
- **Independent Deployment**: Each service has its own CI/CD pipeline
- **Service Isolation**: Separate dev/prod environments
- **API Gateway**: RESTful APIs with throttling and CORS

### 🤖 AI Integration
- **Shopping Agent**: Conversational shopping using AWS Bedrock (Claude 3)
- **Troubleshooting Agent**: AI-powered DevOps assistant
- **Tool Calling**: Agents interact with microservices via tools
- **MCP Protocol**: Model Context Protocol for operational AI

### 🏭 Production-Grade Features
- ✅ Dead Letter Queues (DLQ)
- ✅ CloudWatch Alarms & Monitoring
- ✅ X-Ray Distributed Tracing
- ✅ SNS Email Alerts
- ✅ API Gateway Throttling
- ✅ Reserved Concurrency
- ✅ Cost Alarms

### 🛠️ Infrastructure as Code
- **Terraform**: Complete infrastructure automation
- **Modular Design**: Reusable Terraform modules
- **State Management**: S3 backend with DynamoDB locking
- **Multi-Environment**: Separate dev/prod configurations

### 📊 Observability
- **Unified MCP Server**: 11 observability tools
  - CloudWatch Logs (4 tools)
  - CloudWatch Metrics (3 tools)
  - AWS Services Inspection (4 tools)
- **Centralized Logging**: CloudWatch Logs with retention
- **Metrics & Alarms**: Proactive monitoring
- **Distributed Tracing**: X-Ray for request flow

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

### Option 1: Run Frontend Demo (No AWS Required!)

Perfect for recording demos and showcasing the UI:

```bash
cd frontend
npm install
npm run dev
```

**Open http://localhost:5173** - Full UI with demo data!

See [FRONTEND_SETUP.md](FRONTEND_SETUP.md) for details.

### Option 2: Deploy Full Stack to AWS

**Follow ONE complete guide:**

📖 **[STEP_BY_STEP_COMPLETE_GUIDE.md](STEP_BY_STEP_COMPLETE_GUIDE.md)**

This single file contains:
- EC2 setup
- Tool installation
- AWS configuration
- All 7 microservices deployment
- Frontend setup
- Demo recording
- Troubleshooting

**Time:** 8-10 hours  
**Cost:** $1-5 for 3-day demo

## 📁 Project Structure

```
.
├── agent-service/              # AI Shopping Assistant
├── cart-service/               # Shopping Cart Service
├── order-service/              # Order Management Service
├── payment-service/            # Payment Processing Service
├── product-service/            # Product Catalog Service
├── troubleshooting-agent-service/  # DevOps AI Agent
├── mcp-servers/
│   └── aws-observability/      # Unified MCP Server (11 tools)
├── terraform/
│   ├── modules/                # Reusable Terraform modules
│   ├── shared/                 # Shared infrastructure
│   ├── agent-service/          # Agent infrastructure
│   │   ├── dev/
│   │   ├── prod/
│   │   └── pipeline/
│   └── [other services]/       # Similar structure
├── shared/
│   └── python/                 # Shared Python utilities
├── COMPLETE_DEPLOYMENT_GUIDE.md
├── PRODUCTION_READINESS_AUDIT.md
└── README.md
```

## 💰 Cost Estimation

### Demo (3 days)
- **Optimized**: ~$0.27 (using Claude Haiku)
- **Full Featured**: ~$1.06 (using Claude Sonnet)

### Monthly (Full Deployment)
- **Dev Environment**: ~$73/month
- **Prod Environment**: ~$110/month

**Cost Breakdown:**
- Lambda: ~$2/month (free tier eligible)
- DynamoDB: ~$6/month
- API Gateway: ~$3.50/month
- Bedrock (AI): ~$20-30/month
- Other Services: ~$10/month

**See [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md) for detailed cost analysis**

## 📚 Documentation

**Main Guide (Everything in ONE file):**
- **[STEP_BY_STEP_COMPLETE_GUIDE.md](STEP_BY_STEP_COMPLETE_GUIDE.md)** - Complete deployment from start to finish

**Service Documentation:**
- [Agent Service](agent-service/README.md) - AI Shopping Assistant
- [Cart Service](cart-service/README.md) - Shopping Cart API
- [Product Service](product-service/README.md) - Product Catalog API
- [MCP Server](mcp-servers/aws-observability/README.md) - Observability tools
- [Troubleshooting Agent](troubleshooting-agent-service/README.md) - DevOps AI

## 🎥 Demo

### Shopping Agent Example
```bash
curl -X POST "$AGENT_API/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I want to buy a laptop under $1000",
    "userId": "user123"
  }'
```

**Response:**
```json
{
  "response": "I found some great laptops for you! The Dell XPS 13 is available for $999...",
  "toolsUsed": ["search_products", "get_product_details"],
  "userId": "user123"
}
```

### Troubleshooting Agent Example
```bash
curl -X POST "$TROUBLESHOOT_API/troubleshoot" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Why is the cart service failing?",
    "service": "cart-service-dev",
    "timeRange": "1h"
  }'
```

**Response:**
```json
{
  "answer": "I found 3 errors in the cart service logs:\n1. DynamoDB throttling...",
  "toolsUsed": ["search_errors", "query_logs", "get_dynamodb_table"],
  "service": "cart-service-dev"
}
```

## 🎓 What This Project Demonstrates

### Technical Skills
- ✅ AWS Serverless Architecture
- ✅ Microservices Design Patterns
- ✅ Infrastructure as Code (Terraform)
- ✅ AI/ML Integration (Bedrock)
- ✅ CI/CD Automation
- ✅ Production-Grade Monitoring
- ✅ Security Best Practices
- ✅ Cost Optimization

### Architecture Patterns
- ✅ Domain-Driven Microservices
- ✅ Event-Driven Architecture
- ✅ AI Agent Tool Calling
- ✅ Model Context Protocol (MCP)
- ✅ Circuit Breaker Pattern
- ✅ Graceful Degradation
- ✅ Retry with Exponential Backoff

### Best Practices
- ✅ Separate dev/prod environments
- ✅ Independent service deployment
- ✅ Comprehensive monitoring
- ✅ Automated testing
- ✅ Security by design
- ✅ Cost controls
- ✅ Complete documentation

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

- **7 Microservices**
- **15+ Lambda Functions**
- **5 DynamoDB Tables**
- **7 API Gateways**
- **6 CI/CD Pipelines**
- **5,000+ Lines of Terraform**
- **3,000+ Lines of Python**
- **10,000+ Lines of Documentation**

---

⭐ **Star this repo if you find it helpful!**

📧 **Questions?** Open an issue or reach out!

🚀 **Ready to deploy?** Check out [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md)
