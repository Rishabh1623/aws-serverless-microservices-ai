"""
Cancel Order Lambda Handler

Cancels an order and initiates refund if payment was made.
"""

import json
import os
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')
orders_table = dynamodb.Table(os.environ['ORDERS_TABLE'])
event_bus_name = os.environ.get('EVENT_BUS_NAME', 'travel-platform-dev')

def lambda_handler(event, context):
    """
    Cancel order
    
    DELETE /orders?orderId=xxx
    Body: {"reason": "Changed plans"}
    """
    try:
        # Get orderId from query parameters
        order_id = event.get('queryStringParameters', {}).get('orderId')
        
        if not order_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'orderId query parameter is required'})
            }
        
        body = json.loads(event.get('body', '{}'))
        reason = body.get('reason', 'Customer requested')        
        # Get order
        response = orders_table.get_item(Key={'orderId': order_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'Order not found'})
            }
        
        order = response['Item']
        
        # Check if order can be cancelled
        if order['status'] in ['cancelled', 'completed']:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': f'Cannot cancel order with status: {order["status"]}'})
            }
        
        # Update order status
        orders_table.update_item(
            Key={'orderId': order_id},
            UpdateExpression='SET #status = :status, cancelledAt = :cancelled_at, cancellationReason = :reason, updatedAt = :updated_at',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'cancelled',
                ':cancelled_at': datetime.now().isoformat(),
                ':reason': reason,
                ':updated_at': datetime.now().isoformat()
            }
        )
        
        # Publish order cancelled event
        try:
            events.put_events(
                Entries=[{
                    'Source': 'travel.orders',
                    'DetailType': 'Order Cancelled',
                    'Detail': json.dumps({
                        'orderId': order_id,
                        'userId': order['userId'],
                        'totalPrice': str(order['totalPrice']),
                        'paymentStatus': order.get('paymentStatus'),
                        'reason': reason,
                        'event_type': 'order_cancelled'
                    }),
                    'EventBusName': event_bus_name
                }]
            )
        except Exception as e:
            print(f"Error publishing event: {str(e)}")
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'message': 'Order cancelled successfully',
                'orderId': order_id,
                'status': 'cancelled',
                'refundInitiated': order.get('paymentStatus') == 'paid'
            })
        }
        
    except Exception as e:
        print(f"Error cancelling order: {str(e)}")        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }
