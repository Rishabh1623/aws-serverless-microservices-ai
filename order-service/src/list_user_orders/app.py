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
    List user's orders
    
    GET /orders?userId=xxx&status=confirmed&limit=10
    """
    try:
        params = event.get('queryStringParameters') or {}
        user_id = params.get('userId')
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'userId query parameter is required'})
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
