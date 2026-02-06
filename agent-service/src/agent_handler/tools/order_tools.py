"""
Order Tools for Shopping Agent

Tools that call the Order Service API to create and track orders.
"""

import requests
import logging
from typing import Dict, Any, Optional
from strands_agents import tool

logger = logging.getLogger()


class OrderTools:
    """
    Order service integration tools
    
    Why: Encapsulates all Order Service API calls
    Pattern: Tool calling - agent decides when to use these
    """
    
    def __init__(self, api_url: str):
        """
        Initialize Order Tools
        
        Args:
            api_url: Order Service API base URL
        """
        self.api_url = api_url.rstrip('/')
        self.timeout = 30  # seconds (order creation can take longer)
    
    @tool(description="Create an order (checkout) for the user")
    def create_order(
        self,
        user_id: str,
        shipping_address: Optional[Dict[str, str]] = None,
        payment_method: str = "CARD"
    ) -> Dict[str, Any]:
        """
        Create an order from user's cart
        
        Args:
            user_id: User identifier
            shipping_address: Shipping address (street, city, state, zip)
            payment_method: Payment method (CARD, PAYPAL, etc.)
            
        Returns:
            Order details including order ID, total, status
            
        Example:
            create_order("user123", {"street": "123 Main St", "city": "Seattle"})
            Creates order from cart items
            
        Note: For high-value orders (>$1000), agent should ask for confirmation first
        """
        try:
            logger.info(f"Creating order for user: {user_id}")
            
            # Default shipping address if not provided
            if not shipping_address:
                shipping_address = {
                    'street': 'To be provided',
                    'city': 'To be provided',
                    'state': 'To be provided',
                    'zip': 'To be provided'
                }
            
            # Call Order Service API
            response = requests.post(
                f"{self.api_url}/orders",
                json={
                    'userId': user_id,
                    'shippingAddress': shipping_address,
                    'paymentMethod': payment_method
                },
                headers={'Content-Type': 'application/json'},
                timeout=self.timeout
            )
            
            if response.status_code == 400:
                error_data = response.json()
                return {
                    'error': error_data.get('message', 'Unable to create order'),
                    'success': False
                }
            
            response.raise_for_status()
            order = response.json()
            
            logger.info(f"Order created: {order.get('orderId')}, total: ${order.get('total')}")
            
            return {
                'success': True,
                'orderId': order.get('orderId'),
                'total': order.get('total'),
                'status': order.get('status'),
                'estimatedDelivery': order.get('estimatedDelivery', '3-5 business days'),
                'message': f"Order #{order.get('orderId')} created successfully!"
            }
            
        except requests.exceptions.Timeout:
            logger.error("Order Service timeout")
            return {
                'error': 'Order creation is taking longer than expected. Please check order status in a moment.',
                'success': False
            }
        except requests.exceptions.RequestException as e:
            logger.error(f"Error creating order: {str(e)}")
            return {
                'error': f'Unable to create order: {str(e)}',
                'success': False
            }
    
    @tool(description="Get order status and details")
    def get_order_status(self, order_id: str) -> Dict[str, Any]:
        """
        Get order details and current status
        
        Args:
            order_id: Order identifier
            
        Returns:
            Order details including status, items, total, tracking info
            
        Example:
            get_order_status("order-123")
            Returns order status and details
        """
        try:
            logger.info(f"Getting order status: {order_id}")
            
            # Call Order Service API
            response = requests.get(
                f"{self.api_url}/orders/{order_id}",
                timeout=self.timeout
            )
            
            if response.status_code == 404:
                return {
                    'error': 'Order not found',
                    'orderId': order_id
                }
            
            response.raise_for_status()
            order = response.json()
            
            logger.info(f"Order status: {order.get('status')}")
            
            return {
                'orderId': order.get('orderId'),
                'status': order.get('status'),
                'total': order.get('total'),
                'items': order.get('items', []),
                'createdAt': order.get('createdAt'),
                'shippingAddress': order.get('shippingAddress'),
                'trackingNumber': order.get('trackingNumber', 'Not available yet')
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error getting order status: {str(e)}")
            return {
                'error': f'Unable to get order status: {str(e)}',
                'orderId': order_id
            }
