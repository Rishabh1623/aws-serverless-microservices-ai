import json
import os
import boto3
import requests
from datetime import datetime
from decimal import Decimal
import uuid

dynamodb = boto3.resource('dynamodb')
eventbridge = boto3.client('events')
table = dynamodb.Table(os.environ['ORDER_TABLE'])

# Service endpoints from environment
CART_SERVICE_URL = os.environ.get('CART_SERVICE_URL', '')
PRODUCT_SERVICE_URL = os.environ.get('PRODUCT_SERVICE_URL', '')
PAYMENT_SERVICE_URL = os.environ.get('PAYMENT_SERVICE_URL', '')

def lambda_handler(event, context):
    """Create order from cart"""
    try:
        body = json.loads(event['body'])
        user_id = body['userId']
        shipping_address = body.get('shippingAddress', {})
        payment_method = body.get('paymentMethod', 'CARD')
        
        # Validate input
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'userId is required'})
            }
        
        # 1. Get cart items
        cart_response = requests.get(f"{CART_SERVICE_URL}/{user_id}", timeout=10)
        if cart_response.status_code != 200:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Failed to retrieve cart'})
            }
        
        cart_data = cart_response.json()
        cart_items = cart_data.get('items', [])
        
        if not cart_items:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Cart is empty'})
            }
        
        # 2. Calculate total from cart items (skip product validation for demo)
        total_amount = Decimal('0')
        order_items = []
        
        for item in cart_items:
            product_id = item['productId']
            quantity = int(item['quantity'])
            
            # Use mock price for demo (in production, validate with product service)
            mock_price = Decimal('99.99')
            
            item_total = mock_price * quantity
            total_amount += item_total
            
            order_items.append({
                'productId': product_id,
                'productName': product['name'],
                'quantity': quantity,
                'price': product['price']
            })
        
        # 3. Create order record
        order_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        order = {
            'orderId': order_id,
            'userId': user_id,
            'items': order_items,
            'totalAmount': float(total_amount),
            'status': 'PENDING',
            'shippingAddress': shipping_address,
            'paymentMethod': payment_method,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        table.put_item(Item=order)
        
        # 4. Process payment
        payment_payload = {
            'orderId': order_id,
            'userId': user_id,
            'amount': float(total_amount),
            'currency': 'USD',
            'paymentMethod': payment_method
        }
        
        payment_response = requests.post(
            f"{PAYMENT_SERVICE_URL}/payments",
            json=payment_payload,
            timeout=30
        )
        
        if payment_response.status_code != 200:
            # Payment failed - update order status
            table.update_item(
                Key={'orderId': order_id},
                UpdateExpression='SET #status = :status, updatedAt = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'PAYMENT_FAILED',
                    ':timestamp': datetime.utcnow().isoformat()
                }
            )
            
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Payment processing failed'})
            }
        
        payment_data = payment_response.json()
        payment_id = payment_data.get('paymentId')
        
        # 5. Update order with payment info
        table.update_item(
            Key={'orderId': order_id},
            UpdateExpression='SET #status = :status, paymentId = :paymentId, updatedAt = :timestamp',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'PAID',
                ':paymentId': payment_id,
                ':timestamp': datetime.utcnow().isoformat()
            }
        )
        
        # 6. Clear cart (TODO: implement proper cart clearing)
        # For now, items remain in cart after order
        
        # 7. Publish OrderCreated event
        eventbridge.put_events(
            Entries=[
                {
                    'Source': 'order-service',
                    'DetailType': 'OrderCreated',
                    'Detail': json.dumps({
                        'orderId': order_id,
                        'userId': user_id,
                        'totalAmount': float(total_amount),
                        'items': order_items
                    })
                }
            ]
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Order created successfully',
                'orderId': order_id,
                'status': 'PAID',
                'totalAmount': float(total_amount),
                'paymentId': payment_id
            })
        }
        
    except requests.exceptions.RequestException as e:
        print(f"Service communication error: {str(e)}")
        return {
            'statusCode': 503,
            'body': json.dumps({'error': 'Service temporarily unavailable'})
        }
    except Exception as e:
        print(f"Error creating order: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
