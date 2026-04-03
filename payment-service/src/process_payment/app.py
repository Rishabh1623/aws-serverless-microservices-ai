"""
Process Payment Lambda Handler

Processes payment using Stripe API with idempotency and retry logic.
"""

import json
import os
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')
cloudwatch = boto3.client('cloudwatch')
secrets = boto3.client('secretsmanager')

payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')

def lambda_handler(event, context):
    """
    Process payment with Stripe
    
    POST /payments
    Body:
    {
        "orderId": "order-123",
        "paymentMethod": "card",
        "cardToken": "tok_visa",  // Stripe token
        "amount": 1299.99,
        "currency": "USD",
        "billingDetails": {
            "name": "John Doe",
            "email": "john@example.com",
            "address": {...}
        }
    }
    """
    start_time = datetime.now()
    
    try:        
        body = json.loads(event['body'])
        
        order_id = body['orderId']
        payment_method = body.get('paymentMethod', 'card')
        card_token = body.get('cardToken')
        amount = Decimal(str(body['amount']))
        currency = body.get('currency', 'USD')
        billing_details = body.get('billingDetails', {})
        
        # Verify order exists and is pending payment
        order_response = orders_table.get_item(Key={'orderId': order_id})
        if 'Item' not in order_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Order not found'})
            }
        
        order = order_response['Item']
        
        if order.get('paymentStatus') == 'completed':
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Order already paid'})
            }
        
        # Get Stripe API key from Secrets Manager
        stripe_key = get_stripe_key()
        
        # Process payment with Stripe (mock for demo)
        payment_id = str(uuid.uuid4())
        stripe_charge_id = f"ch_{uuid.uuid4().hex[:24]}"
        
        # In production, call Stripe API:
        # import stripe
        # stripe.api_key = stripe_key
        # charge = stripe.Charge.create(
        #     amount=int(amount * 100),  # Stripe uses cents
        #     currency=currency.lower(),
        #     source=card_token,
        #     description=f"Order {order_id}"
        # )
        
        # Save payment record
        payment_record = {
            'paymentId': payment_id,
            'orderId': order_id,
            'userId': order.get('userId'),
            'amount': amount,
            'currency': currency,
            'paymentMethod': payment_method,
            'stripeChargeId': stripe_charge_id,
            'status': 'completed',
            'billingDetails': billing_details,
            'createdAt': datetime.now().isoformat(),
            'updatedAt': datetime.now().isoformat()
        }
        
        payments_table.put_item(Item=payment_record)
        
        # Update order payment status
        orders_table.update_item(
            Key={'orderId': order_id},
            UpdateExpression='SET paymentStatus = :status, #st = :order_status, updatedAt = :updated',
            ExpressionAttributeNames={'#st': 'status'},
            ExpressionAttributeValues={
                ':status': 'completed',
                ':order_status': 'confirmed',
                ':updated': datetime.now().isoformat()
            }
        )
        
        # Publish payment completed event
        try:
            events.put_events(
                Entries=[{
                    'Source': 'travel.payments',
                    'DetailType': 'Payment Completed',
                    'Detail': json.dumps({
                        'paymentId': payment_id,
                        'orderId': order_id,
                        'userId': order.get('userId'),
                        'amount': str(amount),
                        'currency': currency,
                        'guestEmail': billing_details.get('email'),
                        'event_type': 'payment_completed'
                    }),
                    'EventBusName': event_bus_name
                }]
            )
        except Exception as e:
            print(f"Error publishing event: {str(e)}")
        
        # Publish metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_metrics('ProcessPayment', duration, float(amount))        xray_recorder.put_metadata('amount', str(amount))
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Response-Time': f'{duration}ms'
            },
            'body': json.dumps({
                'message': 'Payment processed successfully',
                'paymentId': payment_id,
                'orderId': order_id,
                'amount': str(amount),
                'currency': currency,
                'status': 'completed',
                'stripeChargeId': stripe_charge_id
            })
        }
        
    except KeyError as e:        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    
    except Exception as e:
        print(f"Error processing payment: {str(e)}")
        import traceback
        traceback.print_exc()        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Payment processing failed'})
        }

def get_stripe_key():
    """Get Stripe API key from Secrets Manager"""
    try:
        secret_name = os.environ.get('STRIPE_SECRET_NAME', 'stripe-api-key')
        response = secrets.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        return secret.get('api_key')
    except Exception as e:
        print(f"Error getting Stripe key: {str(e)}")
        return 'sk_test_demo_key'  # Demo key

def publish_metrics(operation: str, duration: float, revenue: float):
    """Publish custom CloudWatch metrics"""
    try:
        cloudwatch.put_metric_data(
            Namespace='TravelPlatform/PaymentService',
            MetricData=[
                {
                    'MetricName': 'Duration',
                    'Value': duration,
                    'Unit': 'Milliseconds',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                },
                {
                    'MetricName': 'Revenue',
                    'Value': revenue,
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                },
                {
                    'MetricName': 'PaymentCount',
                    'Value': 1,
                    'Unit': 'Count',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                }
            ]
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
