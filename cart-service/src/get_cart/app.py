import json
import os
import boto3
import requests
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CART_TABLE'])

# Product API URL from environment
PRODUCT_API_URL = os.environ.get('PRODUCT_API_URL', '').rstrip('/')

def get_product_details(product_id):
    """Fetch product details from Product Service"""
    try:
        if not PRODUCT_API_URL:
            return None
        
        response = requests.get(
            f"{PRODUCT_API_URL}/products/{product_id}",
            timeout=5
        )
        
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        print(f"Error fetching product {product_id}: {str(e)}")
        return None

def lambda_handler(event, context):
    """Retrieve shopping cart contents for a user with product details"""
    try:
        user_id = event['pathParameters']['userId']
        
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Query all items for this user
        response = table.query(
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        
        cart_items = response.get('Items', [])
        
        # Enrich cart items with product details
        enriched_items = []
        total_price = 0
        
        for item in cart_items:
            product_id = item.get('productId')
            quantity = int(item.get('quantity', 0))
            
            # Fetch product details
            product = get_product_details(product_id)
            
            if product:
                price = float(product.get('price', 0))
                enriched_item = {
                    'productId': product_id,
                    'name': product.get('name', 'Unknown Product'),
                    'price': price,
                    'quantity': quantity,
                    'subtotal': price * quantity,
                    'imageUrl': product.get('imageUrl', ''),
                    'stock': product.get('stock', 0)
                }
                enriched_items.append(enriched_item)
                total_price += price * quantity
            else:
                # Product not found, include basic info
                enriched_items.append({
                    'productId': product_id,
                    'name': 'Product Not Found',
                    'price': 0,
                    'quantity': quantity,
                    'subtotal': 0
                })
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'userId': user_id,
                'items': enriched_items,
                'total': round(total_price, 2),
                'itemCount': len(enriched_items)
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except Exception as e:
        print(f"Error retrieving cart: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
