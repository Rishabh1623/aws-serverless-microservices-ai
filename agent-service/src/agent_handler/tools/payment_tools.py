"""
Payment Tools for Shopping Agent

Tools that call the Payment Service API to check payment status.
"""

import requests
import logging
from typing import Dict, Any
from strands import tool

logger = logging.getLogger()


class PaymentTools:
    """
    Payment service integration tools
    
    Why: Encapsulates all Payment Service API calls
    Pattern: Tool calling - agent decides when to use these
    
    Note: Agent doesn't process payments directly (security)
          Only checks payment status for orders
    """
    
    def __init__(self, api_url: str):
        """
        Initialize Payment Tools
        
        Args:
            api_url: Payment Service API base URL
        """
        self.api_url = api_url.rstrip('/')
        self.timeout = 10  # seconds
    
    @tool(description="Get payment status for an order")
    def get_payment_status(self, payment_id: str) -> Dict[str, Any]:
        """
        Get payment details and status
        
        Args:
            payment_id: Payment identifier (usually from order)
            
        Returns:
            Payment status, amount, method, timestamp
            
        Example:
            get_payment_status("pay-123")
            Returns payment status (COMPLETED, PENDING, FAILED)
            
        Security Note:
            - Agent can only VIEW payment status
            - Agent cannot PROCESS payments (security best practice)
            - Sensitive payment details (card numbers) are never exposed
        """
        try:
            logger.info(f"Getting payment status: {payment_id}")
            
            # Call Payment Service API
            response = requests.get(
                f"{self.api_url}/payments/{payment_id}",
                timeout=self.timeout
            )
            
            if response.status_code == 404:
                return {
                    'error': 'Payment not found',
                    'paymentId': payment_id
                }
            
            response.raise_for_status()
            payment = response.json()
            
            logger.info(f"Payment status: {payment.get('status')}")
            
            return {
                'paymentId': payment.get('paymentId'),
                'status': payment.get('status'),
                'amount': payment.get('amount'),
                'currency': payment.get('currency', 'USD'),
                'method': payment.get('method'),
                'orderId': payment.get('orderId'),
                'processedAt': payment.get('processedAt')
            }
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error getting payment status: {str(e)}")
            return {
                'error': f'Unable to get payment status: {str(e)}',
                'paymentId': payment_id
            }
