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
