"""
Search Hotels Lambda Handler

Search and filter hotels by location, dates, price, amenities.
"""

import json
import os
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['HOTEL_TABLE'])


def lambda_handler(event, context):
    """
    Search hotels with filters
    
    Query Parameters:
    - destination: City/location (required)
    - checkIn: Check-in date YYYY-MM-DD
    - checkOut: Check-out date YYYY-MM-DD
    - guests: Number of guests
    - minPrice: Minimum price per night
    - maxPrice: Maximum price per night
    - category: Hotel category (luxury, business, budget)
    - amenities: Comma-separated amenities
    - starRating: Minimum star rating
    """
    try:
        params = event.get('queryStringParameters') or {}
        
        destination = params.get('destination')
        check_in = params.get('checkIn')
        check_out = params.get('checkOut')
        guests = int(params.get('guests', 1))
        min_price = float(params.get('minPrice', 0)) if params.get('minPrice') else None
        max_price = float(params.get('maxPrice', 10000)) if params.get('maxPrice') else None
        category = params.get('category')
        amenities = params.get('amenities', '').split(',') if params.get('amenities') else []
        min_stars = int(params.get('starRating', 0)) if params.get('starRating') else None
        
        if not destination:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'destination is required'})
            }
        
        # Query hotels by destination
        response = table.scan(
            FilterExpression=Attr('location.city').eq(destination)
        )
        
        hotels = response.get('Items', [])
        
        # Apply filters
        if category:
            hotels = [h for h in hotels if h.get('category') == category]
        
        if min_price or max_price:
            hotels = [
                h for h in hotels
                if (min_price is None or h.get('basePricePerNight', 0) >= min_price) and
                   (max_price is None or h.get('basePricePerNight', 0) <= max_price)
            ]
        
        if min_stars:
            hotels = [h for h in hotels if h.get('starRating', 0) >= min_stars]
        
        if amenities:
            hotels = [
                h for h in hotels
                if all(amenity in h.get('amenities', []) for amenity in amenities)
            ]
        
        # Calculate dynamic pricing if dates provided
        if check_in and check_out:
            for hotel in hotels:
                hotel['dynamicPrice'] = calculate_dynamic_price(
                    base_price=hotel.get('basePricePerNight', 0),
                    check_in=check_in,
                    check_out=check_out
                )
        
        # Sort by price
        hotels.sort(key=lambda x: x.get('basePricePerNight', 0))
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'hotels': hotels,
                'count': len(hotels),
                'filters': {
                    'destination': destination,
                    'checkIn': check_in,
                    'checkOut': check_out,
                    'guests': guests,
                    'category': category
                }
            }, default=str)
        }
        
    except Exception as e:
        print(f"Error searching hotels: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Internal server error'})
        }


def calculate_dynamic_price(base_price: float, check_in: str, check_out: str) -> float:
    """Calculate dynamic price based on dates"""
    try:
        check_in_date = datetime.strptime(check_in, '%Y-%m-%d')
        check_out_date = datetime.strptime(check_out, '%Y-%m-%d')
        nights = (check_out_date - check_in_date).days
        
        total = base_price * nights
        
        # Weekend premium
        weekend_nights = sum(
            1 for i in range(nights)
            if (check_in_date + timedelta(days=i)).weekday() >= 4
        )
        if weekend_nights > 0:
            total *= 1.05
        
        # Early bird discount (30+ days)
        from datetime import timedelta
        days_advance = (check_in_date - datetime.now()).days
        if days_advance >= 30:
            total *= 0.9
        
        return round(total, 2)
        
    except:
        return base_price


from datetime import timedelta
