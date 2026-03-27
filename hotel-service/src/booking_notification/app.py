"""
Booking Notification Lambda Handler

Processes booking events from EventBridge and sends confirmation emails via SES.
"""

import json
import os
import boto3
from datetime import datetime

ses = boto3.client('ses')
dynamodb = boto3.resource('dynamodb')

hotels_table = dynamodb.Table(os.environ['HOTEL_TABLE'])
bookings_table = dynamodb.Table(os.environ['BOOKING_TABLE'])
configuration_set = os.environ.get('SES_CONFIGURATION_SET', 'travel-platform-dev')
from_email = os.environ.get('FROM_EMAIL', 'bookings@example.com')
template_name = os.environ.get('TEMPLATE_NAME', 'booking-confirmation-dev')


def lambda_handler(event, context):
    """
    Process booking created events and send confirmation emails
    
    Event structure:
    {
        "detail": {
            "bookingId": "...",
            "userId": "...",
            "hotelId": "...",
            "roomId": "...",
            "checkIn": "2024-06-15",
            "checkOut": "2024-06-20",
            "totalPrice": "600.00",
            "guestEmail": "guest@example.com"
        }
    }
    """
    try:
        detail = event.get('detail', {})
        
        booking_id = detail['bookingId']
        hotel_id = detail['hotelId']
        guest_email = detail.get('guestEmail')
        
        if not guest_email:
            print(f"No guest email for booking {booking_id}, skipping notification")
            return {'statusCode': 200, 'body': 'No email provided'}
        
        # Get hotel details
        hotel_response = hotels_table.get_item(Key={'hotelId': hotel_id})
        hotel = hotel_response.get('Item', {})
        hotel_name = hotel.get('name', 'Hotel')
        
        # Get full booking details
        booking_response = bookings_table.get_item(Key={'bookingId': booking_id})
        booking = booking_response.get('Item', {})
        
        guest_name = booking.get('guestDetails', {}).get('name', 'Guest')
        room_type = booking.get('roomType', 'Standard Room')
        
        # Send templated email
        response = ses.send_templated_email(
            Source=from_email,
            Destination={
                'ToAddresses': [guest_email]
            },
            Template=template_name,
            TemplateData=json.dumps({
                'guestName': guest_name,
                'bookingId': booking_id,
                'hotelName': hotel_name,
                'roomType': room_type,
                'checkIn': detail['checkIn'],
                'checkOut': detail['checkOut'],
                'guests': str(booking.get('guests', 2)),
                'totalPrice': detail['totalPrice']
            }),
            ConfigurationSetName=configuration_set
        )
        
        print(f"Sent booking confirmation to {guest_email}, MessageId: {response['MessageId']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notification sent',
                'messageId': response['MessageId']
            })
        }
        
    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Don't fail - just log the error
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
