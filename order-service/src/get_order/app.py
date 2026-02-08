import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['ORDER_TABLE'])

def lambda_handler(event, context):
    """Get order details by ID"""
    try:
        order_id = event['pathParameters']['orderId']
        
        if not order_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'orderId is required'})
            }
        
        # Since we have a composite key (orderId + userId), we need to scan
        # In production, consider adding orderId as a GSI for efficient lookups
        response = table.scan(
            FilterExpression='orderId = :orderId',
            ExpressionAttributeValues={':orderId': order_id}
        )
        
        items = response.get('Items', [])
        
        if not items:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Order not found'})
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'order': items[0]
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except Exception as e:
        print(f"Error retrieving order: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
