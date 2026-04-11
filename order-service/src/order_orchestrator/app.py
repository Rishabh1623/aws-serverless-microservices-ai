"""
Order Processing Orchestrator - Lambda Durable Function

Orchestrates the complete order workflow using AWS Lambda Durable Functions.
Replaces EventBridge-based orchestration with a single durable execution.

Workflow:
1. Validate order request
2. Get cart items
3. Apply promo code (if provided)
4. Create order
5. Process payment (with automatic retries)
6. Confirm order
7. Send confirmation email
8. Clear cart
9. Handle rollback on payment failure

Benefits over EventBridge approach:
- Single execution context with automatic state management
- Built-in retry logic for payment processing
- Automatic rollback on failures
- No separate orchestration service needed
- Pay only for active execution time
"""

import json
import os
import sys
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Dict, Any, List
from boto3.dynamodb.conditions import Key

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

# AWS clients
dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses')
secrets = boto3.client('secretsmanager')
cloudwatch = boto3.client('cloudwatch')

# Environment variables
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
cart_table = dynamodb.Table(os.environ['CART_TABLE'])
payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])
from_email = os.environ.get('FROM_EMAIL', 'orders@example.com')
template_name = os.environ.get('TEMPLATE_NAME', 'order-confirmation-dev')


@durable_handler
def lambda_handler(event: Dict[str, Any], context: Any, durable_context: DurableContext):
    """
    Durable function handler for order processing orchestration
    
    Request body:
    {
        "userId": "user123",
        "guestDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "+1234567890"
        },
        "promoCode": "SUMMER20",
        "paymentMethod": {
            "type": "card",
            "cardToken": "tok_visa"
        },
        "billingDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "address": {
                "line1": "123 Main St",
                "city": "New York",
                "state": "NY",
                "postal_code": "10001",
                "country": "US"
            }
        }
    }
    """
    start_time = datetime.now()
    
    try:
        body = json.loads(event['body'])
        
        # Step 1: Validate order request
        order_request = durable_context.step(
            'validate_order_request',
            validate_order_request,
            body
        )
        
        user_id = order_request['userId']
        
        # Step 2: Get cart items
        cart_items = durable_context.step(
            'get_cart_items',
            get_cart_items,
            user_id
        )
        
        if not cart_items:
            return create_response(400, {'error': 'Cart is empty'})
        
        # Step 3: Calculate pricing and apply promo code
        pricing = durable_context.step(
            'calculate_pricing',
            calculate_pricing,
            cart_items,
            order_request.get('promoCode')
        )
        
        # Step 4: Create order
        order_result = durable_context.step(
            'create_order',
            create_order_step,
            user_id,
            cart_items,
            pricing,
            order_request['guestDetails'],
            order_request.get('promoCode')
        )
        
        order_id = order_result['orderId']
        
        # Step 5: Process payment with automatic retries
        payment_result = durable_context.step(
            'process_payment',
            process_payment_step,
            order_id,
            pricing['finalPrice'],
            order_request.get('paymentMethod', {}),
            order_request.get('billingDetails', {}),
            max_retries=3,
            retry_delay_seconds=5
        )
        
        if not payment_result['success']:
            # Payment failed - rollback order
            durable_context.step(
                'rollback_order',
                rollback_order_step,
                order_id,
                cart_items
            )
            return create_response(402, {
                'error': 'Payment failed',
                'details': payment_result.get('error'),
                'orderId': order_id
            })
        
        # Step 6: Confirm order
        durable_context.step(
            'confirm_order',
            confirm_order_step,
            order_id,
            payment_result['paymentId']
        )
        
        # Step 7: Clear cart items
        durable_context.step(
            'clear_cart',
            clear_cart_step,
            cart_items
        )
        
        # Step 8: Send confirmation email
        durable_context.step(
            'send_confirmation_email',
            send_confirmation_email_step,
            order_id,
            order_request['guestDetails'],
            cart_items,
            pricing,
            payment_result,
            max_retries=2
        )
        
        # Publish success metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_order_metrics('OrderOrchestrator', duration, float(pricing['finalPrice']), success=True)
        
        # Return success response
        return create_response(201, {
            'message': 'Order created and payment processed successfully',
            'orderId': order_id,
            'paymentId': payment_result['paymentId'],
            'totalPrice': str(pricing['finalPrice']),
            'discountAmount': str(pricing['discountAmount']),
            'itemCount': len(cart_items),
            'status': 'confirmed',
            'createdAt': order_result['createdAt']
        })
        
    except KeyError as e:
        publish_order_metrics('OrderOrchestrator', 0, 0, success=False)
        return create_response(400, {'error': f'Missing required field: {str(e)}'})
    
    except Exception as e:
        print(f"Error in order orchestration: {str(e)}")
        import traceback
        traceback.print_exc()
        
        publish_order_metrics('OrderOrchestrator', 0, 0, success=False)
        return create_response(500, {'error': 'Internal server error'})


