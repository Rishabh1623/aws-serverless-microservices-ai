"""
Recommendation Tools for Shopping Agent

AI-powered product recommendations using Bedrock and user context.
"""

import requests
import logging
from typing import List, Dict, Any, Optional
from strands import tool
import boto3
import json

logger = logging.getLogger()

# Product categories and their complementary items
COMPLEMENTARY_PRODUCTS = {
    'laptop': ['mouse', 'keyboard', 'laptop bag', 'usb hub', 'monitor'],
    'phone': ['phone case', 'screen protector', 'charger', 'headphones', 'power bank'],
    'camera': ['memory card', 'camera bag', 'tripod', 'lens', 'battery'],
    'gaming': ['controller', 'headset', 'gaming chair', 'mouse pad', 'keyboard'],
    'fitness': ['yoga mat', 'water bottle', 'resistance bands', 'fitness tracker'],
    'cooking': ['knife set', 'cutting board', 'measuring cups', 'mixing bowls'],
}

# Purchase intent keywords
INTENT_KEYWORDS = {
    'work': ['productivity', 'office', 'professional', 'business'],
    'gaming': ['gaming', 'fps', 'rpg', 'multiplayer', 'esports'],
    'photography': ['photo', 'camera', 'lens', 'portrait', 'landscape'],
    'fitness': ['workout', 'exercise', 'gym', 'running', 'training'],
    'study': ['student', 'learning', 'education', 'school', 'college'],
    'entertainment': ['movie', 'music', 'streaming', 'entertainment'],
}


