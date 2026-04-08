"""
Add to Cart Lambda Handler

Adds hotel/room to user's cart with temporary hold (15 min TTL).
"""

import json
import os
import boto3
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')
cart_table = dynamodb.Table(os.environ['CART_TABLE'])
hotels_table = dynamodb.Table(os.environ.get('HOTELS_TABLE', 'hotels'))

def lambda_handler(event, context):
    """
    Add item to cart
    
    Body:
    {
        "userId": "user123",
        "hotelId": "hotel-001",
        "roomId": "room-001",
        "checkIn": "2024-06-15",
        "checkOut": "2024-06-20",
        "guests": 2,
        "roomType": "deluxe"
    }
    """
    start_time = datetime.now()
    
    try:        
        body = json.loads(event['body'])
        
        user_id = body['userId']
        hotel_id = body['hotelId']
        room_id = body['roomId']
        check_in = body['checkIn']
        check_out = body['checkOut']
        guests = body['guests']
        room_type = body.get('roomType', 'standard')
        
        # Calculate nights and price
        from datetime import datetime as dt
        check_in_date = dt.strptime(check_in, '%Y-%m-%d')
        check_out_date = dt.strptime(check_out, '%Y-%m-%d')
        nights = (check_out_date - check_in_date).days
        
        if nights <= 0:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Invalid dates'})
            }
        
        # Get hotel details for pricing
        hotel_response = hotels_table.get_item(Key={'hotelId': hotel_id})
        if 'Item' not in hotel_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Hotel not found'})
            }
        
        hotel = hotel_response['Item']
        base_price = float(hotel.get('basePricePerNight', 100))
        
        # Calculate total price
        total_price = Decimal(str(base_price * nights))
        
        # Create cart item
        cart_item_id = str(uuid.uuid4())
        ttl = int((datetime.now() + timedelta(minutes=15)).timestamp())
        
        cart_item = {
            'cartItemId': cart_item_id,
            'userId': user_id,
            'hotelId': hotel_id,
            'hotelName': hotel.get('name', 'Unknown Hotel'),
            'roomId': room_id,
            'roomType': room_type,
            'checkIn': check_in,
            'checkOut': check_out,
            'guests': guests,
            'nights': nights,
            'pricePerNight': Decimal(str(base_price)),
            'totalPrice': total_price,
            'addedAt': datetime.now().isoformat(),
            'ttl': ttl,  # Auto-delete after 15 minutes
            'status': 'active'
        }
        
        # Save to DynamoDB
        cart_table.put_item(Item=cart_item)
        
        # Publish metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_metrics('AddToCart', duration, float(total_price))
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Response-Time': f'{duration}ms'
            },
            'body': json.dumps({
                'message': 'Added to cart',
                'cartItemId': cart_item_id,
                'totalPrice': str(total_price),
                'nights': nights,
                'expiresIn': '15 minutes'
            })
        }
        
    except KeyError as e:        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    
    except Exception as e:
        print(f"Error adding to cart: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }

def publish_metrics(operation: str, duration: float, cart_value: float):
    """Publish custom CloudWatch metrics"""
    try:
        cloudwatch.put_metric_data(
            Namespace='TravelPlatform/CartService',
            MetricData=[
                {
                    'MetricName': 'Duration',
                    'Value': duration,
                    'Unit': 'Milliseconds',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                },
                {
                    'MetricName': 'CartValue',
                    'Value': cart_value,
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                }
            ]
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
