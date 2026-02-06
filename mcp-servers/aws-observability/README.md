# AWS Observability MCP Server (Unified)

## Overview

**Single unified MCP server** providing complete observability for AWS serverless microservices.

Combines CloudWatch Logs, CloudWatch Metrics, and AWS Services inspection into one server.

**Why Unified:**
- ✅ 67% cost reduction ($15/month → $5/month)
- ✅ Simpler architecture (1 server vs 3)
- ✅ Better performance (single connection)
- ✅ Easier maintenance (one codebase)
- ✅ All 11 observability tools in one place

## Tools Provided

### CloudWatch Logs Tools (4)
1. **query_logs** - Query CloudWatch Logs using CloudWatch Insights
2. **search_errors** - Search for errors in service logs
3. **tail_logs** - Get recent logs from service (like tail -f)
4. **get_log_groups** - List available log groups

### CloudWatch Metrics Tools (3)
5. **get_metrics** - Get CloudWatch metrics with statistics
6. **get_alarms** - Get CloudWatch alarms by state
7. **check_service_health** - Check overall service health

### AWS Services Tools (4)
8. **get_lambda_function** - Get Lambda function configuration
9. **get_dynamodb_table** - Get DynamoDB table details
10. **get_pipeline_execution** - Get CodePipeline execution status
11. **list_services** - List all deployed services

**Total: 11 tools in one unified server**

## Architecture

```
Troubleshooting Agent Lambda
    ↓
    └─→ AWS Observability MCP Server (Single Lambda + API Gateway)
        ├─ CloudWatch Logs tools (4 tools)
        ├─ CloudWatch Metrics tools (3 tools)
        └─ AWS Services tools (4 tools)
```

## Deployment

### Prerequisites
- AWS Account with appropriate permissions
- Terraform installed
- Docker (for local testing)

### Deploy to AWS Lambda

```bash
# Deploy MCP server
cd terraform/mcp-servers
terraform init
terraform apply

# Get MCP server URL
terraform output aws_observability_mcp_url
```

### Local Testing (Docker)

```bash
cd mcp-servers/aws-observability

# Build Docker image
docker build -t aws-observability-mcp .

# Run locally
docker run -p 8080:8080 \
  -e AWS_REGION=us-east-1 \
  -v ~/.aws:/root/.aws \
  aws-observability-mcp
```

## Integration with Troubleshooting Agent

```python
from strands_agents.mcp import MCPClient

# Single MCP client for all observability
observability_client = MCPClient(
    server_url=os.environ['AWS_OBSERVABILITY_MCP_URL'],
    transport="streamable-http"
)

agent = Agent(
    system_prompt=SYSTEM_PROMPT,
    mcp_clients=[observability_client],  # Just one!
    model="anthropic.claude-3-sonnet-20240229-v1:0"
)
```

## Example Usage

### Query Logs
```python
# Search for errors in cart service
result = query_logs(
    log_group="/aws/lambda/cart-service-dev",
    query="fields @timestamp, @message | filter @message like /ERROR/",
    start_time="-1h",
    limit=100
)
```

### Check Service Health
```python
# Check cart service health
health = check_service_health("cart-service-dev")
# Returns: error_rate, avg_duration_ms, throttles
```

### Get Lambda Configuration
```python
# Get Lambda function details
config = get_lambda_function("cart-service-dev")
# Returns: runtime, memory, timeout, code_size
```

## Cost Estimate

**Monthly Cost:**
- Lambda function: ~$2/month (1M requests, 512MB, 3s avg)
- API Gateway: ~$1/month (1M requests)
- CloudWatch Logs: ~$1/month (5GB ingestion)
- Management overhead: ~$1/month
- **Total: ~$5/month**

**Compared to 3 separate servers: $15/month**
**Savings: 67% ($10/month)**

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:FilterLogEvents",
        "logs:StartQuery",
        "logs:GetQueryResults",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:DescribeAlarms",
        "lambda:GetFunction",
        "lambda:ListFunctions",
        "dynamodb:DescribeTable",
        "codepipeline:GetPipelineState",
        "codepipeline:GetPipelineExecution",
        "codepipeline:ListPipelineExecutions"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuration for Kiro/Cline IDE

Add to `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "aws-observability": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-v",
        "~/.aws:/root/.aws",
        "-e",
        "AWS_PROFILE=default",
        "-e",
        "AWS_REGION=us-east-1",
        "aws-observability-mcp:latest"
      ],
      "env": {},
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

## Monitoring

The MCP server logs to CloudWatch Logs:
- Log Group: `/aws/lambda/aws-observability-mcp-dev`
- Metrics: Duration, Errors, Throttles
- Alarms: Error rate > 1%, Duration > 10s

## Troubleshooting

### Server not responding
```bash
# Check Lambda logs
aws logs tail /aws/lambda/aws-observability-mcp-dev --follow

# Check Lambda status
aws lambda get-function --function-name aws-observability-mcp-dev
```

### Permission errors
```bash
# Verify IAM role has required permissions
aws iam get-role-policy --role-name aws-observability-mcp-role --policy-name mcp-policy
```

### Timeout issues
```bash
# Increase Lambda timeout
aws lambda update-function-configuration \
  --function-name aws-observability-mcp-dev \
  --timeout 30
```

## Development

### Run Tests
```bash
cd mcp-servers/aws-observability
python -m pytest tests/
```

### Add New Tool
```python
@server.tool()
def my_new_tool(param: str) -> Dict[str, Any]:
    """
    Tool description
    
    Args:
        param: Parameter description
    """
    try:
        # Implementation
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'error': str(e)}
```

## References

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [AWS Strands Agents SDK](https://github.com/awslabs/strands-agents)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)

## Support

For issues or questions:
1. Check CloudWatch Logs: `/aws/lambda/aws-observability-mcp-dev`
2. Review IAM permissions
3. Verify API Gateway endpoint is accessible
4. Check Terraform state for configuration

## License

MIT License - See LICENSE file for details
