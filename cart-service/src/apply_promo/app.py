"""
Apply Promo Code Lambda Handler

Applies discount code to cart.
"""

import json
import os
import boto3
from decimal import Decimal
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
cart_table = dynamodb.Table(os.environ['CART_TABLE'])
promo_table = dynamodb.Table(os.environ.get('PROMO_TABLE', 'promo-codes'))

def lambda_handler(event, context):
    """
    Apply promo code
    
    POST /cart/{userId}/promo
    Body: {"promoCode": "SUMMER20"}
    """
    try:
        user_id = event['pathParameters']['userId']
        body = json.loads(event['body'])
        promo_code = body['promoCode'].upper()        
        # Validate promo code
        promo_response = promo_table.get_item(Key={'promoCode': promo_code})
        
        if 'Item' not in promo_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Invalid promo code'})
            }
        
        promo = promo_response['Item']
        
        # Check if promo is active
        if not promo.get('active', False):
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Promo code expired'})
            }
        
        discount_percent = Decimal(str(promo.get('discountPercent', 0)))
        
        # Get cart items
        response = cart_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        items = response.get('Items', [])
        
        if not items:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Cart is empty'})
            }
        
        # Calculate discount
        total_price = sum(Decimal(str(item.get('totalPrice', 0))) for item in items)
        discount_amount = total_price * (discount_percent / 100)
        final_price = total_price - discount_amount
        
        xray_recorder.put_metadata('discount_amount', str(discount_amount))
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'message': 'Promo code applied',
                'promoCode': promo_code,
                'discountPercent': float(discount_percent),
                'originalPrice': float(total_price),
                'discountAmount': float(discount_amount),
                'finalPrice': float(final_price)
            })
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    
    except Exception as e:
        print(f"Error applying promo: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
