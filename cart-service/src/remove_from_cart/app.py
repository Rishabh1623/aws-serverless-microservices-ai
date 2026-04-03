"""
Remove from Cart Lambda Handler

Removes item from user's cart.
"""

import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
cart_table = dynamodb.Table(os.environ['CART_TABLE'])

def lambda_handler(event, context):
    """
    Remove item from cart
    
    DELETE /cart/{userId}/{cartItemId}
    """
    try:
        user_id = event['pathParameters']['userId']
        cart_item_id = event['pathParameters']['cartItemId']        
        # Delete item
        cart_table.delete_item(
            Key={'cartItemId': cart_item_id}
        )
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'message': 'Item removed from cart',
                'cartItemId': cart_item_id
            })
        }
        
    except Exception as e:
        print(f"Error removing from cart: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
