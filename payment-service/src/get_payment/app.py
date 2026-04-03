"""
Get Payment Lambda Handler

Retrieves payment details and status.
"""

import json
import os
import boto3
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])


@xray_recorder.capture('get_payment')
def lambda_handler(event, context):
    """
    Get payment details
    
    GET /payments/{paymentId}
    """
    try:
        payment_id = event['pathParameters']['paymentId']
        
        xray_recorder.put_annotation('payment_id', payment_id)
        
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
        xray_recorder.put_annotation('error', True)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
