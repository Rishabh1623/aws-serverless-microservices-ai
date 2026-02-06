import json
import os
import pytest
from moto import mock_dynamodb
import boto3
from src.get_product import app

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
        
        # Add test product
        table.put_item(Item={
            'productId': 'prod123',
            'name': 'Test Product',
            'category': 'electronics',
            'price': 99.99
        })
        
        os.environ['PRODUCT_TABLE'] = 'test-product-table'
        yield table

def test_get_product_success(setup_dynamodb):
    event = {
        'pathParameters': {
            'productId': 'prod123'
        }
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['product']['productId'] == 'prod123'
    assert body['product']['name'] == 'Test Product'

def test_get_product_not_found(setup_dynamodb):
    event = {
        'pathParameters': {
            'productId': 'prod999'
        }
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 404
    body = json.loads(response['body'])
    assert 'error' in body
