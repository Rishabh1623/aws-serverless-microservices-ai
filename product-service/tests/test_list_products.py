import json
import os
import pytest
from moto import mock_dynamodb
import boto3
from src.list_products import app

@pytest.fixture
def setup_dynamodb():
    with mock_dynamodb():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table = dynamodb.create_table(
            TableName='test-product-table',
            KeySchema=[
                {'AttributeName': 'productId', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'productId', 'AttributeType': 'S'},
                {'AttributeName': 'category', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'CategoryIndex',
                    'KeySchema': [
                        {'AttributeName': 'category', 'KeyType': 'HASH'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Add test products
        table.put_item(Item={'productId': 'prod1', 'name': 'Product 1', 'category': 'electronics'})
        table.put_item(Item={'productId': 'prod2', 'name': 'Product 2', 'category': 'books'})
        table.put_item(Item={'productId': 'prod3', 'name': 'Product 3', 'category': 'electronics'})
        
        os.environ['PRODUCT_TABLE'] = 'test-product-table'
        yield table

def test_list_all_products(setup_dynamodb):
    event = {}
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 3

def test_list_products_by_category(setup_dynamodb):
    event = {
        'queryStringParameters': {
            'category': 'electronics'
        }
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 2
    assert body['category'] == 'electronics'