class RecommendationTools:
    """
    AI-powered recommendation engine
    
    Uses:
    - User conversation history
    - Purchase patterns
    - Product relationships
    - Bedrock for intelligent suggestions
    """
    
    def __init__(self, product_api_url: str, bedrock_model_id: str):
        """
        Initialize Recommendation Tools
        
        Args:
            product_api_url: Product Service API URL
            bedrock_model_id: Bedrock model for recommendations
        """
        self.product_api_url = product_api_url.rstrip('/')
        self.bedrock = boto3.client('bedrock-runtime')
        self.model_id = bedrock_model_id
        self.timeout = 10
    
    @tool(description="Get personalized product recommendations based on user's needs and conversation context")
    def get_smart_recommendations(
        self,
        user_intent: str,
        budget: Optional[float] = None,
        current_products: Optional[List[str]] = None,
        exclude_categories: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Generate intelligent product recommendations
        
        Args:
            user_intent: What the user wants to achieve (e.g., "work from home", "gaming setup")
            budget: Maximum budget for recommendations
            current_products: Products already in cart (for complementary suggestions)
            exclude_categories: Categories to exclude
            
        Returns:
            Personalized product recommendations with reasoning
            
        Example:
            get_smart_recommendations(
                user_intent="work from home setup",
                budget=2000
            )
        """
        try:
            logger.info(f"Generating recommendations for intent: {user_intent}")
            
            # Detect intent category
            intent_category = self._detect_intent_category(user_intent)
            
            # Get all products
            response = requests.get(
                f"{self.product_api_url}/products",
                timeout=self.timeout
            )
            response.raise_for_status()
            all_products = response.json().get('products', [])
            
            # Filter by budget
            if budget:
                all_products = [
                    p for p in all_products
                    if float(p.get('price', 0)) <= budget
                ]
            
            # Filter by excluded categories
            if exclude_categories:
                all_products = [
                    p for p in all_products
                    if p.get('category', '').lower() not in [c.lower() for c in exclude_categories]
                ]
            
            # Get complementary products if user has items in cart
            complementary_suggestions = []
            if current_products:
                complementary_suggestions = self._get_complementary_products(
                    current_products,
                    all_products
                )
            
            # Use Bedrock to generate intelligent recommendations
            recommendations = self._generate_ai_recommendations(
                user_intent=user_intent,
                intent_category=intent_category,
                available_products=all_products[:20],  # Limit for context
                budget=budget,
                complementary_products=complementary_suggestions
            )
            
            return {
                'recommendations': recommendations,
                'intent_detected': intent_category,
                'total_estimated_cost': sum(r.get('price', 0) for r in recommendations),
                'reasoning': f"Based on your goal to {user_intent}, here are my suggestions"
            }
            
        except Exception as e:
            logger.error(f"Error generating recommendations: {str(e)}")
            return {
                'error': str(e),
                'recommendations': [],
                'fallback_message': 'I can help you browse products by category instead'
            }
    
    @tool(description="Compare 2-3 products side by side with pros/cons")
    def compare_products(
        self,
        product_ids: List[str],
        comparison_criteria: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Compare multiple products with AI-powered analysis
        
        Args:
            product_ids: List of 2-3 product IDs to compare
            comparison_criteria: Specific aspects to compare (price, features, reviews)
            
        Returns:
            Detailed comparison with recommendations
            
        Example:
            compare_products(
                product_ids=["prod-001", "prod-002", "prod-003"],
                comparison_criteria=["price", "performance", "battery life"]
            )
        """
        try:
            if len(product_ids) < 2 or len(product_ids) > 3:
                return {
                    'error': 'Please provide 2-3 products to compare'
                }
            
            logger.info(f"Comparing products: {product_ids}")
            
            # Fetch product details
            products = []
            for pid in product_ids:
                response = requests.get(
                    f"{self.product_api_url}/products/{pid}",
                    timeout=self.timeout
                )
                if response.status_code == 200:
                    products.append(response.json())
            
            if len(products) < 2:
                return {
                    'error': 'Could not fetch enough products for comparison'
                }
            
            # Use Bedrock to generate comparison
            comparison = self._generate_ai_comparison(
                products=products,
                criteria=comparison_criteria or ['price', 'features', 'value']
            )
            
            return {
                'products': products,
                'comparison': comparison,
                'best_for': comparison.get('recommendations', {}),
                'winner': comparison.get('overall_winner', None)
            }
            
        except Exception as e:
            logger.error(f"Error comparing products: {str(e)}")
            return {
                'error': str(e),
                'products': []
            }
    
    @tool(description="Suggest complementary products based on what's in the cart")
    def suggest_bundle(
        self,
        cart_items: List[Dict[str, Any]],
        max_suggestions: int = 3
    ) -> Dict[str, Any]:
        """
        Suggest products that go well with cart items
        
        Args:
            cart_items: Current items in cart
            max_suggestions: Maximum number of suggestions
            
        Returns:
            Bundle suggestions with discount opportunities
            
        Example:
            suggest_bundle(
                cart_items=[{"productId": "laptop-001", "name": "MacBook Pro"}]
            )
            Returns: mouse, keyboard, laptop bag suggestions
        """
        try:
            logger.info(f"Generating bundle suggestions for {len(cart_items)} items")
            
            # Get all products
            response = requests.get(
                f"{self.product_api_url}/products",
                timeout=self.timeout
            )
            response.raise_for_status()
            all_products = response.json().get('products', [])
            
            # Extract cart product names/categories
            cart_product_names = [item.get('name', '').lower() for item in cart_items]
            
            # Find complementary products
            suggestions = []
            for cart_name in cart_product_names:
                for base_category, complements in COMPLEMENTARY_PRODUCTS.items():
                    if base_category in cart_name:
                        # Find products matching complementary items
                        for product in all_products:
                            product_name = product.get('name', '').lower()
                            if any(comp in product_name for comp in complements):
                                if product not in suggestions:
                                    suggestions.append(product)
            
            # Limit suggestions
            suggestions = suggestions[:max_suggestions]
            
            # Calculate bundle discount (10% off if buying 3+ items)
            cart_total = sum(item.get('price', 0) for item in cart_items)
            bundle_total = cart_total + sum(s.get('price', 0) for s in suggestions)
            discount = bundle_total * 0.10 if len(cart_items) + len(suggestions) >= 3 else 0
            
            return {
                'suggestions': suggestions,
                'bundle_discount': discount,
                'bundle_total': bundle_total - discount,
                'savings': discount,
                'message': f"Complete your setup! Save ${discount:.2f} when you add these items"
            }
            
        except Exception as e:
            logger.error(f"Error generating bundle: {str(e)}")
            return {
                'error': str(e),
                'suggestions': []
            }
    
    def _detect_intent_category(self, user_intent: str) -> str:
        """Detect user's purchase intent category"""
        user_intent_lower = user_intent.lower()
        
        for category, keywords in INTENT_KEYWORDS.items():
            if any(keyword in user_intent_lower for keyword in keywords):
                return category
        
        return 'general'
    
    def _get_complementary_products(
        self,
        current_products: List[str],
        all_products: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Find products that complement current selection"""
        complementary = []
        
        for product_name in current_products:
            product_name_lower = product_name.lower()
            
            for base_category, complements in COMPLEMENTARY_PRODUCTS.items():
                if base_category in product_name_lower:
                    for product in all_products:
                        if any(comp in product.get('name', '').lower() for comp in complements):
                            complementary.append(product)
        
        return complementary[:5]
    
    def _generate_ai_recommendations(
        self,
        user_intent: str,
        intent_category: str,
        available_products: List[Dict[str, Any]],
        budget: Optional[float],
        complementary_products: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Use Bedrock to generate intelligent recommendations"""
        
        # Create prompt for Bedrock
        prompt = f"""You are a helpful shopping assistant. Generate product recommendations.

User Intent: {user_intent}
Intent Category: {intent_category}
Budget: ${budget if budget else 'No limit'}

Available Products:
{json.dumps(available_products, indent=2)}

Complementary Products (if any):
{json.dumps(complementary_products, indent=2)}

Task: Select 3-5 products that best match the user's intent and budget. For each product, explain why it's recommended.

Return JSON format:
[
  {{
    "productId": "...",
    "name": "...",
    "price": ...,
    "reason": "Why this product fits the user's needs"
  }}
]
"""
        
        try:
            # Call Bedrock
            response = self.bedrock.invoke_model(
                modelId=self.model_id,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 1000,
                    "messages": [{
                        "role": "user",
                        "content": prompt
                    }]
                })
            )
            
            result = json.loads(response['body'].read())
            content = result['content'][0]['text']
            
            # Parse JSON from response
            import re
            json_match = re.search(r'\[.*\]', content, re.DOTALL)
            if json_match:
                recommendations = json.loads(json_match.group())
                return recommendations
            
        except Exception as e:
            logger.error(f"Bedrock recommendation error: {str(e)}")
        
        # Fallback: Return top products by price
        return sorted(available_products, key=lambda x: x.get('price', 0))[:3]
    
    def _generate_ai_comparison(
        self,
        products: List[Dict[str, Any]],
        criteria: List[str]
    ) -> Dict[str, Any]:
        """Use Bedrock to compare products"""
        
        prompt = f"""Compare these products based on the criteria provided.

Products:
{json.dumps(products, indent=2)}

Comparison Criteria: {', '.join(criteria)}

Provide:
1. Side-by-side comparison
2. Pros and cons for each
3. Best use case for each product
4. Overall winner and why

Return JSON format:
{{
  "comparison_table": {{}},
  "pros_cons": {{}},
  "recommendations": {{}},
  "overall_winner": "product_id"
}}
"""
        
        try:
            response = self.bedrock.invoke_model(
                modelId=self.model_id,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 1500,
                    "messages": [{
                        "role": "user",
                        "content": prompt
                    }]
                })
            )
            
            result = json.loads(response['body'].read())
            content = result['content'][0]['text']
            
            # Parse JSON
            import re
            json_match = re.search(r'\{.*\}', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group())
                
        except Exception as e:
            logger.error(f"Bedrock comparison error: {str(e)}")
        
        # Fallback comparison
        return {
            'comparison_table': {p['productId']: p for p in products},
            'overall_winner': products[0]['productId'] if products else None
        }
