"""
Unit tests for search_hotels Lambda function
Uses moto to mock DynamoDB (industry best practice)
"""

import json
import os
import pytest
from moto import mock_dynamodb
import boto3
from decimal import Decimal


@pytest.fixture
def dynamodb_table():
    """Create a mock DynamoDB table for testing"""
    with mock_dynamodb():
        # Create mock DynamoDB resource
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        # Create hotels table
        table = dynamodb.create_table(
            TableName='hotel-service-hotels-test',
            KeySchema=[
                {'AttributeName': 'hotelId', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'hotelId', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        # Add sample data
        table.put_item(Item={
            'hotelId': 'hotel-001',
            'name': 'Luxury Resort Bali',
            'location': {
                'city': 'Bali',
                'country': 'Indonesia'
            },
            'category': 'luxury',
            'starRating': 5,
            'basePricePerNight': Decimal('200'),
            'amenities': ['pool', 'spa', 'wifi']
        })
        
        table.put_item(Item={
            'hotelId': 'hotel-002',
            'name': 'Budget Inn Bali',
            'location': {
                'city': 'Bali',
                'country': 'Indonesia'
            },
            'category': 'budget',
            'starRating': 3,
            'basePricePerNight': Decimal('50'),
            'amenities': ['wifi']
        })
        
        yield table


def test_search_hotels_by_destination(dynamodb_table, monkeypatch):
    """Test searching hotels by destination"""
    # Set environment variable
    monkeypatch.setenv('HOTEL_TABLE', 'hotel-service-hotels-test')
    
    # Import after setting env var
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'search_hotels'))
    from app import lambda_handler
    
    # Create test event
    event = {
        'queryStringParameters': {
            'destination': 'Bali'
        }
    }
    
    # Call Lambda handler
    response = lambda_handler(event, None)
    
    # Assertions
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 2
    assert len(body['hotels']) == 2


def test_search_hotels_with_price_filter(dynamodb_table, monkeypatch):
    """Test searching hotels with price filter"""
    monkeypatch.setenv('HOTEL_TABLE', 'hotel-service-hotels-test')
    
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'search_hotels'))
    from app import lambda_handler
    
    event = {
        'queryStringParameters': {
            'destination': 'Bali',
            'minPrice': '100',
            'maxPrice': '300'
        }
    }
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 1
    assert body['hotels'][0]['name'] == 'Luxury Resort Bali'


def test_search_hotels_missing_destination(monkeypatch):
    """Test error handling when destination is missing"""
    monkeypatch.setenv('HOTEL_TABLE', 'hotel-service-hotels-test')
    
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'search_hotels'))
    from app import lambda_handler
    
    event = {
        'queryStringParameters': {}
    }
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 400
    body = json.loads(response['body'])
    assert 'error' in body


def test_search_hotels_by_category(dynamodb_table, monkeypatch):
    """Test searching hotels by category"""
    monkeypatch.setenv('HOTEL_TABLE', 'hotel-service-hotels-test')
    
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'search_hotels'))
    from app import lambda_handler
    
    event = {
        'queryStringParameters': {
            'destination': 'Bali',
            'category': 'luxury'
        }
    }
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 1
    assert body['hotels'][0]['category'] == 'luxury'
