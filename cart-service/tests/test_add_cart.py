import json
import os
import pytest
from moto import mock_dynamodb
import boto3
from src.add_cart import app

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
        os.environ['CART_TABLE'] = 'test-cart-table'
        yield table

def test_add_cart_success(setup_dynamodb):
    event = {
        'body': json.dumps({
            'userId': 'user123',
            'productId': 'prod456',
            'quantity': 2
        })
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['message'] == 'Item added to cart'
    assert body['item']['userId'] == 'user123'
    assert body['item']['productId'] == 'prod456'

def test_add_cart_missing_fields(setup_dynamodb):
    event = {
        'body': json.dumps({
            'userId': 'user123'
        })
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 400
    body = json.loads(response['body'])
    assert 'error' in body

def test_add_cart_invalid_quantity(setup_dynamodb):
    event = {
        'body': json.dumps({
            'userId': 'user123',
            'productId': 'prod456',
            'quantity': 0
        })
    }
    
    response = app.lambda_handler(event, None)
    
    assert response['statusCode'] == 400
    body = json.loads(response['body'])
    assert 'quantity must be at least 1' in body['error']
