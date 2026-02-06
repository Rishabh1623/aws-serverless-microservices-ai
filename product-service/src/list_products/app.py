import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['PRODUCT_TABLE'])

def lambda_handler(event, context):
    """List products with optional category filter"""
    try:
        query_params = event.get('queryStringParameters') or {}
        category = query_params.get('category')
        limit = int(query_params.get('limit', 50))
        
        if limit > 100:
            limit = 100
        
        if category:
            # Query by category using GSI
            response = table.query(
                IndexName='CategoryIndex',
                KeyConditionExpression=Key('category').eq(category),
                Limit=limit
            )
        else:
            # Scan all products
            response = table.scan(Limit=limit)
        
        items = response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'products': items,
                'count': len(items),
                'category': category
            }, default=str)
        }
        
    except ValueError:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid limit parameter'})
        }
    except Exception as e:
        print(f"Error listing products: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
