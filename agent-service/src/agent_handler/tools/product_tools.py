"""
Product Tools for Shopping Agent

Tools that call the Product Service API to search and retrieve product information.
"""

import requests
import logging
from typing import Optional, List, Dict, Any
from strands import tool

logger = logging.getLogger()


class ProductTools:
    """
    Product service integration tools
    
    Why: Encapsulates all Product Service API calls
    Pattern: Tool calling - agent decides when to use these
    """
    
    def __init__(self, api_url: str):
        """
        Initialize Product Tools
        
        Args:
            api_url: Product Service API base URL
        """
        self.api_url = api_url.rstrip('/')
        self.timeout = 10  # seconds
    
    @tool(description="Search for products by name, category, or price range")
    def search_products(
        self,
        query: Optional[str] = None,
        category: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        limit: int = 10
    ) -> Dict[str, Any]:
        """
        Search products in the catalog
        
        Args:
            query: Search term for product name or description
            category: Filter by category (Electronics, Clothing, Books, etc.)
            min_price: Minimum price filter
            max_price: Maximum price filter
            limit: Maximum number of results (default: 10)
            
        Returns:
            Dictionary with products list and count
            
        Example:
            search_products(query="laptop", max_price=1000)
            Returns laptops under $1000
        """
        try:
            logger.info(f"Searching products: query={query}, category={category}, price={min_price}-{max_price}")
            
            # Call Product Service API
            response = requests.get(
                f"{self.api_url}/products",
                timeout=self.timeout
            )
            response.raise_for_status()
            
            products = response.json().get('products', [])
            
            # Apply filters
            filtered_products = products
            
            if query:
                query_lower = query.lower()
                filtered_products = [
                    p for p in filtered_products
                    if query_lower in p.get('name', '').lower()
                    or query_lower in p.get('description', '').lower()
                ]
            
            if category:
                filtered_products = [
                    p for p in filtered_products
                    if p.get('category', '').lower() == category.lower()
                ]
            
            if min_price is not None:
                filtered_products = [
                    p for p in filtered_products
                    if float(p.get('price', 0)) >= min_price
                ]
            
            if max_price is not None:
                filtered_products = [
                    p for p in filtered_products
                    if float(p.get('price', float('inf'))) <= max_price
                ]
            
            # Limit results
            filtered_products = filtered_products[:limit]
            
            logger.info(f"Found {len(filtered_products)} products")
            
            return {
                'products': filtered_products,
                'count': len(filtered_products),
                'filters_applied': {
                    'query': query,
                    'category': category,
                    'min_price': min_price,
                    'max_price': max_price
                }
            }
            
        except requests.exceptions.Timeout:
            logger.error("Product Service timeout")
            return {
                'error': 'Product Service is taking too long to respond',
                'products': [],
                'count': 0
            }
        except requests.exceptions.RequestException as e:
            logger.error(f"Product Service error: {str(e)}")
            return {
                'error': f'Unable to search products: {str(e)}',
                'products': [],
                'count': 0
            }
    
    @tool(description="Get detailed information about a specific product")
    def get_product_details(self, product_id: str) -> Dict[str, Any]:
        """
        Get full details of a product
        
        Args:
            product_id: The unique product identifier
            
        Returns:
            Product details including name, price, description, stock, etc.
            
        Example:
            get_product_details("prod-001")
            Returns full product information
        """
        try:
            logger.info(f"Getting product details: {product_id}")
            
            # Call Product Service API
            response = requests.get(
                f"{self.api_url}/products/{product_id}",
                timeout=self.timeout
            )
            
            if response.status_code == 404:
                return {
                    'error': 'Product not found',
                    'product_id': product_id
                }
            
            response.raise_for_status()
            product = response.json()
            
            logger.info(f"Retrieved product: {product.get('name')}")
            
            return product
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error getting product details: {str(e)}")
            return {
                'error': f'Unable to get product details: {str(e)}',
                'product_id': product_id
            }
