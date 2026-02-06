import json
import os
import boto3
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CART_TABLE'])

def lambda_handler(event, context):
    """Add item to shopping cart"""
    try:
        body = json.loads(event['body'])
        user_id = body['userId']
        product_id = body['productId']
        quantity = body.get('quantity', 1)
        
        # Validate input
        if not user_id or not product_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId and productId are required'})
            }
        
        if quantity < 1:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'quantity must be at least 1'})
            }
        
        # Add/update item in cart
        response = table.update_item(
            Key={
                'userId': user_id,
                'productId': product_id
            },
            UpdateExpression='SET quantity = if_not_exists(quantity, :zero) + :qty, updatedAt = :timestamp',
            ExpressionAttributeValues={
                ':qty': quantity,
                ':zero': 0,
                ':timestamp': datetime.utcnow().isoformat()
            },
            ReturnValues='ALL_NEW'
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Item added to cart',
                'item': response['Attributes']
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    except Exception as e:
        print(f"Error adding to cart: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
