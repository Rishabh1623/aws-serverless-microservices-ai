"""
Unit tests for Troubleshooting Agent Lambda handler
"""

import json
import os
import pytest
from unittest.mock import Mock, patch, MagicMock

# Set environment variables before importing handler
os.environ['CLOUDWATCH_MCP_URL'] = 'https://test-cloudwatch-mcp.example.com'
os.environ['AWS_SERVICES_MCP_URL'] = 'https://test-aws-services-mcp.example.com'
os.environ['BEDROCK_MODEL_ID'] = 'anthropic.claude-3-sonnet-20240229-v1:0'

from troubleshooting_handler.app import lambda_handler, get_mcp_clients, get_agent


@pytest.fixture
def api_gateway_event():
    """Sample API Gateway event"""
    return {
        'body': json.dumps({
            'question': 'Why is the cart service failing?',
            'service': 'cart-service',
            'timeRange': '1h'
        }),
        'headers': {
            'Content-Type': 'application/json'
        },
        'requestContext': {
            'requestId': 'test-request-id'
        }
    }


@pytest.fixture
def lambda_context():
    """Mock Lambda context"""
    context = Mock()
    context.request_id = 'test-request-id'
    context.function_name = 'troubleshooting-agent-test'
    context.memory_limit_in_mb = 1024
    context.invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test'
    return context


@pytest.fixture
def mock_agent_response():
    """Mock agent response"""
    response = Mock()
    response.text = """
    Summary: Cart Service is experiencing high error rates due to DynamoDB throttling.
    
    Root Cause: The cart-service Lambda function is making too many requests to DynamoDB,
    exceeding the provisioned read capacity units.
    
    Evidence:
    - CloudWatch Logs show "ProvisionedThroughputExceededException" errors
    - DynamoDB metrics show ReadThrottleEvents > 100 in the last hour
    - Lambda duration increased from 200ms to 2000ms
    
    Recommendations:
    1. Increase DynamoDB read capacity from 5 to 25 RCU (Priority: High)
    2. Implement exponential backoff in Lambda code (Priority: High)
    3. Add caching layer with ElastiCache (Priority: Medium)
    
    Impact:
    - Cost: +$10/month for increased capacity
    - Downtime: None (capacity increase is instant)
    
    Prevention:
    - Set up CloudWatch alarms for DynamoDB throttling
    - Implement auto-scaling for DynamoDB
    - Add circuit breaker pattern in Lambda
    """
    response.tools_used = [
        'query_logs',
        'get_metrics',
        'get_dynamodb_table'
    ]
    return response


