"""
Minimal AI Travel Assistant - For Testing Bedrock Connection

This is a simplified version WITHOUT tools to isolate the Bedrock timeout issue.
"""

import json
import os
import logging
from typing import Dict, Any

from strands.agent import Agent

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Minimal system prompt
SYSTEM_PROMPT = """
You are a helpful AI Travel Assistant. Help users find hotels and plan trips.
Keep responses concise and friendly.
"""

# Global agent instance
_agent = None


def get_agent():
    """Initialize Strands Agent without tools"""
    global _agent
    
    if _agent is None:
        bedrock_model_id = os.environ.get(
            'BEDROCK_MODEL_ID',
            'anthropic.claude-3-haiku-20240307-v1:0'
        )
        
        bedrock_region = os.environ.get('BEDROCK_REGION', 'us-east-1')
        
        logger.info(f"Using AWS Bedrock with model: {bedrock_model_id}")
        logger.info(f"Bedrock region: {bedrock_region}")
        
        # Create agent WITHOUT tools - just basic conversation
        _agent = Agent(
            system_prompt=SYSTEM_PROMPT,
            model=bedrock_model_id,
            # Explicitly set region if Strands supports it
            # region=bedrock_region  # Uncomment if Strands Agent accepts region parameter
        )
    
    return _agent


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Minimal Lambda handler for testing"""
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')
        user_id = body.get('userId', 'guest')
        
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Missing message'})
            }
        
        logger.info(f"Processing message from user {user_id}: {user_message}")
        
        # Get agent
        agent = get_agent()
        
        logger.info("Agent initialized, calling Bedrock...")
        
        # Call agent with timeout handling
        import signal
        
        def timeout_handler(signum, frame):
            raise TimeoutError("Bedrock call timed out after 30 seconds")
        
        # Set 30-second timeout
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(30)
        
        try:
            response = agent(user_message)
            signal.alarm(0)  # Cancel timeout
            
            response_text = response.text if hasattr(response, 'text') else str(response)
            
            logger.info(f"Got response from Bedrock: {response_text[:100]}...")
            
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({
                    'response': response_text,
                    'userId': user_id,
                    'model': os.environ.get('BEDROCK_MODEL_ID'),
                    'region': os.environ.get('BEDROCK_REGION', 'us-east-1')
                })
            }
            
        except TimeoutError as te:
            signal.alarm(0)
            logger.error(f"Bedrock timeout: {str(te)}")
            return {
                'statusCode': 504,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({
                    'error': 'timeout',
                    'message': 'Bedrock API call timed out',
                    'model': os.environ.get('BEDROCK_MODEL_ID'),
                    'region': os.environ.get('BEDROCK_REGION', 'us-east-1')
                })
            }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'error': 'agent_error',
                'message': str(e),
                'model': os.environ.get('BEDROCK_MODEL_ID'),
                'region': os.environ.get('BEDROCK_REGION', 'us-east-1')
            })
        }
