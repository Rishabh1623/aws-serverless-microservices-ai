"""
DynamoDB Transactions Helper

Provides atomic operations for booking system to prevent race conditions.
"""

import boto3
import uuid
from typing import Dict, Any, List, Optional
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.client('dynamodb')


class TransactionError(Exception):
    """Custom exception for transaction failures"""
    pass


def create_booking_with_transaction(
    booking_data: Dict[str, Any],
    room_data: Dict[str, Any],
    bookings_table: str,
    rooms_table: str
) -> Dict[str, Any]:
    """
    Create booking atomically with room availability check
    
    Prevents double-booking by using DynamoDB transactions
    
    Args:
        booking_data: Booking information
        room_data: Room information with availability
        bookings_table: Bookings table name
        rooms_table: Rooms table name
        
    Returns:
        Created booking data
        
    Raises:
        TransactionError: If transaction fails (room unavailable, etc.)
    """
    
    booking_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()
    
    # Prepare booking item
    booking_item = {
        'bookingId': {'S': booking_id},
        'userId': {'S': booking_data['userId']},
        'hotelId': {'S': booking_data['hotelId']},
        'roomId': {'S': booking_data['roomId']},
        'checkIn': {'S': booking_data['checkIn']},
        'checkOut': {'S': booking_data['checkOut']},
        'guests': {'N': str(booking_data['guests'])},
        'totalPrice': {'N': str(booking_data['totalPrice'])},
        'status': {'S': 'confirmed'},
        'paymentStatus': {'S': 'pending'},
        'createdAt': {'S': timestamp},
        'updatedAt': {'S': timestamp},
        'idempotencyKey': {'S': booking_data.get('idempotencyKey', booking_id)}
    }
    
    # Add optional fields
    if 'specialRequests' in booking_data:
        booking_item['specialRequests'] = {'S': booking_data['specialRequests']}
    
    if 'guestDetails' in booking_data:
        booking_item['guestDetails'] = {'M': {
            'name': {'S': booking_data['guestDetails'].get('name', '')},
            'email': {'S': booking_data['guestDetails'].get('email', '')},
            'phone': {'S': booking_data['guestDetails'].get('phone', '')}
        }}
    
    try:
        # Execute transaction
        response = dynamodb.transact_write_items(
            TransactItems=[
                {
                    # 1. Create booking
                    'Put': {
                        'TableName': bookings_table,
                        'Item': booking_item,
                        'ConditionExpression': 'attribute_not_exists(bookingId)'
                    }
                },
                {
                    # 2. Update room availability (with condition check)
                    'Update': {
                        'TableName': rooms_table,
                        'Key': {
                            'roomId': {'S': booking_data['roomId']}
                        },
                        'UpdateExpression': 'SET availableRooms = availableRooms - :dec, updatedAt = :timestamp',
                        'ConditionExpression': 'availableRooms > :zero',
                        'ExpressionAttributeValues': {
                            ':dec': {'N': '1'},
                            ':zero': {'N': '0'},
                            ':timestamp': {'S': timestamp}
                        }
                    }
                }
            ],
            # Client request token for idempotency
            ClientRequestToken=booking_data.get('idempotencyKey', booking_id)[:36]
        )
        
        return {
            'bookingId': booking_id,
            'status': 'confirmed',
            'createdAt': timestamp
        }
        
    except dynamodb.exceptions.TransactionCanceledException as e:
        # Transaction failed - check reason
        reasons = e.response.get('CancellationReasons', [])
        
        for reason in reasons:
            if reason.get('Code') == 'ConditionalCheckFailed':
                raise TransactionError('Room not available - already booked')
            elif reason.get('Code') == 'DuplicateItem':
                raise TransactionError('Booking already exists')
        
        raise TransactionError(f'Transaction failed: {str(e)}')
    
    except Exception as e:
        raise TransactionError(f'Unexpected error: {str(e)}')


