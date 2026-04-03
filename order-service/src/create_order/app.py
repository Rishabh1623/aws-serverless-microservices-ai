"""
Create Order Lambda Handler

Creates order from cart items and initiates payment flow.
"""

import json
import os
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')
cloudwatch = boto3.client('cloudwatch')

orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
cart_table = dynamodb.Table(os.environ['CART_TABLE'])
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')


@xray_recorder.capture('create_order')
def lambda_handler(event, context):
    """
    Create order from cart
    
    POST /orders
    Body:
    {
        "userId": "user123",
        "guestDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890"
        },
        "promoCode": "SUMMER20"  // optional
    }
    """
    start_time = datetime.now()
    
    try:
        xray_recorder.put_metadata('function', 'create_order')
        
        body = json.loads(event['body'])
        user_id = body['userId']
        guest_details = body.get('guestDetails', {})
        promo_code = body.get('promoCode')
        
        # Get cart items
        cart_response = cart_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        cart_items = cart_response.get('Items', [])
        
        if not cart_items:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Cart is empty'})
            }
        
        # Calculate total
        total_price = sum(Decimal(str(item.get('totalPrice', 0))) for item in cart_items)
        
        # Apply promo code discount if provided
        discount_amount = Decimal('0')
        if promo_code:
            # TODO: Validate and apply promo code
            discount_amount = total_price * Decimal('0.10')  # 10% discount example
            total_price = total_price - discount_amount
        
        # Create order
        order_id = str(uuid.uuid4())
        
        order = {
            'orderId': order_id,
            'userId': user_id,
            'items': cart_items,
            'totalPrice': total_price,
            'discountAmount': discount_amount,
            'promoCode': promo_code,
            'guestDetails': guest_details,
            'status': 'pending_payment',  # pending_payment → confirmed → completed
            'paymentStatus': 'pending',
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        # Save order
        orders_table.put_item(Item=order)
        
        # Clear cart items (mark as ordered)
        for item in cart_items:
            cart_table.update_item(
                Key={'cartItemId': item['cartItemId']},
                UpdateExpression='SET #status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': 'ordered'}
            )
        
        # Publish order created event
        try:
            events.put_events(
                Entries=[{
                    'Source': 'travel.orders',
                    'DetailType': 'Order Created',
                    'Detail': json.dumps({
                        'orderId': order_id,
                        'userId': user_id,
                        'totalPrice': str(total_price),
                        'itemCount': len(cart_items),
                        'guestEmail': guest_details.get('email'),
                        'event_type': 'order_created'
                    }),
                    'EventBusName': event_bus_name
                }]
            )
        except Exception as e:
            print(f"Error publishing event: {str(e)}")
        
        # Publish metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_metrics('CreateOrder', duration, float(total_price))
        
        xray_recorder.put_annotation('order_id', order_id)
        xray_recorder.put_metadata('total_price', str(total_price))
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Response-Time': f'{duration}ms'
            },
            'body': json.dumps({
                'message': 'Order created successfully',
                'orderId': order_id,
                'totalPrice': str(total_price),
                'discountAmount': str(discount_amount),
                'status': 'pending_payment',
                'itemCount': len(cart_items),
                'nextStep': 'payment'
            })
        }
        
    except KeyError as e:
        xray_recorder.put_annotation('error', True)
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    
    except Exception as e:
        print(f"Error creating order: {str(e)}")
        import traceback
        traceback.print_exc()
        xray_recorder.put_annotation('error', True)
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }


def publish_metrics(operation: str, duration: float, order_value: float):
    """Publish custom CloudWatch metrics"""
    try:
        cloudwatch.put_metric_data(
            Namespace='TravelPlatform/OrderService',
            MetricData=[
                {
                    'MetricName': 'Duration',
                    'Value': duration,
                    'Unit': 'Milliseconds',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                },
                {
                    'MetricName': 'OrderValue',
                    'Value': order_value,
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                },
                {
                    'MetricName': 'OrderCount',
                    'Value': 1,
                    'Unit': 'Count',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                }
            ]
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
