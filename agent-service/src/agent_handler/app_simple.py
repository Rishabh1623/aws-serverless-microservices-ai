"""
Simplified AI Travel Assistant - Direct Bedrock Integration
No external dependencies except boto3 (included in Lambda runtime)
"""

import json
import os
import logging
import boto3
from typing import Dict, Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# API endpoints from environment
HOTEL_API_URL = os.environ.get('HOTEL_API_URL')
CART_API_URL = os.environ.get('CART_API_URL')
ORDER_API_URL = os.environ.get('ORDER_API_URL')
PAYMENT_API_URL = os.environ.get('PAYMENT_API_URL')

SYSTEM_PROMPT = """You are a helpful AI travel assistant. You can help users:
- Search for hotels
- Get hotel information
- Add hotels to cart
- Create orders
- Process payments

Be friendly and helpful. Keep responses concise."""

def lambda_handler(event, context):
    """
    Handle AI travel assistant requests
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')
        user_id = body.get('userId', 'anonymous')
        
        logger.info(f"User {user_id}: {user_message}")
        
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'message is required'})
            }
        
        # Call Bedrock to generate response
        response_text = call_bedrock(user_message, user_id)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': response_text,
                'userId': user_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Internal server error'})
        }

def call_bedrock(user_message: str, user_id: str) -> str:
    """
    Call AWS Bedrock to generate AI response
    """
    try:
        # Prepare the prompt
        prompt = f"""{SYSTEM_PROMPT}

User: {user_message}