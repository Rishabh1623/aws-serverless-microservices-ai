"""
Troubleshooting Agent Lambda Handler

AI-powered DevOps troubleshooting using Strands Agents SDK with MCP servers.
Helps engineers diagnose and fix issues using natural language.
"""

import json
import os
import logging
from typing import Dict, Any

from strands_agents import Agent
from strands_agents.mcp import MCPClient

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# System prompt for troubleshooting agent
SYSTEM_PROMPT = """
You are an expert AWS DevOps troubleshooting assistant for a serverless microservices platform.

Your capabilities:
- Query CloudWatch Logs to find errors and patterns
- Analyze CloudWatch Metrics for performance issues
- Check AWS service configurations (Lambda, DynamoDB, CodePipeline)
- Identify root causes of failures
- Suggest specific, actionable fixes
- Estimate impact and cost of fixes

Services you monitor:
- Product Service (product-service)
- Cart Service (cart-service)
- Payment Service (payment-service)
- Order Service (order-service)
- Shopping Agent Service (agent-service)

Guidelines for troubleshooting:
1. Gather information from multiple sources (logs, metrics, configs)
2. Look for correlations and patterns
3. Identify the root cause, not just symptoms
4. Provide specific fixes with commands/steps
5. Estimate cost and downtime impact
6. Explain WHY the issue occurred (for learning)

When analyzing issues:
- Check logs for error messages and stack traces
- Check metrics for anomalies (spikes, drops, throttling)
- Check service configurations for misconfigurations
- Check recent deployments (pipeline executions)
- Consider dependencies between services

Response format:
1. Summary: Brief description of the issue
2. Root Cause: What's actually causing the problem
3. Evidence: Data from logs/metrics supporting your analysis
4. Recommendations: Specific fixes ranked by priority
5. Impact: Cost and downtime estimates
6. Prevention: How to prevent this in the future

Be specific with:
- Service names
- Timestamps
- Metric values
- Log excerpts
- Configuration values
"""

# Initialize MCP client (lazy loading) - UNIFIED SERVER
_observability_client = None
_agent = None


def get_mcp_clients():
    """
    Initialize MCP client (lazy loading)
    
    Why: Single unified MCP server for all observability
    Pattern: Reuse across warm Lambda invocations
    Benefits: Simpler, faster, cheaper than multiple servers
    """
    global _observability_client
    
    if _observability_client is None:
        _observability_client = MCPClient(
            server_url=os.environ['AWS_OBSERVABILITY_MCP_URL'],
            transport="streamable-http"
        )
    
    return [_observability_client]


def get_agent():
    """
    Initialize Troubleshooting Agent (lazy loading)
    
    Why: Reuse agent across warm Lambda invocations
    """
    global _agent
    
    if _agent is None:
        _agent = Agent(
            system_prompt=SYSTEM_PROMPT,
            mcp_clients=get_mcp_clients(),
            model=os.environ.get(
                'BEDROCK_MODEL_ID',
                'anthropic.claude-3-sonnet-20240229-v1:0'
            )
        )
    
    return _agent


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Troubleshooting Agent
    
    Args:
        event: API Gateway event with troubleshooting question
        context: Lambda context
        
    Returns:
        API Gateway response with troubleshooting analysis
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        question = body.get('question', '')
        service = body.get('service', None)  # Optional service context
        time_range = body.get('timeRange', '1h')  # Default: last hour
        
        # Validate input
        if not question:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required field: question'
                })
            }
        
        logger.info(f"Troubleshooting question: {question}")
        if service:
            logger.info(f"Service context: {service}")
        
        # Get agent instance
        agent = get_agent()
        
        # Build context for agent
        agent_context = {
            'timeRange': time_range
        }
        if service:
            agent_context['service'] = service
        
        # Process question through agent
        response = agent.process(
            question,
            context=agent_context
        )
        
        # Log MCP tools used (for monitoring)
        logger.info(f"MCP tools used: {response.tools_used}")
        
        # Parse agent response for structured output
        # (Agent should follow the response format in system prompt)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'answer': response.text,
                'toolsUsed': response.tools_used,
                'service': service,
                'timeRange': time_range,
                'timestamp': context.request_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing troubleshooting request: {str(e)}", exc_info=True)
        
        # Return error with helpful message
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'troubleshooting_agent_error',
                'message': 'Unable to process troubleshooting request. Please check CloudWatch logs or try again.',
                'fallback': 'Check AWS Console → CloudWatch → Log Groups for manual investigation'
            })
        }
