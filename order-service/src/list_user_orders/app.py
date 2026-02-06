import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['ORDER_TABLE'])

def lambda_handler(event, context):
    """List orders for a user"""
    try:
        user_id = event['pathParameters']['userId']
        
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Query orders by userId using GSI
        response = table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id),
            ScanIndexForward=False  # Sort by createdAt descending
        )
        
        orders = response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'orders': orders,
                'count': len(orders)
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except Exception as e:
        print(f"Error listing orders: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
