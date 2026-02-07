import json
import os
import boto3
from datetime import datetime
from decimal import Decimal
import uuid

dynamodb = boto3.resource('dynamodb')
eventbridge = boto3.client('events')
table = dynamodb.Table(os.environ['PAYMENT_TABLE'])

# Mock payment gateway - replace with real Stripe/PayPal integration
def process_with_payment_gateway(amount, currency, payment_method):
    """
    Mock payment gateway integration
    In production, integrate with Stripe, PayPal, etc.
    """
    # Simulate payment processing
    import random
    success = random.random() > 0.1  # 90% success rate
    
    if success:
        return {
            'success': True,
            'transactionId': f'txn_{uuid.uuid4().hex[:16]}',
            'status': 'CAPTURED'
        }
    else:
        return {
            'success': False,
            'error': 'Payment declined by gateway',
            'status': 'FAILED'
        }

def lambda_handler(event, context):
    """Process payment"""
    try:
        body = json.loads(event['body'])
        order_id = body['orderId']
        user_id = body['userId']
        amount = Decimal(str(body['amount']))  # Convert to Decimal for DynamoDB
        currency = body.get('currency', 'USD')
        payment_method = body.get('paymentMethod', 'CARD')
        
        # Validate input
        if not all([order_id, user_id, amount]):
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'orderId, userId, and amount are required'})
            }
        
        if amount <= Decimal('0'):  # Compare Decimal with Decimal
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'amount must be greater than 0'})
            }
        
        # Check for idempotency
        idempotency_key = event.get('headers', {}).get('Idempotency-Key')
        if idempotency_key:
            # Check if payment already processed
            existing = table.query(
                IndexName='IdempotencyKeyIndex',
                KeyConditionExpression='idempotencyKey = :key',
                ExpressionAttributeValues={':key': idempotency_key}
            )
            if existing.get('Items'):
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Payment already processed',
                        'payment': existing['Items'][0]
                    }, default=str)
                }
        
        # Create payment record
        payment_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        payment = {
            'paymentId': payment_id,
            'orderId': order_id,
            'userId': user_id,
            'amount': amount,
            'currency': currency,
            'paymentMethod': payment_method,
            'status': 'PENDING',
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        if idempotency_key:
            payment['idempotencyKey'] = idempotency_key
        
        table.put_item(Item=payment)
        
        # Process payment with gateway
        gateway_response = process_with_payment_gateway(float(amount), currency, payment_method)
        
        if gateway_response['success']:
            # Update payment status
            table.update_item(
                Key={'paymentId': payment_id},
                UpdateExpression='SET #status = :status, transactionId = :txnId, updatedAt = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': gateway_response['status'],
                    ':txnId': gateway_response['transactionId'],
                    ':timestamp': datetime.utcnow().isoformat()
                }
            )
            
            # Publish PaymentProcessed event
            eventbridge.put_events(
                Entries=[
                    {
                        'Source': 'payment-service',
                        'DetailType': 'PaymentProcessed',
                        'Detail': json.dumps({
                            'paymentId': payment_id,
                            'orderId': order_id,
                            'amount': float(amount),  # Convert Decimal to float for JSON
                            'status': 'CAPTURED'
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
                    'message': 'Payment processed successfully',
                    'paymentId': payment_id,
                    'status': 'CAPTURED',
                    'transactionId': gateway_response['transactionId']
                })
            }
        else:
            # Payment failed
            table.update_item(
                Key={'paymentId': payment_id},
                UpdateExpression='SET #status = :status, errorMessage = :error, updatedAt = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'FAILED',
                    ':error': gateway_response.get('error', 'Unknown error'),
                    ':timestamp': datetime.utcnow().isoformat()
                }
            )
            
            # Publish PaymentFailed event
            eventbridge.put_events(
                Entries=[
                    {
                        'Source': 'payment-service',
                        'DetailType': 'PaymentFailed',
                        'Detail': json.dumps({
                            'paymentId': payment_id,
                            'orderId': order_id,
                            'error': gateway_response.get('error')
                        })
                    }
                ]
            )
            
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Payment processing failed',
                    'message': gateway_response.get('error')
                })
            }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }
    except Exception as e:
        print(f"Error processing payment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
