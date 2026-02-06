import json
import os
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CART_TABLE'])

def lambda_handler(event, context):
    """Remove item from shopping cart"""
    try:
        body = json.loads(event['body'])
        user_id = body['userId']
        product_id = body['productId']
        
        # Validate input
        if not user_id or not product_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId and productId are required'})
            }
        
        # Remove item from cart
        table.delete_item(
            Key={
                'userId': user_id,
                'productId': product_id
            }
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Item removed from cart',
                'userId': user_id,
                'productId': product_id
            })
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to remove item from cart'})
        }
    except Exception as e:
        print(f"Error removing from cart: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
