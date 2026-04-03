"""
Get Cart Lambda Handler

Retrieves user's cart with all items and total price.
"""

import json
import os
import boto3
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
cart_table = dynamodb.Table(os.environ['CART_TABLE'])


@xray_recorder.capture('get_cart')
def lambda_handler(event, context):
    """
    Get user's cart
    
    Path: /cart/{userId}
    """
    try:
        user_id = event['pathParameters']['userId']
        
        xray_recorder.put_annotation('user_id', user_id)
        
        # Query cart items for user
        response = cart_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        items = response.get('Items', [])
        
        # Calculate totals
        total_price = sum(Decimal(str(item.get('totalPrice', 0))) for item in items)
        total_nights = sum(item.get('nights', 0) for item in items)
        
        # Convert Decimal to float for JSON
        for item in items:
            item['pricePerNight'] = float(item.get('pricePerNight', 0))
            item['totalPrice'] = float(item.get('totalPrice', 0))
        
        xray_recorder.put_metadata('items_count', len(items))
        xray_recorder.put_metadata('total_price', str(total_price))
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'userId': user_id,
                'items': items,
                'itemCount': len(items),
                'totalNights': total_nights,
                'totalPrice': float(total_price),
                'currency': 'USD'
            }, default=str)
        }
        
    except Exception as e:
        print(f"Error getting cart: {str(e)}")
        xray_recorder.put_annotation('error', True)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
