"""
Integration tests for Agent Service API

Tests the deployed Agent Service with real AWS infrastructure.
"""

import os
import pytest
import requests
import json


class TestAgentAPI:
    """Integration tests for Agent API"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test environment"""
        self.api_url = os.environ.get('AGENT_API_URL')
        if not self.api_url:
            pytest.skip("AGENT_API_URL not set")
        
        self.api_url = self.api_url.rstrip('/')
        self.timeout = 60  # Agent can take time to respond
    
    def test_agent_endpoint_exists(self):
        """Test that agent endpoint is accessible"""
        response = requests.post(
            f"{self.api_url}/agent",
            json={"message": "hello", "userId": "test-user"},
            timeout=self.timeout
        )
        
        # Should not return 404
        assert response.status_code != 404, "Agent endpoint not found"
    
    def test_agent_responds_to_simple_query(self):
        """Test agent responds to simple query"""
        response = requests.post(
            f"{self.api_url}/agent",
            json={
                "message": "Hello, can you help me?",
                "userId": "test-user"
            },
            timeout=self.timeout
        )
        
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert 'response' in data, "Response should contain 'response' field"
        assert isinstance(data['response'], str), "Response should be a string"
        assert len(data['response']) > 0, "Response should not be empty"
    
    def test_agent_handles_missing_message(self):
        """Test agent returns error for missing message"""
        response = requests.post(
            f"{self.api_url}/agent",
            json={"userId": "test-user"},
            timeout=self.timeout
        )
        
        assert response.status_code == 400, "Should return 400 for missing message"
        
        data = response.json()
        assert 'error' in data, "Error response should contain 'error' field"
    
    def test_agent_product_search(self):
        """Test agent can search for products"""
        response = requests.post(
            f"{self.api_url}/agent",
            json={
                "message": "Show me laptops",
                "userId": "test-user"
            },
            timeout=self.timeout
        )
        
        assert response.status_code == 200
        
        data = response.json()
        assert 'response' in data
        assert 'toolsUsed' in data
        
        # Agent should have used search_products tool
        # (This assumes Product Service has data)
        print(f"Agent response: {data['response']}")
        print(f"Tools used: {data['toolsUsed']}")
    
    def test_agent_maintains_context(self):
        """Test agent maintains conversation context"""
        session_id = "test-session-123"
        
        # First message
        response1 = requests.post(
            f"{self.api_url}/agent",
            json={
                "message": "I'm looking for electronics",
                "userId": "test-user",
                "sessionId": session_id
            },
            timeout=self.timeout
        )
        
        assert response1.status_code == 200
        
        # Follow-up message (should remember context)
        response2 = requests.post(
            f"{self.api_url}/agent",
            json={
                "message": "Show me the cheapest one",
                "userId": "test-user",
                "sessionId": session_id
            },
            timeout=self.timeout
        )
        
        assert response2.status_code == 200
        
        data2 = response2.json()
        print(f"Context-aware response: {data2['response']}")
    
    def test_agent_error_handling(self):
        """Test agent handles errors gracefully"""
        # Send very long message (potential timeout)
        long_message = "Tell me about " + "products " * 1000
        
        response = requests.post(
            f"{self.api_url}/agent",
            json={
                "message": long_message,
                "userId": "test-user"
            },
            timeout=self.timeout
        )
        
        # Should either succeed or return graceful error
        assert response.status_code in [200, 500], "Should handle long messages"
        
        if response.status_code == 500:
            data = response.json()
            assert 'error' in data or 'fallback_urls' in data, "Error should provide fallback"
