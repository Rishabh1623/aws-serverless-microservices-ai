"""
Get Bookings Lambda Handler

Retrieve user bookings from DynamoDB.
"""

import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
booking_table = dynamodb.Table(os.environ['BOOKING_TABLE'])

def lambda_handler(event, context):
    """
    Get bookings for a user
    
    Query Parameters:
    - userId: User ID (required)
    """
    try:
        params = event.get('queryStringParameters') or {}
        user_id = params.get('userId')
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # Query bookings by userId using GSI
        response = booking_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id)
        )
        
        bookings = response.get('Items', [])
        
        # Sort by creation date (newest first)
        bookings.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'bookings': bookings,
                'count': len(bookings)
            }, default=str)
        }
        
    except Exception as e:
        print(f"Error fetching bookings: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
