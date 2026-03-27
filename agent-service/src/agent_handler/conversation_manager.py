"""
Conversation History Manager

Stores and retrieves conversation history for personalized recommendations.
Uses DynamoDB for persistence across sessions.
"""

import boto3
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from decimal import Decimal

logger = logging.getLogger()


class ConversationManager:
    """
    Manages conversation history and user context
    
    Features:
    - Store conversation messages
    - Track user preferences
    - Analyze purchase patterns
    - Provide context for recommendations
    """
    
    def __init__(self, table_name: str):
        """
        Initialize Conversation Manager
        
        Args:
            table_name: DynamoDB table for conversation history
        """
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)
        self.max_history = 50  # Keep last 50 messages
    
    def save_message(
        self,
        user_id: str,
        session_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Save a conversation message
        
        Args:
            user_id: User identifier
            session_id: Conversation session ID
            role: 'user' or 'assistant'
            content: Message content
            metadata: Additional context (products viewed, actions taken)
            
        Returns:
            Success status
        """
        try:
            timestamp = datetime.utcnow().isoformat()
            
            item = {
                'userId': user_id,
                'sessionId': session_id,
                'timestamp': timestamp,
                'role': role,
                'content': content,
                'metadata': json.dumps(metadata or {}, default=str),
                'ttl': int((datetime.utcnow() + timedelta(days=30)).timestamp())  # Auto-delete after 30 days
            }
            
            self.table.put_item(Item=item)
            logger.info(f"Saved message for user {user_id}, session {session_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving message: {str(e)}")
            return False
    
    def get_conversation_history(
        self,
        user_id: str,
        session_id: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Retrieve conversation history
        
        Args:
            user_id: User identifier
            session_id: Optional session filter
            limit: Maximum messages to return
            
        Returns:
            List of conversation messages
        """
        try:
            if session_id:
                # Get specific session
                response = self.table.query(
                    KeyConditionExpression='userId = :uid AND begins_with(sessionId, :sid)',
                    ExpressionAttributeValues={
                        ':uid': user_id,
                        ':sid': session_id
                    },
                    Limit=limit,
                    ScanIndexForward=False  # Most recent first
                )
            else:
                # Get all user conversations
                response = self.table.query(
                    KeyConditionExpression='userId = :uid',
                    ExpressionAttributeValues={
                        ':uid': user_id
                    },
                    Limit=limit,
                    ScanIndexForward=False
                )
            
            messages = response.get('Items', [])
            
            # Parse metadata
            for msg in messages:
                if 'metadata' in msg:
                    msg['metadata'] = json.loads(msg['metadata'])
            
            return messages
            
        except Exception as e:
            logger.error(f"Error retrieving history: {str(e)}")
            return []
    
    def analyze_user_preferences(self, user_id: str) -> Dict[str, Any]:
        """
        Analyze user's conversation history to extract preferences
        
        Args:
            user_id: User identifier
            
        Returns:
            User preferences and patterns
        """
        try:
            # Get recent history
            history = self.get_conversation_history(user_id, limit=50)
            
            # Extract patterns
            categories_mentioned = []
            price_ranges = []
            products_viewed = []
            keywords = []
            
            for msg in history:
                content = msg.get('content', '').lower()
                metadata = msg.get('metadata', {})
                
                # Extract categories
                if 'electronics' in content:
                    categories_mentioned.append('Electronics')
                if 'clothing' in content or 'fashion' in content:
                    categories_mentioned.append('Clothing')
                if 'books' in content:
                    categories_mentioned.append('Books')
                
                # Extract price preferences
                if 'under' in content or 'less than' in content:
                    import re
                    prices = re.findall(r'\$?(\d+)', content)
                    price_ranges.extend([int(p) for p in prices])
                
                # Extract products from metadata
                if 'products_viewed' in metadata:
                    products_viewed.extend(metadata['products_viewed'])
                
                # Extract keywords
                important_words = ['gaming', 'work', 'professional', 'budget', 'premium', 'portable']
                keywords.extend([w for w in important_words if w in content])
            
            # Calculate preferences
            preferences = {
                'favorite_categories': self._most_common(categories_mentioned, 3),
                'typical_budget': self._calculate_budget_range(price_ranges),
                'recently_viewed': products_viewed[:10],
                'interests': self._most_common(keywords, 5),
                'conversation_count': len(history),
                'last_interaction': history[0].get('timestamp') if history else None
            }
            
            return preferences
            
        except Exception as e:
            logger.error(f"Error analyzing preferences: {str(e)}")
            return {}
    
    def get_purchase_context(self, user_id: str) -> Dict[str, Any]:
        """
        Get context for current purchase intent
        
        Args:
            user_id: User identifier
            
        Returns:
            Purchase context for recommendations
        """
        try:
            # Get recent messages (last 5)
            recent = self.get_conversation_history(user_id, limit=5)
            
            # Extract current intent
            current_intent = ""
            products_discussed = []
            
            for msg in recent:
                if msg.get('role') == 'user':
                    current_intent = msg.get('content', '')
                    break
            
            # Get metadata from recent messages
            for msg in recent:
                metadata = msg.get('metadata', {})
                if 'products_discussed' in metadata:
                    products_discussed.extend(metadata['products_discussed'])
            
            return {
                'current_intent': current_intent,
                'products_discussed': list(set(products_discussed)),
                'conversation_length': len(recent),
                'user_preferences': self.analyze_user_preferences(user_id)
            }
            
        except Exception as e:
            logger.error(f"Error getting purchase context: {str(e)}")
            return {}
    
    def _most_common(self, items: List[str], n: int) -> List[str]:
        """Get n most common items from list"""
        from collections import Counter
        if not items:
            return []
        counter = Counter(items)
        return [item for item, count in counter.most_common(n)]
    
    def _calculate_budget_range(self, prices: List[int]) -> Dict[str, int]:
        """Calculate typical budget range from price mentions"""
        if not prices:
            return {'min': 0, 'max': 1000}
        
        return {
            'min': min(prices),
            'max': max(prices),
            'average': sum(prices) // len(prices)
        }