def cancel_booking_with_transaction(
    booking_id: str,
    room_id: str,
    bookings_table: str,
    rooms_table: str,
    refund_amount: Decimal
) -> Dict[str, Any]:
    """
    Cancel booking atomically and restore room availability
    
    Args:
        booking_id: Booking ID to cancel
        room_id: Room ID to restore
        bookings_table: Bookings table name
        rooms_table: Rooms table name
        refund_amount: Amount to refund
        
    Returns:
        Cancellation confirmation
    """
    
    timestamp = datetime.utcnow().isoformat()
    
    try:
        response = dynamodb.transact_write_items(
            TransactItems=[
                {
                    # 1. Update booking status
                    'Update': {
                        'TableName': bookings_table,
                        'Key': {
                            'bookingId': {'S': booking_id}
                        },
                        'UpdateExpression': 'SET #status = :cancelled, cancelledAt = :timestamp, refundAmount = :refund',
                        'ConditionExpression': '#status = :confirmed',
                        'ExpressionAttributeNames': {
                            '#status': 'status'
                        },
                        'ExpressionAttributeValues': {
                            ':cancelled': {'S': 'cancelled'},
                            ':confirmed': {'S': 'confirmed'},
                            ':timestamp': {'S': timestamp},
                            ':refund': {'N': str(refund_amount)}
                        }
                    }
                },
                {
                    # 2. Restore room availability
                    'Update': {
                        'TableName': rooms_table,
                        'Key': {
                            'roomId': {'S': room_id}
                        },
                        'UpdateExpression': 'SET availableRooms = availableRooms + :inc, updatedAt = :timestamp',
                        'ExpressionAttributeValues': {
                            ':inc': {'N': '1'},
                            ':timestamp': {'S': timestamp}
                        }
                    }
                }
            ]
        )
        
        return {
            'bookingId': booking_id,
            'status': 'cancelled',
            'refundAmount': float(refund_amount),
            'cancelledAt': timestamp
        }
        
    except dynamodb.exceptions.TransactionCanceledException as e:
        reasons = e.response.get('CancellationReasons', [])
        
        for reason in reasons:
            if reason.get('Code') == 'ConditionalCheckFailed':
                raise TransactionError('Booking cannot be cancelled - already cancelled or not found')
        
        raise TransactionError(f'Cancellation failed: {str(e)}')


def update_booking_with_optimistic_locking(
    booking_id: str,
    updates: Dict[str, Any],
    expected_version: int,
    bookings_table: str
) -> Dict[str, Any]:
    """
    Update booking with optimistic locking to prevent concurrent modifications
    
    Args:
        booking_id: Booking ID
        updates: Fields to update
        expected_version: Expected version number
        bookings_table: Bookings table name
        
    Returns:
        Updated booking data
        
    Raises:
        TransactionError: If version mismatch (concurrent modification detected)
    """
    
    timestamp = datetime.utcnow().isoformat()
    new_version = expected_version + 1
    
    # Build update expression
    update_parts = []
    attr_values = {
        ':version': {'N': str(new_version)},
        ':expected_version': {'N': str(expected_version)},
        ':timestamp': {'S': timestamp}
    }
    
    for key, value in updates.items():
        update_parts.append(f'{key} = :{key}')
        
        # Determine DynamoDB type
        if isinstance(value, str):
            attr_values[f':{key}'] = {'S': value}
        elif isinstance(value, (int, float, Decimal)):
            attr_values[f':{key}'] = {'N': str(value)}
        elif isinstance(value, bool):
            attr_values[f':{key}'] = {'BOOL': value}
    
    update_parts.append('version = :version')
    update_parts.append('updatedAt = :timestamp')
    
    update_expression = 'SET ' + ', '.join(update_parts)
    
    try:
        response = dynamodb.update_item(
            TableName=bookings_table,
            Key={'bookingId': {'S': booking_id}},
            UpdateExpression=update_expression,
            ConditionExpression='version = :expected_version',
            ExpressionAttributeValues=attr_values,
            ReturnValues='ALL_NEW'
        )
        
        return response.get('Attributes', {})
        
    except dynamodb.exceptions.ConditionalCheckFailedException:
        raise TransactionError(
            f'Concurrent modification detected. Expected version {expected_version}, '
            'but booking was modified by another process.'
        )


def check_idempotency(
    idempotency_key: str,
    idempotency_table: str,
    ttl_seconds: int = 86400  # 24 hours
) -> Optional[Dict[str, Any]]:
    """
    Check if request with idempotency key was already processed
    
    Args:
        idempotency_key: Unique key for request
        idempotency_table: Idempotency table name
        ttl_seconds: TTL for idempotency records
        
    Returns:
        Previous response if exists, None otherwise
    """
    
    try:
        response = dynamodb.get_item(
            TableName=idempotency_table,
            Key={'idempotencyKey': {'S': idempotency_key}}
        )
        
        if 'Item' in response:
            # Check if not expired
            ttl = int(response['Item'].get('ttl', {}).get('N', 0))
            current_time = int(datetime.utcnow().timestamp())
            
            if ttl > current_time:
                return response['Item'].get('response', {})
        
        return None
        
    except Exception as e:
        print(f"Error checking idempotency: {str(e)}")
        return None


def store_idempotency_result(
    idempotency_key: str,
    response_data: Dict[str, Any],
    idempotency_table: str,
    ttl_seconds: int = 86400
) -> None:
    """
    Store response for idempotency checking
    
    Args:
        idempotency_key: Unique key for request
        response_data: Response to store
        idempotency_table: Idempotency table name
        ttl_seconds: TTL for record
    """
    
    ttl = int(datetime.utcnow().timestamp()) + ttl_seconds
    
    try:
        dynamodb.put_item(
            TableName=idempotency_table,
            Item={
                'idempotencyKey': {'S': idempotency_key},
                'response': {'S': str(response_data)},
                'ttl': {'N': str(ttl)},
                'createdAt': {'S': datetime.utcnow().isoformat()}
            }
        )
    except Exception as e:
        print(f"Error storing idempotency result: {str(e)}")
