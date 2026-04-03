"""
List User Orders Lambda Handler

Retrieves all orders for a user.
"""

import json
import os
import boto3
from boto3.dynamodb.conditions import Key
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])


@xray_recorder.capture('list_user_orders')
def lambda_handler(event, context):
    """
    List user's orders
    
    GET /orders/user/{userId}
    Query params: ?status=confirmed&limit=10
    """
    try:
        user_id = event['pathParameters']['userId']
        params = event.get('queryStringParameters') or {}
        
        status_filter = params.get('status')
        limit = int(params.get('limit', 50))
        
        xray_recorder.put_annotation('user_id', user_id)
        
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
        
        xray_recorder.put_metadata('orders_count', len(orders))
        
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
        xray_recorder.put_annotation('error', True)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
