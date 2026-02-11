"""
Cart Tools for Shopping Agent

Tools that call the Cart Service API to manage shopping cart operations.
"""

import requests
import logging
from typing import Dict, Any
from strands import tool

logger = logging.getLogger()


class CartTools:
    """
    Cart service integration tools
    
    Why: Encapsulates all Cart Service API calls
    Pattern: Tool calling - agent decides when to use these
    """
    
    def __init__(self, api_url: str):
        """
        Initialize Cart Tools
        
        Args:
            api_url: Cart Service API base URL
        """
        self.api_url = api_url.rstrip('/')
        self.timeout = 10  # seconds
    
    @tool(description="Add a product to the user's shopping cart")
    def add_to_cart(
        self,
        user_id: str,
        product_id: str,
        quantity: int = 1
    ) -> Dict[str, Any]:
        """
        Add item to shopping cart
        
        Args:
            user_id: User identifier
            product_id: Product to add
            quantity: Number of items (default: 1, must be positive)
            
        Returns:
            Success status and updated cart information
            
        Example:
            add_to_cart("user123", "prod-001", 2)
            Adds 2 units of product to cart
        """
        try:
            # Validate quantity
            if quantity < 1:
                return {
                    'error': 'Quantity must be at least 1',
                    'success': False
                }
            
            logger.info(f"Adding to cart: user={user_id}, product={product_id}, qty={quantity}")
            
            # Call Cart Service API
            response = requests.post(
                f"{self.api_url}/cart/add",
                json={
                    'userId': user_id,
                    'productId': product_id,
                    'quantity': quantity
                },
                headers={'Content-Type': 'application/json'},
                timeout=self.timeout
            )
            response.raise_for_status()
            
            result = response.json()
            logger.info(f"Added to cart successfully. Cart total: ${result.get('cartTotal', 0)}")
            
            return {
                'success': True,
                'message': f'Added {quantity} item(s) to cart',
                'cartTotal': result.get('cartTotal', 0),
                'itemCount': result.get('itemCount', 0)
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error adding to cart: {str(e)}")
            return {
                'error': f'Unable to add to cart: {str(e)}',
                'success': False
            }
    
    @tool(description="Remove a product from the user's shopping cart")
    def remove_from_cart(
        self,
        user_id: str,
        product_id: str
    ) -> Dict[str, Any]:
        """
        Remove item from shopping cart
        
        Args:
            user_id: User identifier
            product_id: Product to remove
            
        Returns:
            Success status and updated cart information
            
        Example:
            remove_from_cart("user123", "prod-001")
            Removes product from cart
        """
        try:
            logger.info(f"Removing from cart: user={user_id}, product={product_id}")
            
            # Call Cart Service API
            response = requests.delete(
                f"{self.api_url}/cart/remove",
                json={
                    'userId': user_id,
                    'productId': product_id
                },
                headers={'Content-Type': 'application/json'},
                timeout=self.timeout
            )
            response.raise_for_status()
            
            result = response.json()
            logger.info(f"Removed from cart successfully")
            
            return {
                'success': True,
                'message': 'Item removed from cart',
                'cartTotal': result.get('cartTotal', 0),
                'itemCount': result.get('itemCount', 0)
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error removing from cart: {str(e)}")
            return {
                'error': f'Unable to remove from cart: {str(e)}',
                'success': False
            }
    
    @tool(description="View the user's current shopping cart contents")
    def view_cart(self, user_id: str) -> Dict[str, Any]:
        """
        Get cart contents for a user
        
        Args:
            user_id: User identifier
            
        Returns:
            Cart items, total price, and item count
            
        Example:
            view_cart("user123")
            Returns all items in user's cart
        """
        try:
            logger.info(f"Viewing cart for user: {user_id}")
            
            # Call Cart Service API
            response = requests.get(
                f"{self.api_url}/cart/{user_id}",
                timeout=self.timeout
            )
            
            if response.status_code == 404:
                return {
                    'items': [],
                    'total': 0,
                    'itemCount': 0,
                    'message': 'Cart is empty'
                }
            
            response.raise_for_status()
            cart = response.json()
            
            logger.info(f"Cart has {len(cart.get('items', []))} items")
            
            return {
                'items': cart.get('items', []),
                'total': cart.get('total', 0),
                'itemCount': len(cart.get('items', [])),
                'userId': user_id
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error viewing cart: {str(e)}")
            return {
                'error': f'Unable to view cart: {str(e)}',
                'items': [],
                'total': 0,
                'itemCount': 0
            }