class TestTroubleshootingHandler:
    """Test suite for Troubleshooting Agent handler"""
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_success(self, mock_mcp_client, mock_agent_class, 
                                   api_gateway_event, lambda_context, mock_agent_response):
        """Test successful troubleshooting request"""
        # Setup mocks
        mock_agent_instance = Mock()
        mock_agent_instance.process.return_value = mock_agent_response
        mock_agent_class.return_value = mock_agent_instance
        
        # Call handler
        response = lambda_handler(api_gateway_event, lambda_context)
        
        # Assertions
        assert response['statusCode'] == 200
        assert 'application/json' in response['headers']['Content-Type']
        
        body = json.loads(response['body'])
        assert 'answer' in body
        assert 'toolsUsed' in body
        assert body['service'] == 'cart-service'
        assert body['timeRange'] == '1h'
        assert 'Cart Service is experiencing high error rates' in body['answer']
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_missing_question(self, mock_mcp_client, mock_agent_class,
                                            lambda_context):
        """Test request with missing question field"""
        event = {
            'body': json.dumps({
                'service': 'cart-service'
            })
        }
        
        response = lambda_handler(event, lambda_context)
        
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'Missing required field: question' in body['error']
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_agent_error(self, mock_mcp_client, mock_agent_class,
                                       api_gateway_event, lambda_context):
        """Test handling of agent processing errors"""
        # Setup mock to raise exception
        mock_agent_instance = Mock()
        mock_agent_instance.process.side_effect = Exception("Agent processing failed")
        mock_agent_class.return_value = mock_agent_instance
        
        response = lambda_handler(api_gateway_event, lambda_context)
        
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'troubleshooting_agent_error' in body['error']
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_default_time_range(self, mock_mcp_client, mock_agent_class,
                                               lambda_context, mock_agent_response):
        """Test default time range when not specified"""
        event = {
            'body': json.dumps({
                'question': 'Why is the service slow?'
            })
        }
        
        mock_agent_instance = Mock()
        mock_agent_instance.process.return_value = mock_agent_response
        mock_agent_class.return_value = mock_agent_instance
        
        response = lambda_handler(event, lambda_context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['timeRange'] == '1h'  # Default value
    
    @patch('troubleshooting_handler.app.MCPClient')
    def test_get_mcp_clients(self, mock_mcp_client_class):
        """Test MCP client initialization"""
        # Clear global cache
        import troubleshooting_handler.app as app
        app._observability_client = None
        
        clients = get_mcp_clients()
        
        assert len(clients) == 1
        assert mock_mcp_client_class.called
        
        # Verify client is cached
        clients2 = get_mcp_clients()
        assert clients == clients2
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.get_mcp_clients')
    def test_get_agent(self, mock_get_mcp_clients, mock_agent_class):
        """Test agent initialization"""
        # Clear global cache
        import troubleshooting_handler.app as app
        app._agent = None
        
        mock_clients = [Mock()]
        mock_get_mcp_clients.return_value = mock_clients
        
        agent = get_agent()
        
        assert mock_agent_class.called
        call_args = mock_agent_class.call_args
        assert 'system_prompt' in call_args[1]
        assert 'mcp_clients' in call_args[1]
        assert 'model' in call_args[1]
        
        # Verify agent is cached
        agent2 = get_agent()
        assert agent == agent2
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_cors_headers(self, mock_mcp_client, mock_agent_class,
                                        api_gateway_event, lambda_context, mock_agent_response):
        """Test CORS headers are present"""
        mock_agent_instance = Mock()
        mock_agent_instance.process.return_value = mock_agent_response
        mock_agent_class.return_value = mock_agent_instance
        
        response = lambda_handler(api_gateway_event, lambda_context)
        
        assert 'Access-Control-Allow-Origin' in response['headers']
        assert response['headers']['Access-Control-Allow-Origin'] == '*'
    
    @patch('troubleshooting_handler.app.Agent')
    @patch('troubleshooting_handler.app.MCPClient')
    def test_lambda_handler_with_service_context(self, mock_mcp_client, mock_agent_class,
                                                 lambda_context, mock_agent_response):
        """Test request with service context"""
        event = {
            'body': json.dumps({
                'question': 'Check payment service health',
                'service': 'payment-service',
                'timeRange': '30m'
            })
        }
        
        mock_agent_instance = Mock()
        mock_agent_instance.process.return_value = mock_agent_response
        mock_agent_class.return_value = mock_agent_instance
        
        response = lambda_handler(event, lambda_context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['service'] == 'payment-service'
        assert body['timeRange'] == '30m'
        
        # Verify agent was called with context
        mock_agent_instance.process.assert_called_once()
        call_args = mock_agent_instance.process.call_args
        assert 'context' in call_args[1] or len(call_args[0]) > 1


class TestSystemPrompt:
    """Test system prompt configuration"""
    
    def test_system_prompt_contains_services(self):
        """Test system prompt includes all services"""
        from troubleshooting_handler.app import SYSTEM_PROMPT
        
        services = [
            'product-service',
            'cart-service',
            'payment-service',
            'order-service',
            'agent-service'
        ]
        
        for service in services:
            assert service in SYSTEM_PROMPT
    
    def test_system_prompt_contains_guidelines(self):
        """Test system prompt includes troubleshooting guidelines"""
        from troubleshooting_handler.app import SYSTEM_PROMPT
        
        guidelines = [
            'root cause',
            'logs',
            'metrics',
            'recommendations',
            'impact'
        ]
        
        for guideline in guidelines:
            assert guideline.lower() in SYSTEM_PROMPT.lower()


class TestEnvironmentVariables:
    """Test environment variable handling"""
    
    def test_required_env_vars_present(self):
        """Test all required environment variables are set"""
        required_vars = [
            'CLOUDWATCH_MCP_URL',
            'AWS_SERVICES_MCP_URL',
            'BEDROCK_MODEL_ID'
        ]
        
        for var in required_vars:
            assert var in os.environ
            assert os.environ[var] != ''
    
    def test_default_bedrock_model(self):
        """Test default Bedrock model is Claude 3 Sonnet"""
        model_id = os.environ.get('BEDROCK_MODEL_ID')
        assert 'claude-3-sonnet' in model_id


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
