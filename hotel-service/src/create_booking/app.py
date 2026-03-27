"""
Create Booking Lambda Handler

Create hotel reservation with availability check.
"""

import json
import os
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
bookings_table = dynamodb.Table(os.environ['BOOKING_TABLE'])
rooms_table = dynamodb.Table(os.environ.get('ROOM_TABLE', 'rooms'))


def lambda_handler(event, context):
    """
    Create hotel booking
    
    Body:
    {
        "userId": "user123",
        "hotelId": "hotel-001",
        "roomId": "room-001",
        "checkIn": "2024-06-15",
        "checkOut": "2024-06-20",
        "guests": 2,
        "specialRequests": "Late check-in",
        "guestDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890"
        }
    }
    """
    try:
        body = json.loads(event['body'])
        
        user_id = body['userId']
        hotel_id = body['hotelId']
        room_id = body['roomId']
        check_in = body['checkIn']
        check_out = body['checkOut']
        guests = body['guests']
        special_requests = body.get('specialRequests', '')
        guest_details = body.get('guestDetails', {})
        
        # Check room availability
        if not check_availability(room_id, check_in, check_out):
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Room not available for selected dates'})
            }
        
        # Get room details for pricing
        room_response = rooms_table.get_item(Key={'roomId': room_id})
        if 'Item' not in room_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Room not found'})
            }
        
        room = room_response['Item']
        
        # Calculate total price
        from datetime import datetime as dt
        check_in_date = dt.strptime(check_in, '%Y-%m-%d')
        check_out_date = dt.strptime(check_out, '%Y-%m-%d')
        nights = (check_out_date - check_in_date).days
        
        base_price = float(room.get('basePrice', 100))
        total_price = Decimal(str(base_price * nights))
        
        # Create booking
        booking_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        booking = {
            'bookingId': booking_id,
            'userId': user_id,
            'hotelId': hotel_id,
            'roomId': room_id,
            'checkIn': check_in,
            'checkOut': check_out,
            'guests': guests,
            'totalPrice': total_price,
            'status': 'confirmed',
            'specialRequests': special_requests,
            'guestDetails': guest_details,
            'paymentStatus': 'pending',
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        bookings_table.put_item(Item=booking)
        
        # Send confirmation email (would integrate with SES)
        # send_booking_confirmation(guest_details.get('email'), booking)
        
        return {
            'statusCode': 201,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'message': 'Booking created successfully',
                'booking': booking
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    except Exception as e:
        print(f"Error creating booking: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }


def check_availability(room_id: str, check_in: str, check_out: str) -> bool:
    """Check if room is available for dates"""
    try:
        # Query existing bookings for this room
        response = bookings_table.query(
            IndexName='RoomIdIndex',
            KeyConditionExpression='roomId = :rid',
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':rid': room_id,
                ':status': 'confirmed'
            }
        )
        
        bookings = response.get('Items', [])
        
        # Check for date conflicts
        from datetime import datetime as dt
        new_check_in = dt.strptime(check_in, '%Y-%m-%d')
        new_check_out = dt.strptime(check_out, '%Y-%m-%d')
        
        for booking in bookings:
            existing_check_in = dt.strptime(booking['checkIn'], '%Y-%m-%d')
            existing_check_out = dt.strptime(booking['checkOut'], '%Y-%m-%d')
            
            # Check for overlap
            if not (new_check_out <= existing_check_in or new_check_in >= existing_check_out):
                return False  # Conflict found
        
        return True  # No conflicts
        
    except Exception as e:
        print(f"Error checking availability: {str(e)}")
        return False
