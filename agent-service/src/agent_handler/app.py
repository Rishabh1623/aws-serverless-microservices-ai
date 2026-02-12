"""
Shopping Agent Lambda Handler

AI-powered shopping assistant using AWS Strands Agents SDK and Bedrock.
Orchestrates Product, Cart, Order, and Payment services through natural language.
"""

import json
import os
import logging
from typing import Dict, Any

from strands.agent import Agent
from tools.product_tools import ProductTools
from tools.cart_tools import CartTools
from tools.order_tools import OrderTools
from tools.payment_tools import PaymentTools

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# System prompt defines agent behavior
SYSTEM_PROMPT = """
You are a helpful e-commerce shopping assistant for a serverless microservices platform.

Your capabilities:
- Search for products by name, category, or price range
- Get detailed product information
- Add items to shopping cart
- View cart contents
- Create orders (checkout)
- Track order status
- Check payment status

Guidelines:
1. Always be polite and professional
2. When mentioning prices, include currency (USD)
3. When adding items to cart, use the exact productId from search results
4. Confirm actions before executing (e.g., "Shall I add this to your cart?")
5. For high-value orders (>$1000), ask for explicit confirmation
6. If a product is out of stock, suggest alternatives
7. Provide order tracking information after checkout

Important workflow:
- When user asks to add a product, first search for it to get the productId
- Use the productId (e.g., "prod-001") when calling add_to_cart
- The user's userId is available in the request context
- Always confirm successful actions with the user

Error handling:
- If a service is unavailable, apologize and suggest trying again
- If a product doesn't exist, offer to search for similar items
- If cart is empty at checkout, remind user to add items first
- Log all errors for debugging but provide friendly messages to users

Context awareness:
- Remember items discussed in the conversation
- Track user's cart state
- Reference previous orders when relevant
"""

# Initialize tools (lazy loading for Lambda cold start optimization)
_product_tools = None
_cart_tools = None
_order_tools = None
_payment_tools = None
_agent = None


def get_tools():
    """
    Initialize tools (lazy loading)
    
    Why: Reduces Lambda cold start time by initializing only when needed
    """
    global _product_tools, _cart_tools, _order_tools, _payment_tools
    
    if _product_tools is None:
        _product_tools = ProductTools(
            api_url=os.environ['PRODUCT_API_URL']
        )
    
    if _cart_tools is None:
        _cart_tools = CartTools(
            api_url=os.environ['CART_API_URL']
        )
    
    if _order_tools is None:
        _order_tools = OrderTools(
            api_url=os.environ['ORDER_API_URL']
        )
    
    if _payment_tools is None:
        _payment_tools = PaymentTools(
            api_url=os.environ['PAYMENT_API_URL']
        )
    
    return [
        _product_tools.search_products,
        _product_tools.get_product_details,
        _cart_tools.add_to_cart,
        _cart_tools.remove_from_cart,
        _cart_tools.view_cart,
        _order_tools.create_order,
        _order_tools.get_order_status,
        _payment_tools.get_payment_status
    ]


def get_agent():
    """
    Initialize Strands Agent (lazy loading)
    
    Why: Reuse agent across warm Lambda invocations
    """
    global _agent
    
    if _agent is None:
        _agent = Agent(
            system_prompt=SYSTEM_PROMPT,
            tools=get_tools(),
            model=os.environ.get(
                'BEDROCK_MODEL_ID',
                'anthropic.claude-3-sonnet-20240229-v1:0'
            )
        )
    
    return _agent


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Shopping Agent
    
    Args:
        event: API Gateway event with user message
        context: Lambda context
        
    Returns:
        API Gateway response with agent's reply
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')
        user_id = body.get('userId', 'guest')
        session_id = body.get('sessionId', None)
        
        # Validate input
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required field: message'
                })
            }
        
        logger.info(f"Processing message from user {user_id}: {user_message}")
        
        # Get agent instance
        agent = get_agent()
        
        # Process message through agent (call agent directly)
        response = agent(user_message)
        
        # Log tools used (for monitoring)
        if hasattr(response, 'tools_used'):
            logger.info(f"Tools used: {response.tools_used}")
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': response.text if hasattr(response, 'text') else str(response),
                'toolsUsed': response.tools_used if hasattr(response, 'tools_used') else [],
                'userId': user_id,
                'sessionId': session_id
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        
        # Graceful degradation: Return helpful error message
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'agent_error',
                'message': 'I\'m having trouble right now. Please try using the traditional shopping interface.',
                'fallback_urls': {
                    'products': os.environ.get('PRODUCT_API_URL', ''),
                    'cart': os.environ.get('CART_API_URL', ''),
                    'orders': os.environ.get('ORDER_API_URL', '')
                }
            })
        }
