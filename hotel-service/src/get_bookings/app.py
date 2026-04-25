"""
Get Bookings Lambda Handler

Retrieve user bookings from DynamoDB with hotel and room details.
"""

import json
import os
import boto3
from boto3.dynamodb.conditions import Key
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
booking_table = dynamodb.Table(os.environ['BOOKING_TABLE'])
hotel_table = dynamodb.Table(os.environ['HOTEL_TABLE'])
room_table = dynamodb.Table(os.environ['ROOM_TABLE'])

def lambda_handler(event, context):
    """
    Get bookings for a user with enriched hotel/room data
    
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
        
        # Enrich bookings with hotel and room details
        enriched_bookings = []
        for booking in bookings:
            enriched = enrich_booking(booking)
            enriched_bookings.append(enriched)
        
        # Sort by creation date (newest first)
        enriched_bookings.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'bookings': enriched_bookings,
                'count': len(enriched_bookings)
            }, default=decimal_default)
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

def enrich_booking(booking):
    """Enrich booking with hotel and room details"""
    try:
        hotel_id = booking.get('hotelId')
        room_id = booking.get('roomId')
        
        # Fetch hotel details
        hotel_name = 'Hotel'
        if hotel_id:
            try:
                hotel_response = hotel_table.get_item(Key={'hotelId': hotel_id})
                if 'Item' in hotel_response:
                    hotel_name = hotel_response['Item'].get('name', 'Hotel')
            except Exception as e:
                print(f"Error fetching hotel {hotel_id}: {str(e)}")
        
        # Fetch room details
        room_type = 'Room'
        if room_id:
            try:
                room_response = room_table.get_item(Key={'roomId': room_id})
                if 'Item' in room_response:
                    room_type = room_response['Item'].get('roomType', 'Room')
            except Exception as e:
                print(f"Error fetching room {room_id}: {str(e)}")
        
        # Calculate nights
        nights = calculate_nights(booking.get('checkIn'), booking.get('checkOut'))
        
        # Add enriched fields
        booking['hotelName'] = hotel_name
        booking['roomType'] = room_type
        booking['nights'] = nights
        
        return booking
        
    except Exception as e:
        print(f"Error enriching booking: {str(e)}")
        return booking

def calculate_nights(check_in, check_out):
    """Calculate number of nights between check-in and check-out"""
    try:
        if not check_in or not check_out:
            return 1
        start = datetime.strptime(check_in, '%Y-%m-%d')
        end = datetime.strptime(check_out, '%Y-%m-%d')
        nights = (end - start).days
        return max(nights, 1)
    except:
        return 1

def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError
