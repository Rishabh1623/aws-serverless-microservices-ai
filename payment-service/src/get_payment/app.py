import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['PAYMENT_TABLE'])

def lambda_handler(event, context):
    """Get payment details by ID"""
    try:
        payment_id = event['pathParameters']['paymentId']
        
        if not payment_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'paymentId is required'})
            }
        
        # Get payment from DynamoDB
        response = table.get_item(Key={'paymentId': payment_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Payment not found'})
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'payment': response['Item']
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except Exception as e:
        print(f"Error retrieving payment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