# ============================================================================
# Durable Function Steps
# Each step is a discrete unit of work with automatic checkpointing
# ============================================================================

def validate_order_request(body: Dict[str, Any]) -> Dict[str, Any]:
    """Step 1: Validate order request"""
    required_fields = ['userId', 'guestDetails', 'paymentMethod']
    
    for field in required_fields:
        if field not in body:
            raise KeyError(field)
    
    # Validate guest details
    guest_details = body['guestDetails']
    if 'email' not in guest_details:
        raise KeyError('guestDetails.email')
    
    return {
        'userId': body['userId'],
        'guestDetails': guest_details,
        'promoCode': body.get('promoCode'),
        'paymentMethod': body['paymentMethod'],
        'billingDetails': body.get('billingDetails', guest_details)
    }


def get_cart_items(user_id: str) -> List[Dict[str, Any]]:
    """Step 2: Get cart items for user"""
    try:
        response = cart_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression=Key('userId').eq(user_id),
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
        
        items = response.get('Items', [])
        
        # Convert DynamoDB types to standard Python types
        for item in items:
            if isinstance(item.get('totalPrice'), Decimal):
                item['totalPrice'] = float(item['totalPrice'])
            if isinstance(item.get('pricePerNight'), Decimal):
                item['pricePerNight'] = float(item['pricePerNight'])
        
        return items
        
    except Exception as e:
        print(f"Error getting cart items: {str(e)}")
        raise


def calculate_pricing(cart_items: List[Dict[str, Any]], promo_code: str = None) -> Dict[str, Any]:
    """Step 3: Calculate pricing and apply promo code"""
    # Calculate subtotal
    subtotal = sum(Decimal(str(item.get('totalPrice', 0))) for item in cart_items)
    
    # Apply promo code discount
    discount_amount = Decimal('0')
    discount_percentage = 0
    
    if promo_code:
        # Validate promo code (simplified - in production, check against promo table)
        promo_discounts = {
            'SUMMER20': 20,
            'WELCOME10': 10,
            'VIP25': 25
        }
        
        discount_percentage = promo_discounts.get(promo_code.upper(), 0)
        if discount_percentage > 0:
            discount_amount = subtotal * Decimal(str(discount_percentage / 100))
    
    final_price = subtotal - discount_amount
    
    return {
        'subtotal': subtotal,
        'discountAmount': discount_amount,
        'discountPercentage': discount_percentage,
        'finalPrice': final_price,
        'promoCode': promo_code
    }


def create_order_step(
    user_id: str,
    cart_items: List[Dict[str, Any]],
    pricing: Dict[str, Any],
    guest_details: Dict[str, Any],
    promo_code: str = None
) -> Dict[str, Any]:
    """Step 4: Create order in DynamoDB"""
    order_id = str(uuid.uuid4())
    
    order = {
        'orderId': order_id,
        'userId': user_id,
        'items': cart_items,
        'subtotal': pricing['subtotal'],
        'discountAmount': pricing['discountAmount'],
        'totalPrice': pricing['finalPrice'],
        'promoCode': promo_code,
        'guestDetails': guest_details,
        'status': 'pending_payment',
        'paymentStatus': 'pending',
        'createdAt': datetime.now().isoformat(),
        'updatedAt': datetime.now().isoformat()
    }
    
    orders_table.put_item(Item=order)
    
    print(f"Order created: {order_id}")
    
    return {
        'orderId': order_id,
        'createdAt': order['createdAt']
    }


