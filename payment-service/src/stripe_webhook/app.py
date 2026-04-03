"""
Stripe Webhook Lambda Handler

Handles Stripe webhook events for payment status updates.
"""

import json
import os
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')

payments_table = dynamodb.Table(os.environ['PAYMENTS_TABLE'])
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')

def lambda_handler(event, context):
    """
    Handle Stripe webhook events
    
    Events:
    - charge.succeeded
    - charge.failed
    - charge.refunded
    - payment_intent.succeeded
    - payment_intent.payment_failed
    """
    try:        
        # Verify webhook signature (in production)
        # stripe_signature = event['headers'].get('Stripe-Signature')
        # verify_webhook_signature(event['body'], stripe_signature)
        
        body = json.loads(event['body'])
        event_type = body.get('type')
        data = body.get('data', {}).get('object', {})        
        # Handle different event types
        if event_type == 'charge.succeeded':
            handle_charge_succeeded(data)
        elif event_type == 'charge.failed':
            handle_charge_failed(data)
        elif event_type == 'charge.refunded':
            handle_charge_refunded(data)
        elif event_type == 'payment_intent.succeeded':
            handle_payment_intent_succeeded(data)
        elif event_type == 'payment_intent.payment_failed':
            handle_payment_intent_failed(data)
        else:
            print(f"Unhandled event type: {event_type}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({'received': True})
        }
        
    except Exception as e:
        print(f"Error processing webhook: {str(e)}")
        import traceback
        traceback.print_exc()        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Webhook processing failed'})
        }

def handle_charge_succeeded(charge):
    """Handle successful charge"""
    charge_id = charge.get('id')
    amount = charge.get('amount', 0) / 100  # Convert from cents
    
    print(f"Charge succeeded: {charge_id}, amount: ${amount}")
    
    # Update payment status if exists
    # In production, query by stripeChargeId
    publish_event('Payment Confirmed', {
        'stripeChargeId': charge_id,
        'amount': amount,
        'status': 'succeeded'
    })

def handle_charge_failed(charge):
    """Handle failed charge"""
    charge_id = charge.get('id')
    failure_message = charge.get('failure_message')
    
    print(f"Charge failed: {charge_id}, reason: {failure_message}")
    
    publish_event('Payment Failed', {
        'stripeChargeId': charge_id,
        'failureReason': failure_message,
        'status': 'failed'
    })

def handle_charge_refunded(charge):
    """Handle refunded charge"""
    charge_id = charge.get('id')
    amount_refunded = charge.get('amount_refunded', 0) / 100
    
    print(f"Charge refunded: {charge_id}, amount: ${amount_refunded}")
    
    publish_event('Payment Refunded', {
        'stripeChargeId': charge_id,
        'refundAmount': amount_refunded,
        'status': 'refunded'
    })

def handle_payment_intent_succeeded(payment_intent):
    """Handle successful payment intent"""
    intent_id = payment_intent.get('id')
    amount = payment_intent.get('amount', 0) / 100
    
    print(f"Payment intent succeeded: {intent_id}, amount: ${amount}")

def handle_payment_intent_failed(payment_intent):
    """Handle failed payment intent"""
    intent_id = payment_intent.get('id')
    last_error = payment_intent.get('last_payment_error', {})
    
    print(f"Payment intent failed: {intent_id}, error: {last_error}")

def publish_event(detail_type: str, detail: dict):
    """Publish event to EventBridge"""
    try:
        events.put_events(
            Entries=[{
                'Source': 'travel.payments.stripe',
                'DetailType': detail_type,
                'Detail': json.dumps(detail),
                'EventBusName': event_bus_name
            }]
        )
    except Exception as e:
        print(f"Error publishing event: {str(e)}")
