"""
Get Payment Lambda Handler

Retrieves payment details and status.
"""

import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])

def lambda_handler(event, context):
    """
    Get payment details
    
    GET /payments/{paymentId}
    """
    try:
        # Get paymentId from query parameters
        payment_id = event.get('queryStringParameters', {}).get('paymentId')
        
        if not payment_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'paymentId query parameter is required'})
            }
        
        response = payments_table.get_item(Key={'paymentId': payment_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Payment not found'})
            }
        
        payment = response['Item']
        
        # Convert Decimal to float
        if 'amount' in payment:
            payment['amount'] = float(payment['amount'])
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(payment, default=str)
        }
        
    except Exception as e:
        print(f"Error getting payment: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
