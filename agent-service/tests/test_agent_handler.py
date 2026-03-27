"""
Unit tests for Travel Agent Handler
"""

import json
import pytest
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from agent_handler.app import lambda_handler


class TestAgentHandler:
    """Test cases for agent Lambda handler"""
    
    def test_missing_message_returns_400(self):
        """Test that missing message returns 400 error"""
        event = {
            'body': json.dumps({})
        }
        context = Mock()
        
        response = lambda_handler(event, context)
        
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'message' in body['error'].lower()
    
    @patch('agent_handler.app.get_agent')
    def test_successful_agent_response(self, mock_get_agent):
        """Test successful agent processing"""
        # Mock agent response
        mock_agent = Mock()
        mock_response = Mock()
        mock_response.text = "I found 2 hotels in Paris under $200/night"
        mock_response.tools_used = ['search_hotels']
        mock_agent.process.return_value = mock_response
        mock_get_agent.return_value = mock_agent
        
        event = {
            'body': json.dumps({
                'message': 'I want to book a hotel in Paris under $200',
                'userId': 'test-user'
            })
        }
        context = Mock()
        
        response = lambda_handler(event, context)
        
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert 'response' in body
        assert 'toolsUsed' in body
        assert body['userId'] == 'test-user'
    
    @patch('agent_handler.app.get_agent')
    def test_agent_error_returns_graceful_fallback(self, mock_get_agent):
        """Test that agent errors return graceful fallback"""
        # Mock agent to raise exception
        mock_agent = Mock()
        mock_agent.process.side_effect = Exception("Bedrock error")
        mock_get_agent.return_value = mock_agent
        
        event = {
            'body': json.dumps({
                'message': 'test message',
                'userId': 'test-user'
            })
        }
        context = Mock()
        
        response = lambda_handler(event, context)
        
        assert response['statusCode'] == 500
        body = json.loads(response['body'])
        assert 'error' in body
        assert 'fallback_urls' in body
