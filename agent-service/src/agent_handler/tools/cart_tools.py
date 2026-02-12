"""
Cart Tools for Shopping Agent

Tools that call the Cart Service API to manage shopping cart operations.
Best practices: Proper error handling, detailed logging, timeout management.
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
    Best practices: Retry logic, detailed error messages, proper logging
    """
    
    def __init__(self, api_url: str):
        """
        Initialize Cart Tools
        
        Args:
            api_url: Cart Service API base URL
        """
        self.api_url = api_url.rstrip('/')
        self.timeout = 10  # seconds
        self.max_retries = 2
    
    def _make_request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """
        Make HTTP request with retry logic
        
        Args:
            method: HTTP method (GET, POST, DELETE)
            endpoint: API endpoint path
            **kwargs: Additional arguments for requests
            
        Returns:
            Response object
            
        Raises:
            requests.exceptions.RequestException: On failure after retries
        """
        url = f"{self.api_url}{endpoint}"
        
        for attempt in range(self.max_retries + 1):
            try:
                logger.info(f"Cart API request: {method} {url} (attempt {attempt + 1})")
                response = getattr(requests, method.lower())(url, timeout=self.timeout, **kwargs)
                logger.info(f"Cart API response: {response.status_code}")
                return response
            except requests.exceptions.Timeout:
                if attempt == self.max_retries:
                    logger.error(f"Cart API timeout after {self.max_retries + 1} attempts")
                    raise
                logger.warning(f"Cart API timeout, retrying... (attempt {attempt + 1})")
            except requests.exceptions.RequestException as e:
                logger.error(f"Cart API error: {str(e)}")
                raise
    
    @tool(description="Add a product to the user's shopping cart. Use the productId from search results.")
    def add_to_cart(
        self,
        user_id: str,
        product_id: str,
        quantity: int = 1
    ) -> Dict[str, Any]:
        """
        Add item to shopping cart
        
        Args:
            user_id: User identifier (e.g., "user123")
            product_id: Product ID from catalog (e.g., "prod-001")
            quantity: Number of items (default: 1, must be positive)
            
        Returns:
            Success status and cart information
            
        Example:
            add_to_cart("user123", "prod-001", 1)
            
        Best practice:
            Always search for products first to get the correct product_id
        """
        try:
            # Validate inputs
            if not user_id or not product_id:
                return {
                    'success': False,
                    'error': 'user_id and product_id are required'
                }
            
            if quantity < 1:
                return {
                    'success': False,
                    'error': 'Quantity must be at least 1'
                }
            
            logger.info(f"Adding to cart: user={user_id}, product={product_id}, qty={quantity}")
            
            # Make API request
            response = self._make_request(
                'POST',
                '/cart/add',
                json={
                    'userId': user_id,
                    'productId': product_id,
                    'quantity': quantity
                },
                headers={'Content-Type': 'application/json'}
            )
            
            # Handle response
            if response.status_code == 200:
                result = response.json()
                logger.info(f"Successfully added to cart: {result}")
                return {
                    'success': True,
                    'message': f'Successfully added {quantity} item(s) to cart',
                    'productId': product_id,
                    'quantity': quantity
                }
            else:
                error_msg = response.text
                logger.error(f"Cart API error: {response.status_code} - {error_msg}")
                return {
                    'success': False,
                    'error': f'Failed to add to cart: {error_msg}',
                    'status_code': response.status_code
                }
            
        except requests.exceptions.Timeout:
            logger.error("Cart Service timeout")
            return {
                'success': False,
                'error': 'Cart Service is not responding. Please try again in a moment.'
            }
        except requests.exceptions.RequestException as e:
            logger.error(f"Cart Service error: {str(e)}")
            return {
                'success': False,
                'error': f'Unable to connect to Cart Service: {str(e)}'
            }
        except Exception as e:
            logger.error(f"Unexpected error in add_to_cart: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': 'An unexpected error occurred. Please try again.'
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
        """
        try:
            if not user_id or not product_id:
                return {
                    'success': False,
                    'error': 'user_id and product_id are required'
                }
            
            logger.info(f"Removing from cart: user={user_id}, product={product_id}")
            
            response = self._make_request(
                'POST',
                '/cart/remove',
                json={
                    'userId': user_id,
                    'productId': product_id
                },
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 200:
                logger.info("Successfully removed from cart")
                return {
                    'success': True,
                    'message': 'Item removed from cart'
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to remove from cart: {response.text}'
                }
            
        except Exception as e:
            logger.error(f"Error removing from cart: {str(e)}")
            return {
                'success': False,
                'error': f'Unable to remove from cart: {str(e)}'
            }
    
    @tool(description="View the user's current shopping cart contents")
    def view_cart(self, user_id: str) -> Dict[str, Any]:
        """
        Get cart contents for a user
        
        Args:
            user_id: User identifier
            
        Returns:
            Cart items and total information
        """
        try:
            if not user_id:
                return {
                    'success': False,
                    'error': 'user_id is required',
                    'items': [],
                    'itemCount': 0
                }
            
            logger.info(f"Viewing cart for user: {user_id}")
            
            response = self._make_request('GET', f'/cart/{user_id}')
            
            if response.status_code == 404:
                return {
                    'success': True,
                    'items': [],
                    'itemCount': 0,
                    'message': 'Cart is empty'
                }
            
            if response.status_code == 200:
                cart = response.json()
                items = cart.get('items', [])
                logger.info(f"Cart has {len(items)} items")
                return {
                    'success': True,
                    'items': items,
                    'itemCount': len(items),
                    'userId': user_id
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to view cart: {response.text}',
                    'items': [],
                    'itemCount': 0
                }
            
        except Exception as e:
            logger.error(f"Error viewing cart: {str(e)}")
            return {
                'success': False,
                'error': f'Unable to view cart: {str(e)}',
                'items': [],
                'itemCount': 0
            }
