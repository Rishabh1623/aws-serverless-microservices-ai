import json
import os
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['PRODUCT_TABLE'])

def lambda_handler(event, context):
    """Retrieve product details by ID"""
    try:
        product_id = event['pathParameters']['productId']
        
        if not product_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'productId is required'})
            }
        
        # Get product from DynamoDB
        response = table.get_item(
            Key={'productId': product_id}
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Product not found'})
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'product': response['Item']
            }, default=str)
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required parameter: {str(e)}'})
        }
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to retrieve product'})
        }
    except Exception as e:
        print(f"Error retrieving product: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
