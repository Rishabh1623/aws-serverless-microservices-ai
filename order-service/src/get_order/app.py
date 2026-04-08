"""
Get Order Lambda Handler

Retrieves order details by order ID.
"""

import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])

def lambda_handler(event, context):
    """
    Get order details
    
    GET /orders?orderId=xxx
    """
    try:
        # Get orderId from query parameters
        order_id = event.get('queryStringParameters', {}).get('orderId')
        
        if not order_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'orderId query parameter is required'})
            }
        
        # Get order
        response = orders_table.get_item(Key={'orderId': order_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Order not found'})
            }
        
        order = response['Item']
        
        # Convert Decimal to float
        order['totalPrice'] = float(order.get('totalPrice', 0))
        order['discountAmount'] = float(order.get('discountAmount', 0))
        
        for item in order.get('items', []):
            item['pricePerNight'] = float(item.get('pricePerNight', 0))
            item['totalPrice'] = float(item.get('totalPrice', 0))
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(order, default=str)
        }
        
    except Exception as e:
        print(f"Error getting order: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
