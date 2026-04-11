"""
Hotel Booking Orchestrator - Lambda Durable Function

Orchestrates the complete hotel booking workflow using AWS Lambda Durable Functions.
Replaces EventBridge-based orchestration with a single durable execution.

Workflow:
1. Validate booking request
2. Check room availability
3. Create booking with transaction
4. Process payment (with retries)
5. Send confirmation email
6. Handle failures with automatic rollback

Benefits over EventBridge approach:
- Single execution context with automatic state management
- Built-in retry logic for each step
- Automatic checkpointing and replay on failures
- No separate orchestration service needed
- Pay only for active execution time during waits
"""

import json
import os
import sys
import boto3
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, Any

# Add shared libraries to path
sys.path.append('/opt/python')
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'shared', 'python'))

# Import AWS Lambda Durable Execution SDK
try:
    from aws_lambda_durable import durable_handler, DurableContext
except ImportError:
    print("Warning: aws_lambda_durable not installed. Install with: pip install aws-lambda-durable")
    # Fallback for local testing
    def durable_handler(func):
        return func
    class DurableContext:
        pass

from dynamodb_transactions import (
    create_booking_with_transaction,
    TransactionError,
    check_idempotency,
    store_idempotency_result
)

# AWS clients
dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses')
cloudwatch = boto3.client('cloudwatch')

# Environment variables
bookings_table = dynamodb.Table(os.environ['BOOKING_TABLE'])
rooms_table = dynamodb.Table(os.environ.get('ROOM_TABLE', 'rooms'))
hotels_table = dynamodb.Table(os.environ.get('HOTEL_TABLE', 'hotels'))
idempotency_table = os.environ.get('IDEMPOTENCY_TABLE', 'idempotency-keys')
from_email = os.environ.get('FROM_EMAIL', 'bookings@example.com')
template_name = os.environ.get('TEMPLATE_NAME', 'booking-confirmation-dev')


@durable_handler
def lambda_handler(event: Dict[str, Any], context: Any, durable_context: DurableContext):
    """
    Durable function handler for hotel booking orchestration
    
    Request body:
    {
        "userId": "user123",
        "hotelId": "hotel-001",
        "roomId": "room-001",
        "checkIn": "2024-06-15",
        "checkOut": "2024-06-20",
        "guests": 2,
        "idempotencyKey": "unique-request-id",
        "specialRequests": "Late check-in",
        "guestDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890"
        },
        "paymentMethod": {
            "type": "credit_card",
            "token": "tok_visa"
        }
    }
    """
    start_time = datetime.now()
    
    try:
        body = json.loads(event['body'])
        
        # Step 1: Validate and extract booking data
        booking_request = durable_context.step(
            'validate_booking_request',
            validate_booking_request,
            body
        )
        
        # Step 2: Check room availability
        is_available = durable_context.step(
            'check_room_availability',
            check_room_availability,
            booking_request['roomId'],
            booking_request['checkIn'],
            booking_request['checkOut']
        )
        
        if not is_available:
            return create_response(409, {'error': 'Room not available for selected dates'})
        
        # Step 3: Get room details and calculate pricing
        room_details = durable_context.step(
            'get_room_details',
            get_room_details,
            booking_request['roomId']
        )
        
        total_price = calculate_total_price(
            room_details['basePrice'],
            booking_request['checkIn'],
            booking_request['checkOut']
        )
        
        # Step 4: Create booking with DynamoDB transaction (atomic)
        booking_result = durable_context.step(
            'create_booking_transaction',
            create_booking_step,
            booking_request,
            room_details,
            total_price,
            max_retries=3  # Retry up to 3 times on failure
        )
        
        booking_id = booking_result['bookingId']
        
        # Step 5: Process payment with retries
        # This step has built-in retry logic via durable context
        payment_result = durable_context.step(
            'process_payment',
            process_payment_step,
            booking_id,
            total_price,
            booking_request.get('paymentMethod', {}),
            max_retries=3,
            retry_delay_seconds=5
        )
        
        if not payment_result['success']:
            # Payment failed - rollback booking
            durable_context.step(
                'rollback_booking',
                rollback_booking_step,
                booking_id,
                booking_request['roomId']
            )
            return create_response(402, {'error': 'Payment failed', 'details': payment_result})
        
        # Step 6: Update booking status to confirmed
        durable_context.step(
            'confirm_booking',
            confirm_booking_step,
            booking_id,
            payment_result['transactionId']
        )
        
        # Step 7: Send confirmation email (non-blocking, best effort)
        durable_context.step(
            'send_confirmation_email',
            send_confirmation_email_step,
            booking_id,
            booking_request,
            room_details,
            total_price,
            max_retries=2  # Retry email sending twice
        )
        
        # Optional: Wait for check-in date and send reminder
        # This demonstrates long-running capabilities
        if booking_request.get('sendReminder', False):
            check_in_date = datetime.strptime(booking_request['checkIn'], '%Y-%m-%d')
            reminder_date = check_in_date - timedelta(days=1)
            
            if reminder_date > datetime.now():
                # Wait until reminder date (no compute charges during wait)
                durable_context.wait_until(reminder_date)
                
                # Send reminder email
                durable_context.step(
                    'send_reminder_email',
                    send_reminder_email_step,
                    booking_id,
                    booking_request['guestDetails']['email']
                )
        
        # Publish success metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_booking_metrics('BookingOrchestrator', duration, float(total_price), success=True)
        
        # Return success response
        return create_response(201, {
            'message': 'Booking created successfully',
            'bookingId': booking_id,
            'status': 'confirmed',
            'totalPrice': str(total_price),
            'paymentTransactionId': payment_result['transactionId'],
            'createdAt': booking_result['createdAt']
        })
        
    except TransactionError as e:
        publish_booking_metrics('BookingOrchestrator', 0, 0, success=False)
        return create_response(409, {'error': str(e)})
    
    except KeyError as e:
        publish_booking_metrics('BookingOrchestrator', 0, 0, success=False)
        return create_response(400, {'error': f'Missing required field: {str(e)}'})
    
    except Exception as e:
        print(f"Error in booking orchestration: {str(e)}")
        import traceback
        traceback.print_exc()
        
        publish_booking_metrics('BookingOrchestrator', 0, 0, success=False)
        return create_response(500, {'error': 'Internal server error'})