def process_payment_step(
    order_id: str,
    amount: Decimal,
    payment_method: Dict[str, Any],
    billing_details: Dict[str, Any]
) -> Dict[str, Any]:
    """Step 5: Process payment with Stripe (with automatic retries)"""
    print(f"Processing payment for order {order_id}: ${amount}")
    
    try:
        # Get Stripe API key from Secrets Manager
        stripe_key = get_stripe_key()
        
        # In production, integrate with Stripe:
        # import stripe
        # stripe.api_key = stripe_key
        # charge = stripe.Charge.create(
        #     amount=int(amount * 100),
        #     currency='usd',
        #     source=payment_method.get('cardToken'),
        #     description=f"Order {order_id}"
        # )
        
        # Simulate payment processing
        payment_id = str(uuid.uuid4())
        stripe_charge_id = f"ch_{uuid.uuid4().hex[:24]}"
        
        # Simulate occasional failures for testing retry logic
        import random
        if random.random() < 0.1:  # 10% failure rate for testing
            return {
                'success': False,
                'error': 'Payment gateway timeout',
                'paymentId': None
            }
        
        # Save payment record
        payment_record = {
            'paymentId': payment_id,
            'orderId': order_id,
            'amount': amount,
            'currency': 'USD',
            'paymentMethod': payment_method.get('type', 'card'),
            'stripeChargeId': stripe_charge_id,
            'status': 'completed',
            'billingDetails': billing_details,
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        payments_table.put_item(Item=payment_record)
        
        print(f"Payment processed successfully: {payment_id}")
        
        return {
            'success': True,
            'paymentId': payment_id,
            'stripeChargeId': stripe_charge_id,
            'amount': str(amount),
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Payment processing error: {str(e)}")
        return {
            'success': False,
            'error': str(e),
            'paymentId': None
        }


def confirm_order_step(order_id: str, payment_id: str):
    """Step 6: Update order status to confirmed after successful payment"""
    orders_table.update_item(
        Key={'orderId': order_id},
        UpdateExpression='SET #status = :status, paymentStatus = :payment_status, paymentId = :payment_id, confirmedAt = :time, updatedAt = :updated',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'confirmed',
            ':payment_status': 'completed',
            ':payment_id': payment_id,
            ':time': datetime.now().isoformat(),
            ':updated': datetime.now().isoformat()
        }
    )
    print(f"Order {order_id} confirmed with payment {payment_id}")


def clear_cart_step(cart_items: List[Dict[str, Any]]):
    """Step 7: Clear cart items (mark as ordered)"""
    for item in cart_items:
        cart_table.update_item(
            Key={'cartItemId': item['cartItemId']},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'ordered'}
        )
    print(f"Cleared {len(cart_items)} items from cart")


def rollback_order_step(order_id: str, cart_items: List[Dict[str, Any]]):
    """Rollback: Cancel order and restore cart items"""
    print(f"Rolling back order {order_id}")
    
    # Update order status to cancelled
    orders_table.update_item(
        Key={'orderId': order_id},
        UpdateExpression='SET #status = :status, paymentStatus = :payment_status, cancelledAt = :time, updatedAt = :updated',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'cancelled',
            ':payment_status': 'failed',
            ':time': datetime.now().isoformat(),
            ':updated': datetime.now().isoformat()
        }
    )
    
    # Restore cart items to active status
    for item in cart_items:
        cart_table.update_item(
            Key={'cartItemId': item['cartItemId']},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'active'}
        )
    
    print(f"Order {order_id} rolled back, cart items restored")


def send_confirmation_email_step(
    order_id: str,
    guest_details: Dict[str, Any],
    cart_items: List[Dict[str, Any]],
    pricing: Dict[str, Any],
    payment_result: Dict[str, Any]
):
    """Step 8: Send order confirmation email"""
    guest_email = guest_details.get('email')
    
    if not guest_email:
        print(f"No email for order {order_id}, skipping notification")
        return
    
    guest_name = guest_details.get('name', 'Guest')
    
    # Prepare item details for email
    items_summary = []
    for item in cart_items:
        items_summary.append({
            'hotelName': item.get('hotelName', 'Hotel'),
            'roomType': item.get('roomType', 'Room'),
            'checkIn': item.get('checkIn'),
            'checkOut': item.get('checkOut'),
            'nights': item.get('nights'),
            'price': str(item.get('totalPrice'))
        })
    
    # Send templated email via SES
    try:
        response = ses.send_templated_email(
            Source=from_email,
            Destination={'ToAddresses': [guest_email]},
            Template=template_name,
            TemplateData=json.dumps({
                'guestName': guest_name,
                'orderId': order_id,
                'items': items_summary,
                'subtotal': str(pricing['subtotal']),
                'discountAmount': str(pricing['discountAmount']),
                'totalPrice': str(pricing['finalPrice']),
                'paymentId': payment_result['paymentId']
            })
        )
        
        print(f"Sent confirmation email to {guest_email}, MessageId: {response['MessageId']}")
        
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        # Don't fail the order if email fails
        # In production, you might want to queue for retry


# ============================================================================
# Helper Functions
# ============================================================================

def get_stripe_key() -> str:
    """Get Stripe API key from Secrets Manager"""
    try:
        secret_name = os.environ.get('STRIPE_SECRET_NAME', 'stripe-api-key')
        response = secrets.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        return secret.get('api_key')
    except Exception as e:
        print(f"Error getting Stripe key: {str(e)}")
        return 'sk_test_demo_key'


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create API Gateway response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, default=str)
    }


def publish_order_metrics(operation: str, duration: float, revenue: float, success: bool = True):
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
                'MetricName': 'OrderCount',
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
            Namespace='TravelPlatform/OrderService',
            MetricData=metrics
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
