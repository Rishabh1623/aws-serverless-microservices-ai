import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CART_TABLE'])

def lambda_handler(event, context):
    """Retrieve shopping cart contents for a user"""
    try:
        user_id = event['pathParameters']['userId']
        
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Query all items for this user
        response = table.query(
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        
        items = response.get('Items', [])
        total_items = sum(item.get('quantity', 0) for item in items)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'userId': user_id,
                'items': items,
                'totalItems': total_items,
                'itemCount': len(items)
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except Exception as e:
        print(f"Error retrieving cart: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
