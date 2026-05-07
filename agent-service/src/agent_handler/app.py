"""
AI Travel Assistant Lambda Handler

AI-powered travel booking assistant using AWS Strands Agents SDK and Bedrock.
Features intelligent hotel recommendations and complete itinerary planning.

Key Features:
- Personalized hotel recommendations based on travel purpose
- Complete travel itinerary generation
- Natural language hotel search and booking
- Dynamic pricing with loyalty rewards
- Conversation history and preference tracking
"""

import json
import os
import logging
from typing import Dict, Any

from strands.agent import Agent
from anthropic import Anthropic
from tools.travel_planner_tools import TravelPlannerTools
from tools.upselling_tools import UpsellingTools
from conversation_manager import ConversationManager

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Enhanced system prompt with travel planning and upselling capabilities
SYSTEM_PROMPT = """
You are an intelligent AI Travel Assistant powered by AWS Bedrock.

Your capabilities:
🏨 Hotel & Travel Planning:
- Search hotels by destination, dates, and preferences
- Generate personalized hotel recommendations
- Create complete travel itineraries
- Suggest travel packages with discounts
- Compare hotels side-by-side

💰 Smart Upselling (Revenue Maximization):
- Ask intelligent questions about room preferences
- Suggest room upgrades with compelling reasons
- Recommend add-on services (spa, dining, tours)
- Offer extended stay discounts
- Suggest premium features (ocean view, high floor)
- Provide travel insurance options

🎯 AI-Powered Personalization:
- Remember conversation history and preferences
- Detect travel intent and purpose
- Analyze budget constraints
- Suggest complete travel solutions
- Loyalty rewards integration

Guidelines:
1. Always be warm, professional, and helpful
2. Ask clarifying questions to understand traveler needs
3. Proactively suggest upgrades and add-ons that enhance the experience
4. Focus on VALUE, not just price - explain WHY upgrades are worth it
5. Use emotional language for romantic trips, professional for business
6. Bundle services for better deals
7. For high-value bookings (>$2000), confirm details explicitly
8. Remember user preferences across conversations

🎯 Upselling Strategy (IMPORTANT):
When a user shows interest in booking:
1. Ask about room preferences (view, floor, size)
2. Inquire about location preferences within hotel
3. Suggest relevant add-ons based on travel purpose:
   - Romantic: Spa packages, private dinners, room decorations
   - Business: Meeting rooms, airport transfers, express services
   - Family: Kids club, family activities, meal plans
   - Leisure: Tours, experiences, wellness activities
4. Offer extended stay discounts (stay longer, save more)
5. Suggest premium features (ocean view, balcony, corner room)
6. Recommend travel protection for peace of mind

Example Upselling Flow:
User: "I want to book the Deluxe Room for 3 nights"
You: "Great choice! Before I finalize your booking, let me help you get the most out of your stay:

🏨 Room Preferences:
- Would you prefer an ocean view? It's only $50/night more and the sunrise is breathtaking
- Interested in a higher floor for better views and quieter stay?

✨ Enhance Your Experience:
- Since you're staying 3 nights, I can offer a couples spa package at 15% off
- We have a special: extend to 5 nights and get 20% off the extra nights

What sounds good to you?"

Revenue Maximization Rules:
- ALWAYS ask about preferences before finalizing booking
- Suggest at least 2-3 relevant upgrades/add-ons
- Use scarcity ("limited availability") when appropriate
- Emphasize savings and value ("only $X more per night")
- Bundle multiple add-ons for better discounts
- Make it emotional - focus on memories and experiences

Context Awareness:
- Track booking stage (browsing → interested → ready to book)
- Remember discussed hotels and preferences
- Reference loyalty status and offer tier-based benefits
- Use conversation history for personalized upselling
"""

# Initialize tools (lazy loading for Lambda cold start optimization)
_travel_planner_tools = None
_upselling_tools = None
_conversation_manager = None
_agent = None


def get_tools():
    """
    Initialize tools (lazy loading)
    
    Why: Reduces Lambda cold start time by initializing only when needed
    """
    global _travel_planner_tools, _upselling_tools
    
    if _travel_planner_tools is None:
        _travel_planner_tools = TravelPlannerTools(
            hotel_api_url=os.environ.get('HOTEL_API_URL'),
            bedrock_model_id=os.environ.get(
                'BEDROCK_MODEL_ID',
                'us.anthropic.claude-haiku-4-5-20251001-v1:0'
            )
        )
    
    if _upselling_tools is None:
        _upselling_tools = UpsellingTools(
            hotel_api_url=os.environ.get('HOTEL_API_URL'),
            bedrock_model_id=os.environ.get(
                'BEDROCK_MODEL_ID',
                'us.anthropic.claude-haiku-4-5-20251001-v1:0'
            )
        )
    
    return [
        # Travel Planner tools
        _travel_planner_tools.recommend_hotels,
        _travel_planner_tools.create_itinerary,
        _travel_planner_tools.suggest_packages,
        _travel_planner_tools.compare_hotels,
        # Upselling tools (Revenue Maximization)
        _upselling_tools.suggest_room_upgrade,
        _upselling_tools.suggest_addons,
        _upselling_tools.suggest_extended_stay,
        _upselling_tools.suggest_premium_features,
        _upselling_tools.suggest_travel_protection
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
    
    Uses Anthropic API directly to bypass AWS Bedrock billing issues.
    Strands SDK supports both Bedrock and Anthropic providers.
    """
    global _agent
    
    if _agent is None:
        # Check if we should use Anthropic direct API or Bedrock
        use_anthropic_direct = os.environ.get('USE_ANTHROPIC_DIRECT', 'true').lower() == 'true'
        
        if use_anthropic_direct:
            # Use Anthropic API directly (bypasses Bedrock billing)
            anthropic_api_key = os.environ.get('ANTHROPIC_API_KEY')
            if not anthropic_api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable is required")
            
            logger.info("Using Anthropic API directly (bypassing Bedrock)")
            _agent = Agent(
                system_prompt=SYSTEM_PROMPT,
                tools=get_tools(),
                model="claude-3-5-haiku-20241022",  # Anthropic model ID format
                client=Anthropic(api_key=anthropic_api_key)
            )
        else:
            # Use AWS Bedrock (original approach)
            logger.info("Using AWS Bedrock")
            _agent = Agent(
                system_prompt=SYSTEM_PROMPT,
                tools=get_tools(),
                model=os.environ.get(
                    'BEDROCK_MODEL_ID',
                    'anthropic.claude-3-haiku-20240307-v1:0'
                )
            )
    
    return _agent


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Travel Agent
    
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
                'message': 'I\'m having trouble right now. Please try using the traditional hotel search.',
                'fallback_urls': {
                    'hotels': os.environ.get('HOTEL_API_URL', ''),
                    'cart': os.environ.get('CART_API_URL', ''),
                    'orders': os.environ.get('ORDER_API_URL', '')
                }
            })
        }
