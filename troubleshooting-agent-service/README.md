# Troubleshooting Agent Service

## Overview

AI-powered DevOps troubleshooting assistant using AWS Strands Agents SDK with Model Context Protocol (MCP) servers.

**Purpose:** Enable DevOps engineers to troubleshoot issues using natural language queries.

**Technology Stack:**
- AWS Strands Agents SDK
- Model Context Protocol (MCP)
- AWS Bedrock (Claude 3 Sonnet)
- AWS Lambda (Python 3.11)
- MCP Servers (CloudWatch Logs, Metrics, AWS Services)

## Features

- Natural language troubleshooting queries
- Automated log analysis
- Performance metrics investigation
- Service health checks
- Root cause analysis
- Automated fix suggestions

## Architecture

```
DevOps Engineer: "Why is Cart Service failing?"
    ↓
API Gateway: POST /troubleshoot
    ↓
Troubleshooting Agent Lambda (Strands + MCP)
    ↓
MCP Servers:
├─ CloudWatch Logs MCP → Query logs, search errors
├─ CloudWatch Metrics MCP → Check performance, alarms
└─ AWS Services MCP → Lambda, DynamoDB, Pipeline details
    ↓
Response: "Cart Service failing due to DynamoDB throttling..."
```

## Use Cases

### 1. Service Failure Investigation
```
Query: "Why is Cart Service returning 500 errors?"

Agent investigates:
1. Queries CloudWatch Logs for errors
2. Finds: DynamoDB ProvisionedThroughputExceededException
3. Checks DynamoDB metrics
4. Finds: Read capacity at 100%
5. Suggests: Switch to PAY_PER_REQUEST mode

MTTR: 2 minutes (vs 2 hours manual)
```

### 2. Performance Degradation
```
Query: "Product Service is slow today"

Agent investigates:
1. Checks Lambda duration metrics
2. Finds: Average duration increased 15x
3. Queries logs for timeouts
4. Checks Lambda memory usage
5. Suggests: Increase memory from 128MB to 512MB
```

### 3. Pipeline Failure
```
Query: "Cart Service pipeline failed, why?"

Agent investigates:
1. Gets pipeline execution details
2. Finds: Build stage failed
3. Queries CodeBuild logs
4. Finds: Unit test failure
5. Identifies: Recent commit broke tests
6. Suggests: Revert commit or fix test
```

## API Endpoints

### POST /troubleshoot
Troubleshooting interface

**Request:**
```json
{
  "question": "Why is Cart Service failing?",
  "service": "cart-service",  // optional, for context
  "timeRange": "1h"  // optional, default: 1h
}
```

**Response:**
```json
{
  "answer": "Cart Service is failing because...",
  "rootCause": "DynamoDB throttling",
  "evidence": [
    "CloudWatch Logs: 45 ProvisionedThroughputExceeded errors",
    "CloudWatch Metrics: Read capacity at 100% for 30 minutes"
  ],
  "recommendations": [
    "Switch to PAY_PER_REQUEST billing mode (immediate)",
    "Or increase provisioned capacity to 50 RCU"
  ],
  "estimatedImpact": {
    "cost": "+$2/month",
    "downtime": "0 seconds (hot switch)"
  }
}
```

## MCP Servers

### 1. CloudWatch Logs MCP Server
- `query_logs()` - Query logs using CloudWatch Insights
- `search_errors()` - Search for error patterns
- `tail_logs()` - Get recent logs (like tail -f)

### 2. CloudWatch Metrics MCP Server
- `get_metrics()` - Get CloudWatch metrics
- `get_alarms()` - Get alarm status
- `check_service_health()` - Overall health check

### 3. AWS Services MCP Server
- `get_lambda_function()` - Get Lambda configuration
- `get_dynamodb_table()` - Get DynamoDB details
- `get_pipeline_execution()` - Get pipeline status

## Environment Variables

- `CLOUDWATCH_LOGS_MCP_URL` - CloudWatch Logs MCP server URL
- `CLOUDWATCH_METRICS_MCP_URL` - CloudWatch Metrics MCP server URL
- `AWS_SERVICES_MCP_URL` - AWS Services MCP server URL
- `BEDROCK_MODEL_ID` - Bedrock model

## Cost

- Lambda: ~$2/month
- Bedrock: ~$10/month (less usage than shopping agent)
- MCP Servers: ~$5/month (Lambda + API Gateway)
- **Total: ~$17/month**

## Deployment

See `terraform/troubleshooting-agent-service/` for infrastructure.

```bash
# Deploy MCP servers first
cd terraform/mcp-servers
terraform init
terraform apply

# Deploy troubleshooting agent
cd ../troubleshooting-agent-service/dev
terraform init
terraform apply
```

## Security

- MCP servers only accessible from troubleshooting agent Lambda
- Read-only access to CloudWatch and AWS services
- No write permissions (agent can't modify infrastructure)
- All queries logged for audit

## Benefits

- **80% reduction in MTTR** (Mean Time To Resolution)
- **Democratizes DevOps knowledge** (juniors can troubleshoot)
- **24/7 availability** (no waiting for senior engineers)
- **Consistent troubleshooting** (follows best practices)
- **Learning tool** (explains root causes)
