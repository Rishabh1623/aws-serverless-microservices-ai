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
        
        # Get order from DynamoDB
        response = table.get_item(Key={'orderId': order_id})
        
        if 'Item' not in response:
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
                'order': response['Item']
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
