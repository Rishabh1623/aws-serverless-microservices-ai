"""
AI Travel Planner Tools

Personalized travel recommendations using Bedrock AI and user preferences.
"""

import boto3
import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from decimal import Decimal
from strands import tool

logger = logging.getLogger()


class TravelPlannerTools:
    """
    AI-powered travel planning and personalization
    
    Features:
    - Personalized hotel recommendations
    - Complete itinerary generation
    - Package deal suggestions
    - Dynamic pricing
    - Loyalty rewards integration
    """
    
    def __init__(self, hotel_api_url: str, bedrock_model_id: str, bedrock_region: str = 'us-east-1'):
        """
        Initialize Travel Planner Tools
        
        Args:
            hotel_api_url: Hotel Service API URL
            bedrock_model_id: Bedrock model for AI recommendations
            bedrock_region: AWS region for Bedrock (default: us-east-1)
        """
        self.hotel_api_url = hotel_api_url.rstrip('/')
        self.bedrock_region = bedrock_region
        self.bedrock = boto3.client('bedrock-runtime', region_name=bedrock_region)
        self.dynamodb = boto3.resource('dynamodb')
        self.model_id = bedrock_model_id
        self.timeout = 10
    
    @tool(description="Generate personalized hotel recommendations based on travel preferences and purpose")
    def recommend_hotels(
        self,
        destination: str,
        check_in: str,  # YYYY-MM-DD
        check_out: str,  # YYYY-MM-DD
        guests: int,
        travel_purpose: str,  # business, leisure, family, romantic, adventure
        budget_per_night: Optional[float] = None,
        preferred_amenities: Optional[List[str]] = None,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get personalized hotel recommendations
        
        Args:
            destination: City or location
            check_in: Check-in date
            check_out: Check-out date
            guests: Number of guests
            travel_purpose: Why traveling (business, leisure, family, romantic, adventure)
            budget_per_night: Maximum budget per night
            preferred_amenities: Must-have amenities (wifi, pool, gym, spa)
            user_id: User ID for personalization
            
        Returns:
            Personalized hotel recommendations with reasoning
            
        Example:
            recommend_hotels(
                destination="Paris",
                check_in="2024-06-15",
                check_out="2024-06-20",
                guests=2,
                travel_purpose="romantic",
                budget_per_night=300
            )
        """
        try:
            logger.info(f"Generating hotel recommendations for {destination}, purpose: {travel_purpose}")
            
            # Get user's travel profile if available
            user_profile = self._get_user_profile(user_id) if user_id else {}
            
            # Calculate nights
            check_in_date = datetime.strptime(check_in, '%Y-%m-%d').date()
            check_out_date = datetime.strptime(check_out, '%Y-%m-%d').date()
            nights = (check_out_date - check_in_date).days
            
            # Get available hotels (mock for now - would call hotel service)
            available_hotels = self._get_available_hotels(
                destination=destination,
                check_in=check_in_date,
                check_out=check_out_date,
                guests=guests
            )
            
            # Filter by budget
            if budget_per_night:
                available_hotels = [
                    h for h in available_hotels
                    if h.get('basePricePerNight', 0) <= budget_per_night
                ]
            
            # Filter by amenities
            if preferred_amenities:
                available_hotels = [
                    h for h in available_hotels
                    if all(amenity in h.get('amenities', []) for amenity in preferred_amenities)
                ]
            
            # Use Bedrock AI to generate personalized recommendations
            recommendations = self._generate_ai_hotel_recommendations(
                hotels=available_hotels[:10],
                travel_purpose=travel_purpose,
                user_profile=user_profile,
                destination=destination,
                nights=nights,
                guests=guests
            )
            
            # Apply loyalty discounts if user has profile
            if user_profile:
                loyalty_discount = user_profile.get('loyaltyDiscount', 0)
                for rec in recommendations:
                    original_price = rec.get('totalPrice', 0)
                    rec['loyaltyDiscount'] = original_price * loyalty_discount
                    rec['finalPrice'] = original_price * (1 - loyalty_discount)
                    rec['loyaltyTier'] = user_profile.get('loyaltyTier', 'bronze')
            
            return {
                'recommendations': recommendations,
                'destination': destination,
                'checkIn': check_in,
                'checkOut': check_out,
                'nights': nights,
                'guests': guests,
                'travelPurpose': travel_purpose,
                'totalOptions': len(recommendations),
                'personalized': bool(user_profile),
                'message': self._generate_recommendation_message(travel_purpose, len(recommendations))
            }
            
        except Exception as e:
            logger.error(f"Error generating hotel recommendations: {str(e)}")
            return {
                'error': str(e),
                'recommendations': [],
                'fallback_message': 'I can help you search hotels by location and dates'
            }
    
    @tool(description="Create complete travel itinerary with hotel, activities, and dining suggestions")
    def create_itinerary(
        self,
        destination: str,
        duration_days: int,
        travel_purpose: str,
        interests: List[str],  # culture, food, adventure, relaxation, shopping
        budget_total: Optional[float] = None,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate AI-powered complete travel itinerary
        
        Args:
            destination: Travel destination
            duration_days: Trip duration in days
            travel_purpose: Purpose of travel
            interests: User interests for activities
            budget_total: Total trip budget
            user_id: User ID for personalization
            
        Returns:
            Day-by-day itinerary with hotel, activities, dining
            
        Example:
            create_itinerary(
                destination="Tokyo",
                duration_days=5,
                travel_purpose="cultural",
                interests=["culture", "food", "shopping"],
                budget_total=2000
            )
        """
        try:
            logger.info(f"Creating itinerary for {destination}, {duration_days} days")
            
            # Get user profile
            user_profile = self._get_user_profile(user_id) if user_id else {}
            
            # Use Bedrock to generate itinerary
            itinerary = self._generate_ai_itinerary(
                destination=destination,
                duration_days=duration_days,
                travel_purpose=travel_purpose,
                interests=interests,
                budget_total=budget_total,
                user_profile=user_profile
            )
            
            # Add hotel recommendations for each night
            for day in itinerary.get('days', []):
                if day.get('accommodation_needed'):
                    day['hotel_options'] = self._get_hotels_for_day(
                        destination=destination,
                        date=day.get('date'),
                        budget=budget_total / duration_days if budget_total else None
                    )
            
            return {
                'itinerary': itinerary,
                'destination': destination,
                'duration': duration_days,
                'estimated_cost': itinerary.get('total_cost', 0),
                'personalized': bool(user_profile),
                'includes': {
                    'accommodation': True,
                    'activities': True,
                    'dining': True,
                    'transportation': True
                }
            }
            
        except Exception as e:
            logger.error(f"Error creating itinerary: {str(e)}")
            return {
                'error': str(e),
                'itinerary': {}
            }
    
    @tool(description="Suggest travel packages with bundled hotel + activities at discounted rates")
    def suggest_packages(
        self,
        destination: str,
        travel_purpose: str,
        duration_nights: int,
        guests: int,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Recommend travel packages with discounts
        
        Args:
            destination: Travel destination
            travel_purpose: Purpose of travel
            duration_nights: Number of nights
            guests: Number of travelers
            user_id: User ID for personalization
            
        Returns:
            Package deals with savings
            
        Example:
            suggest_packages(
                destination="Bali",
                travel_purpose="wellness",
                duration_nights=7,
                guests=2
            )
        """
        try:
            logger.info(f"Suggesting packages for {destination}, {duration_nights} nights")
            
            # Get user profile
            user_profile = self._get_user_profile(user_id) if user_id else {}
            
            # Get available packages (mock for now)
            packages = self._get_available_packages(
                destination=destination,
                travel_purpose=travel_purpose,
                duration_nights=duration_nights
            )
            
            # Calculate package prices with group discounts
            for package in packages:
                base_price = package.get('pricePerPerson', 0) * guests
                
                # Group discount
                if guests >= 4:
                    discount = 0.15
                elif guests >= 2:
                    discount = 0.10
                else:
                    discount = 0
                
                # Loyalty discount
                if user_profile:
                    discount += user_profile.get('loyaltyDiscount', 0)
                
                package['totalPrice'] = base_price
                package['discount'] = base_price * discount
                package['finalPrice'] = base_price * (1 - discount)
                package['savings'] = base_price * discount
            
            # Sort by value (price vs included activities)
            packages.sort(key=lambda x: x.get('finalPrice', 0))
            
            return {
                'packages': packages,
                'destination': destination,
                'nights': duration_nights,
                'guests': guests,
                'best_value': packages[0] if packages else None,
                'total_savings': sum(p.get('savings', 0) for p in packages),
                'message': f"Found {len(packages)} package deals for {destination}"
            }
            
        except Exception as e:
            logger.error(f"Error suggesting packages: {str(e)}")
            return {
                'error': str(e),
                'packages': []
            }
    
    @tool(description="Compare multiple hotels side-by-side with AI analysis")
    def compare_hotels(
        self,
        hotel_ids: List[str],
        travel_purpose: str,
        priorities: Optional[List[str]] = None  # price, location, amenities, reviews
    ) -> Dict[str, Any]:
        """
        AI-powered hotel comparison
        
        Args:
            hotel_ids: List of 2-3 hotel IDs to compare
            travel_purpose: Purpose of travel
            priorities: What matters most to user
            
        Returns:
            Detailed comparison with recommendation
        """
        try:
            if len(hotel_ids) < 2 or len(hotel_ids) > 3:
                return {'error': 'Please provide 2-3 hotels to compare'}
            
            # Get hotel details
            hotels = [self._get_hotel_details(hid) for hid in hotel_ids]
            
            # Use Bedrock for intelligent comparison
            comparison = self._generate_ai_hotel_comparison(
                hotels=hotels,
                travel_purpose=travel_purpose,
                priorities=priorities or ['price', 'location', 'amenities']
            )
            
            return {
                'hotels': hotels,
                'comparison': comparison,
                'best_for': comparison.get('recommendations', {}),
                'overall_winner': comparison.get('winner', None)
            }
            
        except Exception as e:
            logger.error(f"Error comparing hotels: {str(e)}")
            return {'error': str(e)}
    
    def _get_user_profile(self, user_id: str) -> Dict[str, Any]:
        """Get user's travel profile from DynamoDB"""
        try:
            table = self.dynamodb.Table('user-travel-profiles')
            response = table.get_item(Key={'userId': user_id})
            
            profile = response.get('Item', {})
            
            # Calculate loyalty discount
            loyalty_tiers = {
                'bronze': 0.00,
                'silver': 0.05,
                'gold': 0.10,
                'platinum': 0.15
            }
            profile['loyaltyDiscount'] = loyalty_tiers.get(profile.get('loyaltyTier', 'bronze'), 0)
            
            return profile
            
        except Exception as e:
            logger.error(f"Error getting user profile: {str(e)}")
            return {}
    
    def _get_available_hotels(
        self,
        destination: str,
        check_in: date,
        check_out: date,
        guests: int
    ) -> List[Dict[str, Any]]:
        """Get available hotels (mock data for now)"""
        # In production, this would call the hotel service API
        return [
            {
                'hotelId': 'hotel-001',
                'name': 'Grand Luxury Hotel',
                'location': {'city': destination, 'address': '123 Main St'},
                'category': 'luxury',
                'starRating': 5,
                'basePricePerNight': 250,
                'amenities': ['wifi', 'pool', 'gym', 'spa', 'restaurant'],
                'images': ['url1', 'url2']
            },
            {
                'hotelId': 'hotel-002',
                'name': 'Business Center Hotel',
                'location': {'city': destination, 'address': '456 Business Ave'},
                'category': 'business',
                'starRating': 4,
                'basePricePerNight': 150,
                'amenities': ['wifi', 'gym', 'business_center', 'restaurant'],
                'images': ['url1', 'url2']
            },
            {
                'hotelId': 'hotel-003',
                'name': 'Budget Inn',
                'location': {'city': destination, 'address': '789 Economy Rd'},
                'category': 'budget',
                'starRating': 3,
                'basePricePerNight': 75,
                'amenities': ['wifi', 'parking'],
                'images': ['url1']
            }
        ]
    
    def _generate_ai_hotel_recommendations(
        self,
        hotels: List[Dict[str, Any]],
        travel_purpose: str,
        user_profile: Dict[str, Any],
        destination: str,
        nights: int,
        guests: int
    ) -> List[Dict[str, Any]]:
        """Use Bedrock to generate personalized recommendations"""
        
        prompt = f"""You are a travel expert. Recommend the best hotels for this traveler.

Destination: {destination}
Duration: {nights} nights
Guests: {guests}
Travel Purpose: {travel_purpose}

User Profile:
{json.dumps(user_profile, indent=2)}

Available Hotels:
{json.dumps(hotels, indent=2)}

Task: Select top 3 hotels that best match the traveler's needs. For each, explain:
1. Why it's perfect for their travel purpose
2. Key amenities that match their preferences
3. Value for money
4. Any special features

Return JSON:
[
  {{
    "hotelId": "...",
    "name": "...",
    "totalPrice": ...,
    "reason": "Detailed explanation why this hotel is recommended",
    "highlights": ["feature1", "feature2"],
    "perfectFor": "Who this hotel is best for"
  }}
]
"""
        
        try:
            response = self.bedrock.invoke_model(
                modelId=self.model_id,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 2000,
                    "messages": [{"role": "user", "content": prompt}]
                })
            )
            
            result = json.loads(response['body'].read())
            content = result['content'][0]['text']
            
            # Parse JSON
            import re
            json_match = re.search(r'\[.*\]', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group())
                
        except Exception as e:
            logger.error(f"Bedrock error: {str(e)}")
        
        # Fallback
        return hotels[:3]
    
    def _generate_ai_itinerary(
        self,
        destination: str,
        duration_days: int,
        travel_purpose: str,
        interests: List[str],
        budget_total: Optional[float],
        user_profile: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate complete itinerary using Bedrock"""
        
        prompt = f"""Create a detailed {duration_days}-day itinerary for {destination}.

Travel Purpose: {travel_purpose}
Interests: {', '.join(interests)}
Budget: ${budget_total if budget_total else 'Flexible'}

User Profile:
{json.dumps(user_profile, indent=2)}

Create day-by-day plan including:
- Morning, afternoon, evening activities
- Restaurant recommendations
- Transportation tips
- Estimated costs
- Insider tips

Return JSON format with daily breakdown.
"""
        
        try:
            response = self.bedrock.invoke_model(
                modelId=self.model_id,
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 3000,
                    "messages": [{"role": "user", "content": prompt}]
                })
            )
            
            result = json.loads(response['body'].read())
            content = result['content'][0]['text']
            
            # Parse JSON
            import re
            json_match = re.search(r'\{.*\}', content, re.DOTALL)
            if json_match:
                return json.loads(json_match.group())
                
        except Exception as e:
            logger.error(f"Bedrock itinerary error: {str(e)}")
        
        return {'days': [], 'total_cost': 0}
    
    def _generate_recommendation_message(self, travel_purpose: str, count: int) -> str:
        """Generate personalized message"""
        messages = {
            'business': f"Found {count} business-friendly hotels with excellent meeting facilities",
            'romantic': f"Discovered {count} romantic getaways perfect for couples",
            'family': f"Selected {count} family-friendly hotels with great amenities for kids",
            'adventure': f"Found {count} hotels perfect for adventure seekers",
            'leisure': f"Recommended {count} relaxing hotels for your vacation"
        }
        return messages.get(travel_purpose, f"Found {count} great hotels for your trip")
    
    def _get_available_packages(
        self,
        destination: str,
        travel_purpose: str,
        duration_nights: int
    ) -> List[Dict[str, Any]]:
        """Get available packages (mock)"""
        return [
            {
                'packageId': 'pkg-001',
                'name': f'{destination} {travel_purpose.title()} Package',
                'description': f'{duration_nights}-night stay with activities',
                'pricePerPerson': 500,
                'includedActivities': ['City tour', 'Museum visit', 'Dinner cruise'],
                'hotelCategory': 'luxury'
            }
        ]
    
    def _get_hotel_details(self, hotel_id: str) -> Dict[str, Any]:
        """Get hotel details (mock)"""
        return {
            'hotelId': hotel_id,
            'name': f'Hotel {hotel_id}',
            'starRating': 4,
            'basePricePerNight': 150
        }
    
    def _get_hotels_for_day(
        self,
        destination: str,
        date: str,
        budget: Optional[float]
    ) -> List[Dict[str, Any]]:
        """Get hotels for specific day"""
        return []
    
    def _generate_ai_hotel_comparison(
        self,
        hotels: List[Dict[str, Any]],
        travel_purpose: str,
        priorities: List[str]
    ) -> Dict[str, Any]:
        """AI comparison of hotels"""
        return {
            'winner': hotels[0]['hotelId'] if hotels else None,
            'recommendations': {}
        }
