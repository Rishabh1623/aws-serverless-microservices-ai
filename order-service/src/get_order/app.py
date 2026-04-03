"""
Get Order Lambda Handler

Retrieves order details by order ID.
"""

import json
import os
import boto3
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])


@xray_recorder.capture('get_order')
def lambda_handler(event, context):
    """
    Get order details
    
    GET /orders/{orderId}
    """
    try:
        order_id = event['pathParameters']['orderId']
        
        xray_recorder.put_annotation('order_id', order_id)
        
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
        xray_recorder.put_annotation('error', True)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