# ============================================================================
# Durable Function Steps
# Each step is a discrete unit of work with automatic checkpointing
# ============================================================================

def validate_booking_request(body: Dict[str, Any]) -> Dict[str, Any]:
    """Step 1: Validate booking request and check idempotency"""
    required_fields = ['userId', 'hotelId', 'roomId', 'checkIn', 'checkOut', 'guests', 'guestDetails']
    
    for field in required_fields:
        if field not in body:
            raise KeyError(field)
    
    # Check idempotency
    idempotency_key = body.get('idempotencyKey') or f"{body['userId']}-{body['roomId']}-{body['checkIn']}"
    existing_response = check_idempotency(idempotency_key, idempotency_table)
    
    if existing_response:
        raise ValueError(f"Duplicate request: {idempotency_key}")
    
    return {
        'userId': body['userId'],
        'hotelId': body['hotelId'],
        'roomId': body['roomId'],
        'checkIn': body['checkIn'],
        'checkOut': body['checkOut'],
        'guests': body['guests'],
        'specialRequests': body.get('specialRequests', ''),
        'guestDetails': body['guestDetails'],
        'idempotencyKey': idempotency_key
    }


def check_room_availability(room_id: str, check_in: str, check_out: str) -> bool:
    """Step 2: Check if room is available for the requested dates"""
    try:
        response = bookings_table.query(
            IndexName='RoomIdIndex',
            KeyConditionExpression='roomId = :rid',
            FilterExpression='#status IN (:confirmed, :pending)',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':rid': room_id,
                ':confirmed': 'confirmed',
                ':pending': 'pending'
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
                return False
        
        return True
        
    except Exception as e:
        print(f"Error checking availability: {str(e)}")
        raise


def get_room_details(room_id: str) -> Dict[str, Any]:
    """Step 3: Get room details including pricing"""
    response = rooms_table.get_item(Key={'roomId': room_id})
    
    if 'Item' not in response:
        raise ValueError(f"Room not found: {room_id}")
    
    room = response['Item']
    return {
        'roomId': room_id,
        'roomType': room.get('roomType', 'Standard'),
        'basePrice': float(room.get('basePrice', 100)),
        'capacity': int(room.get('capacity', 2))
    }


def create_booking_step(
    booking_request: Dict[str, Any],
    room_details: Dict[str, Any],
    total_price: Decimal
) -> Dict[str, Any]:
    """Step 4: Create booking with DynamoDB transaction"""
    booking_data = {
        'userId': booking_request['userId'],
        'hotelId': booking_request['hotelId'],
        'roomId': booking_request['roomId'],
        'checkIn': booking_request['checkIn'],
        'checkOut': booking_request['checkOut'],
        'guests': booking_request['guests'],
        'totalPrice': total_price,
        'specialRequests': booking_request['specialRequests'],
        'guestDetails': booking_request['guestDetails'],
        'idempotencyKey': booking_request['idempotencyKey'],
        'status': 'pending'  # Will be confirmed after payment
    }
    
    result = create_booking_with_transaction(
        booking_data=booking_data,
        room_data=room_details,
        bookings_table=os.environ['BOOKING_TABLE'],
        rooms_table=os.environ.get('ROOM_TABLE', 'rooms')
    )
    
    return result


def process_payment_step(
    booking_id: str,
    amount: Decimal,
    payment_method: Dict[str, Any]
) -> Dict[str, Any]:
    """Step 5: Process payment (simulated - integrate with real payment gateway)"""
    # In production, integrate with Stripe, PayPal, etc.
    # This is a simplified simulation
    
    print(f"Processing payment for booking {booking_id}: ${amount}")
    
    # Simulate payment processing
    import uuid
    transaction_id = str(uuid.uuid4())
    
    # Simulate occasional failures for testing retry logic
    import random
    if random.random() < 0.1:  # 10% failure rate for testing
        return {
            'success': False,
            'error': 'Payment gateway timeout',
            'transactionId': None
        }
    
    return {
        'success': True,
        'transactionId': transaction_id,
        'amount': str(amount),
        'timestamp': datetime.now().isoformat()
    }


def confirm_booking_step(booking_id: str, transaction_id: str):
    """Step 6: Update booking status to confirmed after successful payment"""
    bookings_table.update_item(
        Key={'bookingId': booking_id},
        UpdateExpression='SET #status = :status, paymentTransactionId = :txn, confirmedAt = :time',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'confirmed',
            ':txn': transaction_id,
            ':time': datetime.now().isoformat()
        }
    )
    print(f"Booking {booking_id} confirmed with transaction {transaction_id}")


