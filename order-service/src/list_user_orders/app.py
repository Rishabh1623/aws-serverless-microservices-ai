"""
List User Orders Lambda Handler

Retrieves all orders for a user.
"""

import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])

def lambda_handler(event, context):
    """
    List user's orders or get single order
    
    GET /orders?userId=xxx&status=confirmed&limit=10  (list orders)
    GET /orders?orderId=xxx  (get single order)
    """
    try:
        params = event.get('queryStringParameters') or {}
        
        # Check if requesting single order
        order_id = params.get('orderId')
        if order_id:
            return get_single_order(order_id)
        
        # Otherwise list user orders
        user_id = params.get('userId')
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'userId or orderId query parameter is required'})
            }
        
        status_filter = params.get('status')
        limit = int(params.get('limit', 50))        
        # Query orders
        query_params = {
            'IndexName': 'UserIdIndex',
            'KeyConditionExpression': Key('userId').eq(user_id),
            'Limit': limit,
            'ScanIndexForward': False  # Most recent first
        }
        
        if status_filter:
            query_params['FilterExpression'] = '#status = :status'
            query_params['ExpressionAttributeNames'] = {'#status': 'status'}
            query_params['ExpressionAttributeValues'] = {':status': status_filter}
        
        response = orders_table.query(**query_params)
        orders = response.get('Items', [])
        
        # Convert Decimal to float
        for order in orders:
            order['totalPrice'] = float(order.get('totalPrice', 0))
            order['discountAmount'] = float(order.get('discountAmount', 0))
            
            for item in order.get('items', []):
                item['pricePerNight'] = float(item.get('pricePerNight', 0))
                item['totalPrice'] = float(item.get('totalPrice', 0))
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'userId': user_id,
                'orders': orders,
                'count': len(orders)
            }, default=str)
        }
        
    except Exception as e:
        print(f"Error listing orders: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }

def get_single_order(order_id):
    """Get a single order by ID"""
    try:
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
