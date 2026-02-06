import json
import os
import pytest
from moto import mock_dynamodb
import boto3
from src.get_cart import app

@pytest.fixture
def setup_dynamodb():
    with mock_dynamodb():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table = dynamodb.create_table(
            TableName='test-cart-table',
            KeySchema=[
                {'AttributeName': 'userId', 'KeyType': 'HASH'},
                {'AttributeName': 'productId', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'userId', 'AttributeType': 'S'},
                {'AttributeName': 'productId', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Add test data
        table.put_item(Item={'userId': 'user123', 'productId': 'prod1', 'quantity': 2})
        table.put_item(Item={'userId': 'user123', 'productId': 'prod2', 'quantity': 1})
        
        os.environ['CART_TABLE'] = 'test-cart-table'
        yield table

def test_get_cart_success(setup_dynamodb):
    event = {
        'pathParameters': {
            'userId': 'user123'
        }
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['userId'] == 'user123'
    assert body['itemCount'] == 2
    assert body['totalItems'] == 3

def test_get_cart_empty(setup_dynamodb):
    event = {
        'pathParameters': {
            'userId': 'user999'
        }
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['itemCount'] == 0
    assert body['totalItems'] == 0
