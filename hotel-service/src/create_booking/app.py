"""
Create Booking Lambda Handler

Create hotel reservation with availability check using DynamoDB transactions.
Prevents double-booking and ensures data consistency.
"""

import json
import os
import sys
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

# Add shared libraries to path
sys.path.append('/opt/python')  # Lambda layer path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'shared', 'python'))

from dynamodb_transactions import (
    create_booking_with_transaction,
    TransactionError,
    check_idempotency,
    store_idempotency_result
)

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')
cloudwatch = boto3.client('cloudwatch')
bookings_table = dynamodb.Table(os.environ['BOOKING_TABLE'])
rooms_table = dynamodb.Table(os.environ.get('ROOM_TABLE', 'rooms'))
idempotency_table = os.environ.get('IDEMPOTENCY_TABLE', 'idempotency-keys')
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')

def lambda_handler(event, context):
    """
    Create hotel booking with DynamoDB transactions
    
    Supports two invocation modes:
    1. API Gateway (HTTP request with 'body' field)
    2. Step Functions workflow (direct invocation with 'action' field)
    
    Workflow Actions:
    - validate: Validate booking request
    - create: Create booking record
    - payment: Process payment
    - rollback: Cancel booking
    
    API Gateway Body:
    {
        "userId": "user123",
        "hotelId": "hotel-001",
        "roomId": "room-001",
        "checkIn": "2024-06-15",
        "checkOut": "2024-06-20",
        "guests": 2,
        "idempotencyKey": "unique-request-id",  # Optional
        "specialRequests": "Late check-in",
        "guestDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890"
        }
    }
    """
    start_time = datetime.now()
    
    try:
        # Check if this is a Step Functions workflow action
        if 'action' in event:
            return handle_workflow_action(event, context)
        
        # Otherwise, handle as API Gateway request
        body = json.loads(event['body'])
        
        # Extract fields
        user_id = body['userId']
        hotel_id = body['hotelId']
        room_id = body['roomId']
        check_in = body['checkIn']
        check_out = body['checkOut']
        guests = body['guests']
        special_requests = body.get('specialRequests', '')
        guest_details = body.get('guestDetails', {})
        
        # Idempotency key (prevents duplicate requests)
        idempotency_key = body.get('idempotencyKey') or f"{user_id}-{room_id}-{check_in}"
        
        # Check if request already processed
        existing_response = check_idempotency(idempotency_key, idempotency_table)
        if existing_response:
            print(f"Duplicate request detected: {idempotency_key}")
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': existing_response
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
        
        if nights <= 0:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Invalid dates: check-out must be after check-in'})
            }
        
        base_price = float(room.get('basePrice', 100))
        total_price = Decimal(str(base_price * nights))
        
        # Prepare booking data
        booking_data = {
            'userId': user_id,
            'hotelId': hotel_id,
            'roomId': room_id,
            'checkIn': check_in,
            'checkOut': check_out,
            'guests': guests,
            'totalPrice': total_price,
            'specialRequests': special_requests,
            'guestDetails': guest_details,
            'idempotencyKey': idempotency_key
        }
        
        # Create booking with transaction (atomic operation)
        result = create_booking_with_transaction(
            booking_data=booking_data,
            room_data=room,
            bookings_table=os.environ['BOOKING_TABLE'],
            rooms_table=os.environ.get('ROOM_TABLE', 'rooms')
        )
        
        booking_id = result['bookingId']
        
        # Publish event to EventBridge
        try:
            events.put_events(
                Entries=[{
                    'Source': 'travel.bookings',
                    'DetailType': 'Booking Created',
                    'Detail': json.dumps({
                        'bookingId': booking_id,
                        'userId': user_id,
                        'hotelId': hotel_id,
                        'roomId': room_id,
                        'checkIn': check_in,
                        'checkOut': check_out,
                        'totalPrice': str(total_price),
                        'guestEmail': guest_details.get('email'),
                        'event_type': 'booking_created'
                    }),
                    'EventBusName': event_bus_name
                }]
            )
            print(f"Published booking event for {booking_id}")
        except Exception as e:
            print(f"Error publishing event: {str(e)}")
            # Don't fail the request if event publishing fails
        
        # Prepare response
        response_body = json.dumps({
            'message': 'Booking created successfully',
            'bookingId': booking_id,
            'status': 'confirmed',
            'totalPrice': str(total_price),
            'nights': nights,
            'createdAt': result['createdAt']
        })
        
        # Store for idempotency
        store_idempotency_result(idempotency_key, response_body, idempotency_table)
        
        # Publish success metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_booking_metrics('CreateBooking', duration, float(total_price), success=True)
        
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json', 
                'Access-Control-Allow-Origin': '*',
                'X-Response-Time': f'{duration}ms'
            },
            'body': response_body
        }
        
    except TransactionError as e:
        # Transaction failed (room unavailable, etc.)
        print(f"Transaction error: {str(e)}")        publish_booking_metrics('CreateBooking', 0, 0, success=False)
        
        return {
            'statusCode': 409,  # Conflict
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }
    
    except KeyError as e:
        publish_booking_metrics('CreateBooking', 0, 0, success=False)
        
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    
    except Exception as e:
        print(f"Error creating booking: {str(e)}")
        import traceback
        traceback.print_exc()
        
        publish_booking_metrics('CreateBooking', 0, 0, success=False)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }

