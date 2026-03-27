"""
Get Hotel Details Lambda Handler

Retrieve detailed information about a specific hotel.
"""

import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['HOTEL_TABLE'])


def lambda_handler(event, context):
    """Get hotel details by ID"""
    try:
        hotel_id = event['pathParameters']['hotelId']
        
        response = table.get_item(Key={'hotelId': hotel_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Hotel not found'})
            }
        
        hotel = response['Item']
        
        # Get available rooms for this hotel
        rooms_table = dynamodb.Table(os.environ.get('ROOM_TABLE', 'rooms'))
        rooms_response = rooms_table.query(
            IndexName='HotelIdIndex',
            KeyConditionExpression='hotelId = :hid',
            ExpressionAttributeValues={':hid': hotel_id}
        )
        
        hotel['availableRooms'] = rooms_response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(hotel, default=str)
        }
        
    except KeyError:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'hotelId is required'})
        }
    except Exception as e:
        print(f"Error getting hotel: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