def rollback_booking_step(booking_id: str, room_id: str):
    """Rollback: Cancel booking and restore room availability"""
    print(f"Rolling back booking {booking_id}")
    
    # Update booking status to cancelled
    bookings_table.update_item(
        Key={'bookingId': booking_id},
        UpdateExpression='SET #status = :status, cancelledAt = :time',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'cancelled',
            ':time': datetime.now().isoformat()
        }
    )
    
    # Restore room availability (increment available count)
    rooms_table.update_item(
        Key={'roomId': room_id},
        UpdateExpression='SET availableRooms = availableRooms + :inc',
        ExpressionAttributeValues={':inc': 1}
    )


def send_confirmation_email_step(
    booking_id: str,
    booking_request: Dict[str, Any],
    room_details: Dict[str, Any],
    total_price: Decimal
):
    """Step 7: Send booking confirmation email"""
    guest_email = booking_request['guestDetails'].get('email')
    
    if not guest_email:
        print(f"No email for booking {booking_id}, skipping notification")
        return
    
    # Get hotel details
    hotel_response = hotels_table.get_item(Key={'hotelId': booking_request['hotelId']})
    hotel = hotel_response.get('Item', {})
    hotel_name = hotel.get('name', 'Hotel')
    
    guest_name = booking_request['guestDetails'].get('name', 'Guest')
    
    # Send templated email via SES
    response = ses.send_templated_email(
        Source=from_email,
        Destination={'ToAddresses': [guest_email]},
        Template=template_name,
        TemplateData=json.dumps({
            'guestName': guest_name,
            'bookingId': booking_id,
            'hotelName': hotel_name,
            'roomType': room_details['roomType'],
            'checkIn': booking_request['checkIn'],
            'checkOut': booking_request['checkOut'],
            'guests': str(booking_request['guests']),
            'totalPrice': str(total_price)
        })
    )
    
    print(f"Sent confirmation email to {guest_email}, MessageId: {response['MessageId']}")


def send_reminder_email_step(booking_id: str, guest_email: str):
    """Send check-in reminder email (demonstrates long-running capability)"""
    print(f"Sending reminder email for booking {booking_id} to {guest_email}")
    
    # Send reminder email
    ses.send_email(
        Source=from_email,
        Destination={'ToAddresses': [guest_email]},
        Message={
            'Subject': {'Data': 'Check-in Reminder - Tomorrow!'},
            'Body': {
                'Text': {
                    'Data': f'Your check-in is tomorrow! Booking ID: {booking_id}'
                }
            }
        }
    )


# ============================================================================
# Helper Functions
# ============================================================================

def calculate_total_price(base_price: float, check_in: str, check_out: str) -> Decimal:
    """Calculate total price based on number of nights"""
    from datetime import datetime as dt
    check_in_date = dt.strptime(check_in, '%Y-%m-%d')
    check_out_date = dt.strptime(check_out, '%Y-%m-%d')
    nights = (check_out_date - check_in_date).days
    
    if nights <= 0:
        raise ValueError('Invalid dates: check-out must be after check-in')
    
    return Decimal(str(base_price * nights))


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create API Gateway response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }


def publish_booking_metrics(operation: str, duration: float, revenue: float, success: bool = True):
    """Publish CloudWatch metrics"""
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