def publish_booking_metrics(operation: str, duration: float, revenue: float, success: bool = True):
    """Publish business and operational metrics"""
    try:
        metrics = [
            {
                'MetricName': 'Duration',
                'Value': duration,
                'Unit': 'Milliseconds',
                'Dimensions': [{'Name': 'Operation', 'Value': operation}]
            },
            {
                'MetricName': 'BookingCount',
                'Value': 1 if success else 0,
                'Unit': 'Count',
                'Dimensions': [{'Name': 'Operation', 'Value': operation}]
            }
        ]
        
        if success and revenue > 0:
            metrics.append({
                'MetricName': 'Revenue',
                'Value': revenue,
                'Unit': 'None',
                'Dimensions': [{'Name': 'Operation', 'Value': operation}]
            })
        
        if not success:
            metrics.append({
                'MetricName': 'Errors',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [{'Name': 'Operation', 'Value': operation}]
            })
        
        cloudwatch.put_metric_data(
            Namespace='TravelPlatform/HotelService',
            MetricData=metrics
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")

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

def handle_workflow_action(event, context):
    """
    Handle Step Functions workflow actions
    
    Actions:
    - validate: Validate booking request
    - create: Create booking record  
    - payment: Process payment (placeholder)
    - rollback: Cancel booking
    """
    action = event.get('action')
    booking_data = event.get('booking', event)
    
    print(f"Workflow action: {action}")
    print(f"Booking data: {json.dumps(booking_data, default=str)}")
    
    if action == 'validate':
        return validate_booking_request(booking_data)
    elif action == 'create':
        return create_booking_workflow(booking_data)
    elif action == 'payment':
        return process_payment_workflow(booking_data)
    elif action == 'rollback':
        return rollback_booking_workflow(booking_data)
    else:
        raise ValueError(f"Unknown workflow action: {action}")

def validate_booking_request(booking_data):
    """Validate booking request data"""
    try:
        # Required fields
        required_fields = ['hotelId', 'roomId', 'userId', 'checkIn', 'checkOut']
        missing_fields = [f for f in required_fields if f not in booking_data]
        
        if missing_fields:
            raise ValueError(f"Missing required fields: {', '.join(missing_fields)}")
        
        # Validate dates
        from datetime import datetime as dt
        check_in = dt.strptime(booking_data['checkIn'], '%Y-%m-%d')
        check_out = dt.strptime(booking_data['checkOut'], '%Y-%m-%d')
        
        if check_out <= check_in:
            raise ValueError("Check-out date must be after check-in date")
        
        if check_in < dt.now():
            raise ValueError("Check-in date cannot be in the past")
        
        # Check room exists
        room_response = rooms_table.get_item(Key={'roomId': booking_data['roomId']})
        if 'Item' not in room_response:
            raise ValueError(f"Room not found: {booking_data['roomId']}")
        
        return {
            'statusCode': 200,
            'valid': True,
            'message': 'Booking request is valid'
        }
        
    except ValueError as e:
        print(f"Validation error: {str(e)}")
        raise Exception(f"ValidationError: {str(e)}")
    except Exception as e:
        print(f"Validation error: {str(e)}")
        raise Exception(f"ValidationError: {str(e)}")

def create_booking_workflow(booking_data):
    """Create booking for workflow"""
    try:
        # Extract fields
        user_id = booking_data['userId']
        hotel_id = booking_data['hotelId']
        room_id = booking_data['roomId']
        check_in = booking_data['checkIn']
        check_out = booking_data['checkOut']
        guests = booking_data.get('guests', 1)
        special_requests = booking_data.get('specialRequests', '')
        guest_details = booking_data.get('guestDetails', {
            'name': booking_data.get('guestName', 'Guest'),
            'email': booking_data.get('guestEmail', '')
        })
        
        # Get room details for pricing
        room_response = rooms_table.get_item(Key={'roomId': room_id})
        if 'Item' not in room_response:
            raise Exception(f"Room not found: {room_id}")
        
        room = room_response['Item']
        
        # Calculate total price
        from datetime import datetime as dt
        check_in_date = dt.strptime(check_in, '%Y-%m-%d')
        check_out_date = dt.strptime(check_out, '%Y-%m-%d')
        nights = (check_out_date - check_in_date).days
        
        base_price = float(room.get('basePrice', 100))
        total_price = Decimal(str(base_price * nights))
        
        # Prepare booking data
        booking_id = str(uuid.uuid4())
        created_at = datetime.now().isoformat()
        
        booking_item = {
            'bookingId': booking_id,
            'userId': user_id,
            'hotelId': hotel_id,
            'roomId': room_id,
            'checkIn': check_in,
            'checkOut': check_out,
            'guests': guests,
            'totalPrice': total_price,
            'specialRequests': special_requests,
            'guestDetails': guest_details,
            'status': 'pending',
            'createdAt': created_at,
            'updatedAt': created_at
        }
        
        # Store booking
        bookings_table.put_item(Item=booking_item)
        
        print(f"Created booking: {booking_id}")
        
        return {
            'statusCode': 201,
            'bookingId': booking_id,
            'totalPrice': str(total_price),
            'nights': nights,
            'createdAt': created_at
        }
        
    except Exception as e:
        print(f"Error creating booking: {str(e)}")
        raise Exception(f"BookingCreationError: {str(e)}")

def process_payment_workflow(booking_data):
    """Process payment for booking (placeholder)"""
    try:
        booking_id = booking_data.get('bookingResult', {}).get('Payload', {}).get('bookingId')
        
        if not booking_id:
            raise Exception("Booking ID not found in workflow data")
        
        # Update booking status to confirmed
        bookings_table.update_item(
            Key={'bookingId': booking_id},
            UpdateExpression='SET #status = :status, updatedAt = :updated',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'confirmed',
                ':updated': datetime.now().isoformat()
            }
        )
        
        print(f"Payment processed for booking: {booking_id}")
        
        return {
            'statusCode': 200,
            'paymentStatus': 'success',
            'bookingId': booking_id
        }
        
    except Exception as e:
        print(f"Error processing payment: {str(e)}")
        raise Exception(f"PaymentError: {str(e)}")

def rollback_booking_workflow(booking_data):
    """Rollback/cancel booking"""
    try:
        booking_id = booking_data.get('bookingResult', {}).get('Payload', {}).get('bookingId')
        
        if not booking_id:
            print("No booking ID found, nothing to rollback")
            return {'statusCode': 200, 'message': 'Nothing to rollback'}
        
        # Update booking status to cancelled
        bookings_table.update_item(
            Key={'bookingId': booking_id},
            UpdateExpression='SET #status = :status, updatedAt = :updated',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'cancelled',
                ':updated': datetime.now().isoformat()
            }
        )
        
        print(f"Rolled back booking: {booking_id}")
        
        return {
            'statusCode': 200,
            'message': 'Booking rolled back successfully',
            'bookingId': booking_id
        }
        
    except Exception as e:
        print(f"Error rolling back booking: {str(e)}")
        # Don't fail rollback
        return {
            'statusCode': 200,
            'message': f'Rollback completed with errors: {str(e)}'
        }

