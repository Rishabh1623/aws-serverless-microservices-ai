"""
Refund Payment Lambda Handler

Processes refunds through Stripe API.
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

payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')

def lambda_handler(event, context):
    """
    Refund payment
    
    POST /payments/{paymentId}/refund
    Body:
    {
        "amount": 1299.99,  // Optional, defaults to full refund
        "reason": "Customer requested cancellation"
    }
    """
    start_time = datetime.now()
    
    try:        
        payment_id = event['pathParameters']['paymentId']
        body = json.loads(event['body'])
        
        reason = body.get('reason', 'Customer requested')
        refund_amount = body.get('amount')  # None = full refund
        
        # Get payment record
        payment_response = payments_table.get_item(Key={'paymentId': payment_id})
        if 'Item' not in payment_response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Payment not found'})
            }
        
        payment = payment_response['Item']
        
        if payment.get('status') == 'refunded':
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Payment already refunded'})
            }
        
        original_amount = Decimal(str(payment['amount']))
        refund_amount = Decimal(str(refund_amount)) if refund_amount else original_amount
        
        if refund_amount > original_amount:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Refund amount exceeds original payment'})
            }
        
        # Process refund with Stripe (mock for demo)
        refund_id = f"re_{uuid.uuid4().hex[:24]}"
        
        # In production, call Stripe API:
        # import stripe
        # refund = stripe.Refund.create(
        #     charge=payment['stripeChargeId'],
        #     amount=int(refund_amount * 100)
        # )
        
        # Update payment record
        payments_table.update_item(
            Key={'paymentId': payment_id},
            UpdateExpression='SET #status = :status, refundId = :refund_id, refundAmount = :amount, refundReason = :reason, updatedAt = :updated',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'refunded',
                ':refund_id': refund_id,
                ':amount': refund_amount,
                ':reason': reason,
                ':updated': datetime.now().isoformat()
            }
        )
        
        # Publish refund event
        try:
            events.put_events(
                Entries=[{
                    'Source': 'travel.payments',
                    'DetailType': 'Payment Refunded',
                    'Detail': json.dumps({
                        'paymentId': payment_id,
                        'orderId': payment.get('orderId'),
                        'userId': payment.get('userId'),
                        'refundAmount': str(refund_amount),
                        'reason': reason,
                        'event_type': 'payment_refunded'
                    }),
                    'EventBusName': event_bus_name
                }]
            )
        except Exception as e:
            print(f"Error publishing event: {str(e)}")
        
        # Publish metrics
        duration = (datetime.now() - start_time).total_seconds() * 1000
        publish_metrics('RefundPayment', duration, float(refund_amount))        xray_recorder.put_metadata('refund_amount', str(refund_amount))
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Response-Time': f'{duration}ms'
            },
            'body': json.dumps({
                'message': 'Refund processed successfully',
                'paymentId': payment_id,
                'refundId': refund_id,
                'refundAmount': str(refund_amount),
                'status': 'refunded'
            })
        }
        
    except Exception as e:
        print(f"Error processing refund: {str(e)}")
        import traceback
        traceback.print_exc()        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Refund processing failed'})
        }

def publish_metrics(operation: str, duration: float, amount: float):
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
                    'MetricName': 'RefundAmount',
                    'Value': amount,
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                }
            ]
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
