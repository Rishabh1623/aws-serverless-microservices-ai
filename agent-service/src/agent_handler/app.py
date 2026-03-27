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
from tools.recommendation_tools import RecommendationTools
from tools.travel_planner_tools import TravelPlannerTools
from conversation_manager import ConversationManager

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Enhanced system prompt with recommendation capabilities
SYSTEM_PROMPT = """
You are an intelligent e-commerce shopping assistant powered by AI.

Your capabilities:
- Search for products by name, category, or price range
- Get detailed product information
- Add items to shopping cart
- View cart contents
- Create orders (checkout)
- Track order status
- Check payment status

🎯 NEW: Advanced AI Features:
- Generate personalized product recommendations based on user's needs
- Compare 2-3 products side-by-side with pros/cons
- Suggest complementary products (bundles)
- Remember conversation history and user preferences
- Detect purchase intent and suggest complete solutions

Guidelines:
1. Always be polite and professional
2. When mentioning prices, include currency (USD)
3. Proactively suggest recommendations based on user's stated needs
4. When user mentions a purpose (e.g., "work from home", "gaming"), use get_smart_recommendations
5. If user is deciding between products, offer to compare them
6. When user adds items to cart, suggest complementary products
7. For high-value orders (>$1000), ask for explicit confirmation
8. If a product is out of stock, suggest alternatives
9. Remember previous conversations to provide personalized service

Recommendation Strategy:
- Ask about user's purpose/goal before recommending
- Consider budget constraints
- Suggest complete solutions, not just individual products
- Explain WHY each product is recommended
- Offer bundle discounts when suggesting multiple items

Example Interactions:
User: "I need a laptop for work"
You: "I'd be happy to help! To give you the best recommendations:
- What's your budget?
- What type of work? (coding, design, general office)
- Do you need portability or prefer performance?

Based on your answers, I'll suggest a complete work-from-home setup including laptop, accessories, and peripherals."

User: "Compare MacBook Pro and Dell XPS"
You: "I'll compare these two laptops for you across key criteria like performance, price, battery life, and value. Let me pull up the details..."

Context awareness:
- Remember items discussed in the conversation
- Track user's cart state and suggest complementary items
- Reference previous orders when relevant
- Use conversation history to personalize recommendations
"""

# Initialize tools (lazy loading for Lambda cold start optimization)
_product_tools = None
_cart_tools = None
_order_tools = None
_payment_tools = None
_recommendation_tools = None
_travel_planner_tools = None
_conversation_manager = None
_agent = None


def get_tools():
    """
    Initialize tools (lazy loading)
    
    Why: Reduces Lambda cold start time by initializing only when needed
    """
    global _product_tools, _cart_tools, _order_tools, _payment_tools, _recommendation_tools, _travel_planner_tools
    
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
    
    if _recommendation_tools is None:
        _recommendation_tools = RecommendationTools(
            product_api_url=os.environ['PRODUCT_API_URL'],
            bedrock_model_id=os.environ.get(
                'BEDROCK_MODEL_ID',
                'anthropic.claude-3-sonnet-20240229-v1:0'
            )
        )
    
    if _travel_planner_tools is None:
        _travel_planner_tools = TravelPlannerTools(
            hotel_api_url=os.environ.get('HOTEL_API_URL', os.environ['PRODUCT_API_URL']),
            bedrock_model_id=os.environ.get(
                'BEDROCK_MODEL_ID',
                'anthropic.claude-3-sonnet-20240229-v1:0'
            )
        )
    
    return [
        # Product tools
        _product_tools.search_products,
        _product_tools.get_product_details,
        # Cart tools
        _cart_tools.add_to_cart,
        _cart_tools.remove_from_cart,
        _cart_tools.view_cart,
        # Order tools
        _order_tools.create_order,
        _order_tools.get_order_status,
        # Payment tools
        _payment_tools.get_payment_status,
        # Recommendation tools
        _recommendation_tools.get_smart_recommendations,
        _recommendation_tools.compare_products,
        _recommendation_tools.suggest_bundle,
        # Travel Planner tools
        _travel_planner_tools.recommend_hotels,
        _travel_planner_tools.create_itinerary,
        _travel_planner_tools.suggest_packages,
        _travel_planner_tools.compare_hotels
    ]


def get_conversation_manager():
    """Initialize conversation manager (lazy loading)"""
    global _conversation_manager
    
    if _conversation_manager is None:
        _conversation_manager = ConversationManager(
            table_name=os.environ.get('CONVERSATION_TABLE', 'agent-conversations')
        )
    
    return _conversation_manager


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
        
        # Get conversation manager
        conv_manager = get_conversation_manager()
        
        # Generate session ID if not provided
        if not session_id:
            from datetime import datetime
            session_id = f"{user_id}-{datetime.utcnow().strftime('%Y%m%d')}"
        
        # Save user message to history
        conv_manager.save_message(
            user_id=user_id,
            session_id=session_id,
            role='user',
            content=user_message
        )
        
        # Get user context for personalization
        user_context = conv_manager.get_purchase_context(user_id)
        
        # Enhance message with context if available
        enhanced_message = user_message
        if user_context.get('user_preferences'):
            prefs = user_context['user_preferences']
            context_note = f"\n\n[User Context: Interested in {', '.join(prefs.get('favorite_categories', []))}, typical budget: ${prefs.get('typical_budget', {}).get('max', 'N/A')}]"
            enhanced_message += context_note
        
        # Get agent instance
        agent = get_agent()
        
        # Process message through agent
        response = agent(enhanced_message)
        
        # Extract response text
        response_text = response.text if hasattr(response, 'text') else str(response)
        tools_used = response.tools_used if hasattr(response, 'tools_used') else []
        
        # Save assistant response to history
        conv_manager.save_message(
            user_id=user_id,
            session_id=session_id,
            role='assistant',
            content=response_text,
            metadata={'tools_used': tools_used}
        )
        
        # Log tools used (for monitoring)
        logger.info(f"Tools used: {tools_used}")
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': response_text,
                'toolsUsed': tools_used,
                'userId': user_id,
                'sessionId': session_id,
                'userContext': {
                    'conversationLength': user_context.get('conversation_length', 0),
                    'preferences': user_context.get('user_preferences', {})
                }
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
