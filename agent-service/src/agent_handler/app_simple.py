"""
AI Travel Assistant Lambda Handler - Production Version

Multi-Agent Bedrock implementation based on AWS Workshop patterns
"""

import json
import os
import logging
from typing import Dict, Any
from bedrock_agent import TravelAgent

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize agent (lazy loading)
_travel_agent = None

def get_agent():
    """Get or create TravelAgent instance"""
    global _travel_agent
    if _travel_agent is None:
        _travel_agent = TravelAgent()
    return _travel_agent

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for AI Travel Assistant
    
    Request format:
    {
        "message": "I need a hotel in Miami",
        "userId": "user123",
        "sessionId": "session-abc" (optional)
    }
    
    Response format:
    {
        "response": "AI response text",
        "agent_used": "search|booking|upsell|support",
        "tools_called": ["hotel_search"],
        "suggestions": ["View hotels", "Filter by price"],
        "session_id": "session-abc"
    }
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')
        user_id = body.get('userId', 'guest')
        session_id = body.get('sessionId')
        
        # Validate
        if not user_message:
            return error_response(400, 'Missing required field: message')
        
        # Generate session ID if not provided
        if not session_id:
            from datetime import datetime
            session_id = f"{user_id}-{datetime.utcnow().strftime('%Y%m%d%H%M')}"
        
        logger.info(f"Processing message from {user_id}: {user_message[:100]}")
        
        # Process through multi-agent system
        agent = get_agent()
        result = agent.process_message(user_message, user_id, session_id)
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return error_response(500, 'Internal server error')

def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Return error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': message})
    }
