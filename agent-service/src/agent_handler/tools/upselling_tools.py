"""
AI Upselling Tools

Revenue maximization through intelligent upselling and cross-selling.
"""

import boto3
import json
import logging
from typing import List, Dict, Any, Optional
from decimal import Decimal
from strands import tool

logger = logging.getLogger()


class UpsellingTools:
    """
    AI-powered upselling and revenue optimization
    
    Features:
    - Room upgrade suggestions
    - Add-on service recommendations
    - Extended stay discounts
    - Premium feature upsells
    - Travel protection offers
    """
    
    def __init__(self, hotel_api_url: str, bedrock_model_id: str, bedrock_region: str = 'us-east-1'):
        """
        Initialize Upselling Tools
        
        Args:
            hotel_api_url: Hotel Service API URL
            bedrock_model_id: Bedrock model for AI recommendations
            bedrock_region: AWS region for Bedrock (default: us-east-1)
        """
        self.hotel_api_url = hotel_api_url.rstrip('/')
        self.bedrock_region = bedrock_region
        self.bedrock = boto3.client('bedrock-runtime', region_name=bedrock_region)
        self.model_id = bedrock_model_id
    
    @tool(description="Suggest room upgrades with compelling value propositions")
    def suggest_room_upgrade(
        self,
        current_room_type: str,
        hotel_id: str,
        travel_purpose: str,
        guests: int,
        nights: int
    ) -> Dict[str, Any]:
        """
        Recommend room upgrades based on travel purpose
        
        Args:
            current_room_type: Currently selected room type
            hotel_id: Hotel identifier
            travel_purpose: Why traveling (romantic, business, family)
            guests: Number of guests
            nights: Number of nights
            
        Returns:
            Upgrade options with value propositions
            
        Example:
            suggest_room_upgrade(
                current_room_type="Standard Room",
                hotel_id="hotel-001",
                travel_purpose="romantic",
                guests=2,
                nights=3
            )
        """
        try:
            logger.info(f"Suggesting room upgrades for {current_room_type}")
            
            # Get available room types (mock data)
            available_rooms = self._get_room_types(hotel_id)
            
            # Filter upgrades (rooms better than current)
            room_hierarchy = ['standard', 'deluxe', 'suite', 'penthouse']
            current_level = self._get_room_level(current_room_type)
            
            upgrades = [
                room for room in available_rooms
                if self._get_room_level(room['type']) > current_level
            ]
            
            # Generate AI-powered value propositions
            for upgrade in upgrades:
                price_diff = upgrade['pricePerNight'] - self._get_current_room_price(current_room_type)
                total_diff = price_diff * nights
                
                upgrade['priceDifference'] = price_diff
                upgrade['totalUpgradeCost'] = total_diff
                upgrade['valueProposition'] = self._generate_upgrade_value_prop(
                    upgrade=upgrade,
                    travel_purpose=travel_purpose,
                    price_diff=price_diff
                )
                upgrade['features'] = self._get_upgrade_features(upgrade['type'])
            
            # Sort by value (best value first)
            upgrades.sort(key=lambda x: x['totalUpgradeCost'])
            
            return {
                'currentRoom': current_room_type,
                'upgrades': upgrades,
                'bestValue': upgrades[0] if upgrades else None,
                'message': self._generate_upgrade_message(travel_purpose, len(upgrades))
            }
            
        except Exception as e:
            logger.error(f"Error suggesting room upgrades: {str(e)}")
            return {'error': str(e), 'upgrades': []}
    
    @tool(description="Recommend add-on services based on travel purpose")
    def suggest_addons(
        self,
        hotel_id: str,
        travel_purpose: str,
        guests: int,
        nights: int,
        budget_flexibility: str = "moderate"  # low, moderate, high
    ) -> Dict[str, Any]:
        """
        Suggest relevant add-on services
        
        Args:
            hotel_id: Hotel identifier
            travel_purpose: Purpose of travel
            guests: Number of guests
            nights: Number of nights
            budget_flexibility: How flexible is the budget
            
        Returns:
            Personalized add-on recommendations
            
        Example:
            suggest_addons(
                hotel_id="hotel-001",
                travel_purpose="romantic",
                guests=2,
                nights=3,
                budget_flexibility="high"
            )
        """
        try:
            logger.info(f"Suggesting add-ons for {travel_purpose} trip")
            
            # Get available add-ons
            all_addons = self._get_available_addons(hotel_id)
            
            # Filter by travel purpose
            relevant_addons = self._filter_addons_by_purpose(
                addons=all_addons,
                travel_purpose=travel_purpose,
                guests=guests
            )
            
            # Apply budget filter
            if budget_flexibility == "low":
                relevant_addons = [a for a in relevant_addons if a['price'] < 100]
            elif budget_flexibility == "moderate":
                relevant_addons = [a for a in relevant_addons if a['price'] < 300]
            
            # Calculate bundle discounts
            if len(relevant_addons) >= 2:
                bundle_discount = 0.15  # 15% off when buying 2+ add-ons
                for addon in relevant_addons:
                    addon['bundlePrice'] = addon['price'] * (1 - bundle_discount)
                    addon['savings'] = addon['price'] * bundle_discount
            
            # Generate personalized pitch
            for addon in relevant_addons:
                addon['pitch'] = self._generate_addon_pitch(
                    addon=addon,
                    travel_purpose=travel_purpose
                )
            
            # Sort by relevance
            relevant_addons.sort(key=lambda x: x.get('relevanceScore', 0), reverse=True)
            
            return {
                'addons': relevant_addons[:5],  # Top 5
                'bundleDiscount': 0.15 if len(relevant_addons) >= 2 else 0,
                'totalSavings': sum(a.get('savings', 0) for a in relevant_addons),
                'message': self._generate_addon_message(travel_purpose, len(relevant_addons))
            }
            
        except Exception as e:
            logger.error(f"Error suggesting add-ons: {str(e)}")
            return {'error': str(e), 'addons': []}
    
    @tool(description="Offer extended stay discounts to increase booking value")
    def suggest_extended_stay(
        self,
        current_nights: int,
        check_in: str,
        check_out: str,
        hotel_id: str,
        current_price_per_night: float
    ) -> Dict[str, Any]:
        """
        Suggest extending stay with discounts
        
        Args:
            current_nights: Currently planned nights
            check_in: Check-in date
            check_out: Check-out date
            hotel_id: Hotel identifier
            current_price_per_night: Current nightly rate
            
        Returns:
            Extended stay options with savings
            
        Example:
            suggest_extended_stay(
                current_nights=3,
                check_in="2024-06-15",
                check_out="2024-06-18",
                hotel_id="hotel-001",
                current_price_per_night=200
            )
        """
        try:
            logger.info(f"Suggesting extended stay from {current_nights} nights")
            
            # Calculate discount tiers
            discount_tiers = {
                5: 0.10,   # 10% off for 5+ nights
                7: 0.15,   # 15% off for 7+ nights
                14: 0.20,  # 20% off for 14+ nights
                30: 0.25   # 25% off for 30+ nights
            }
            
            options = []
            
            for nights, discount in discount_tiers.items():
                if nights > current_nights:
                    extra_nights = nights - current_nights
                    
                    # Calculate pricing
                    current_total = current_price_per_night * current_nights
                    extended_total = current_price_per_night * nights * (1 - discount)
                    savings = (current_price_per_night * nights) - extended_total
                    
                    options.append({
                        'nights': nights,
                        'extraNights': extra_nights,
                        'discount': discount * 100,
                        'pricePerNight': current_price_per_night * (1 - discount),
                        'totalPrice': extended_total,
                        'savings': savings,
                        'valueProposition': self._generate_extended_stay_pitch(
                            extra_nights=extra_nights,
                            savings=savings,
                            discount=discount * 100
                        )
                    })
            
            return {
                'currentNights': current_nights,
                'options': options,
                'bestValue': max(options, key=lambda x: x['savings']) if options else None,
                'message': f"Stay longer and save! Extend your trip to unlock discounts up to 25%"
            }
            
        except Exception as e:
            logger.error(f"Error suggesting extended stay: {str(e)}")
            return {'error': str(e), 'options': []}
    
    @tool(description="Suggest premium features like ocean view, high floor, corner room")
    def suggest_premium_features(
        self,
        room_type: str,
        hotel_id: str,
        travel_purpose: str,
        budget_per_night: float
    ) -> Dict[str, Any]:
        """
        Recommend premium room features
        
        Args:
            room_type: Selected room type
            hotel_id: Hotel identifier
            travel_purpose: Purpose of travel
            budget_per_night: Budget per night
            
        Returns:
            Premium feature options
            
        Example:
            suggest_premium_features(
                room_type="Deluxe Room",
                hotel_id="hotel-001",
                travel_purpose="romantic",
                budget_per_night=300
            )
        """
        try:
            logger.info(f"Suggesting premium features for {room_type}")
            
            # Available premium features
            features = [
                {
                    'feature': 'Ocean View',
                    'priceIncrease': 50,
                    'description': 'Wake up to breathtaking ocean views',
                    'relevance': {'romantic': 10, 'leisure': 9, 'business': 5}
                },
                {
                    'feature': 'High Floor (15+)',
                    'priceIncrease': 30,
                    'description': 'Enjoy panoramic city views and quieter stay',
                    'relevance': {'romantic': 8, 'leisure': 7, 'business': 9}
                },
                {
                    'feature': 'Corner Room',
                    'priceIncrease': 40,
                    'description': 'Extra windows and more natural light',
                    'relevance': {'romantic': 7, 'leisure': 8, 'business': 6}
                },
                {
                    'feature': 'Balcony',
                    'priceIncrease': 60,
                    'description': 'Private outdoor space to relax',
                    'relevance': {'romantic': 10, 'leisure': 9, 'business': 4}
                },
                {
                    'feature': 'Executive Lounge Access',
                    'priceIncrease': 45,
                    'description': 'Complimentary breakfast and evening cocktails',
                    'relevance': {'romantic': 6, 'leisure': 7, 'business': 10}
                }
            ]
            
            # Filter by budget
            affordable_features = [
                f for f in features
                if budget_per_night + f['priceIncrease'] <= budget_per_night * 1.3
            ]
            
            # Sort by relevance to travel purpose
            for feature in affordable_features:
                feature['relevanceScore'] = feature['relevance'].get(travel_purpose, 5)
                feature['pitch'] = self._generate_feature_pitch(
                    feature=feature,
                    travel_purpose=travel_purpose
                )
            
            affordable_features.sort(key=lambda x: x['relevanceScore'], reverse=True)
            
            return {
                'features': affordable_features,
                'topRecommendation': affordable_features[0] if affordable_features else None,
                'message': f"Enhance your {travel_purpose} experience with these premium features"
            }
            
        except Exception as e:
            logger.error(f"Error suggesting premium features: {str(e)}")
            return {'error': str(e), 'features': []}
    
    @tool(description="Offer travel protection and insurance options")
    def suggest_travel_protection(
        self,
        booking_value: float,
        trip_duration_days: int,
        destination: str,
        travelers: int
    ) -> Dict[str, Any]:
        """
        Recommend travel insurance options
        
        Args:
            booking_value: Total booking value
            trip_duration_days: Trip duration
            destination: Travel destination
            travelers: Number of travelers
            
        Returns:
            Travel protection options
            
        Example:
            suggest_travel_protection(
                booking_value=2000,
                trip_duration_days=7,
                destination="Paris",
                travelers=2
            )
        """
        try:
            logger.info(f"Suggesting travel protection for ${booking_value} booking")
            
            # Calculate insurance tiers
            basic_cost = booking_value * 0.05  # 5% of booking
            standard_cost = booking_value * 0.08  # 8% of booking
            premium_cost = booking_value * 0.12  # 12% of booking
            
            options = [
                {
                    'tier': 'Basic',
                    'cost': basic_cost,
                    'coverage': booking_value,
                    'benefits': [
                        'Trip cancellation coverage',
                        'Medical emergency assistance',
                        '24/7 travel support'
                    ],
                    'recommended': booking_value < 1000
                },
                {
                    'tier': 'Standard',
                    'cost': standard_cost,
                    'coverage': booking_value * 1.5,
                    'benefits': [
                        'Everything in Basic',
                        'Baggage loss/delay coverage',
                        'Travel delay reimbursement',
                        'Emergency evacuation'
                    ],
                    'recommended': 1000 <= booking_value < 3000
                },
                {
                    'tier': 'Premium',
                    'cost': premium_cost,
                    'coverage': booking_value * 2,
                    'benefits': [
                        'Everything in Standard',
                        'Cancel for any reason',
                        'Rental car coverage',
                        'Adventure sports coverage',
                        'Concierge services'
                    ],
                    'recommended': booking_value >= 3000
                }
            ]
            
            # Add value proposition
            for option in options:
                option['valueProposition'] = self._generate_insurance_pitch(
                    tier=option['tier'],
                    cost=option['cost'],
                    coverage=option['coverage'],
                    booking_value=booking_value
                )
            
            # Recommend based on booking value
            recommended = next((o for o in options if o['recommended']), options[1])
            
            return {
                'options': options,
                'recommended': recommended,
                'message': f"Protect your ${booking_value} investment with travel insurance",
                'peace_of_mind': True
            }
            
        except Exception as e:
            logger.error(f"Error suggesting travel protection: {str(e)}")
            return {'error': str(e), 'options': []}
    
    # Helper methods
    
    def _get_room_types(self, hotel_id: str) -> List[Dict[str, Any]]:
        """Get available room types (mock)"""
        return [
            {'type': 'Standard Room', 'pricePerNight': 150, 'size': '300 sq ft'},
            {'type': 'Deluxe Room', 'pricePerNight': 220, 'size': '400 sq ft'},
            {'type': 'Junior Suite', 'pricePerNight': 320, 'size': '550 sq ft'},
            {'type': 'Executive Suite', 'pricePerNight': 450, 'size': '750 sq ft'},
            {'type': 'Penthouse', 'pricePerNight': 800, 'size': '1200 sq ft'}
        ]
    
    def _get_room_level(self, room_type: str) -> int:
        """Get room hierarchy level"""
        levels = {
            'standard': 1,
            'deluxe': 2,
            'junior suite': 3,
            'suite': 4,
            'executive': 5,
            'penthouse': 6
        }
        room_lower = room_type.lower()
        for key, level in levels.items():
            if key in room_lower:
                return level
        return 1
    
    def _get_current_room_price(self, room_type: str) -> float:
        """Get current room price (mock)"""
        prices = {
            'standard': 150,
            'deluxe': 220,
            'suite': 320
        }
        room_lower = room_type.lower()
        for key, price in prices.items():
            if key in room_lower:
                return price
        return 150
    
    def _generate_upgrade_value_prop(
        self,
        upgrade: Dict[str, Any],
        travel_purpose: str,
        price_diff: float
    ) -> str:
        """Generate compelling upgrade value proposition"""
        purpose_messages = {
            'romantic': f"For just ${price_diff} more per night, enjoy {upgrade['size']} of romantic luxury",
            'business': f"Upgrade to {upgrade['type']} for ${price_diff}/night - perfect for work and relaxation",
            'family': f"Give your family more space! Only ${price_diff} more per night for {upgrade['size']}",
            'leisure': f"Treat yourself to {upgrade['type']} - just ${price_diff} extra per night"
        }
        return purpose_messages.get(travel_purpose, f"Upgrade for only ${price_diff} more per night")
    
    def _get_upgrade_features(self, room_type: str) -> List[str]:
        """Get features for room type"""
        features = {
            'Deluxe Room': ['King bed', 'City view', 'Premium toiletries', 'Coffee maker'],
            'Junior Suite': ['Separate living area', 'Sofa bed', 'Mini bar', 'Bathrobe'],
            'Executive Suite': ['Full kitchen', 'Dining area', 'Work desk', 'Premium amenities'],
            'Penthouse': ['Panoramic views', 'Private terrace', 'Butler service', 'Jacuzzi']
        }
        return features.get(room_type, [])
    
    def _generate_upgrade_message(self, travel_purpose: str, count: int) -> str:
        """Generate upgrade message"""
        return f"Found {count} upgrade options perfect for your {travel_purpose} trip"
    
    def _get_available_addons(self, hotel_id: str) -> List[Dict[str, Any]]:
        """Get available add-ons (mock)"""
        return [
            {
                'id': 'spa-package',
                'name': 'Couples Spa Package',
                'price': 250,
                'description': '90-min massage for two + champagne',
                'category': 'wellness',
                'relevanceScore': 0
            },
            {
                'id': 'airport-transfer',
                'name': 'Private Airport Transfer',
                'price': 80,
                'description': 'Luxury car pickup and drop-off',
                'category': 'transportation',
                'relevanceScore': 0
            },
            {
                'id': 'romantic-dinner',
                'name': 'Private Beach Dinner',
                'price': 350,
                'description': 'Candlelit dinner on the beach',
                'category': 'dining',
                'relevanceScore': 0
            },
            {
                'id': 'city-tour',
                'name': 'Private City Tour',
                'price': 150,
                'description': '4-hour guided city exploration',
                'category': 'activities',
                'relevanceScore': 0
            },
            {
                'id': 'breakfast-package',
                'name': 'Daily Breakfast',
                'price': 35,
                'description': 'Full breakfast buffet daily',
                'category': 'dining',
                'relevanceScore': 0
            }
        ]
    
    def _filter_addons_by_purpose(
        self,
        addons: List[Dict[str, Any]],
        travel_purpose: str,
        guests: int
    ) -> List[Dict[str, Any]]:
        """Filter add-ons by travel purpose"""
        relevance_map = {
            'romantic': ['spa-package', 'romantic-dinner', 'airport-transfer'],
            'business': ['airport-transfer', 'breakfast-package'],
            'family': ['city-tour', 'breakfast-package', 'airport-transfer'],
            'leisure': ['spa-package', 'city-tour', 'breakfast-package']
        }
        
        relevant_ids = relevance_map.get(travel_purpose, [])
        filtered = [a for a in addons if a['id'] in relevant_ids]
        
        # Set relevance scores
        for i, addon in enumerate(filtered):
            addon['relevanceScore'] = len(filtered) - i
        
        return filtered
    
    def _generate_addon_pitch(self, addon: Dict[str, Any], travel_purpose: str) -> str:
        """Generate addon pitch"""
        return f"Enhance your {travel_purpose} experience with {addon['name']}"
    
    def _generate_addon_message(self, travel_purpose: str, count: int) -> str:
        """Generate addon message"""
        return f"Personalized {count} add-ons for your {travel_purpose} trip"
    
    def _generate_extended_stay_pitch(
        self,
        extra_nights: int,
        savings: float,
        discount: float
    ) -> str:
        """Generate extended stay pitch"""
        return f"Stay {extra_nights} more nights and save ${savings:.2f} ({discount}% off)"
    
    def _generate_feature_pitch(
        self,
        feature: Dict[str, Any],
        travel_purpose: str
    ) -> str:
        """Generate feature pitch"""
        return f"{feature['description']} - Perfect for {travel_purpose} travelers"
    
    def _generate_insurance_pitch(
        self,
        tier: str,
        cost: float,
        coverage: float,
        booking_value: float
    ) -> str:
        """Generate insurance pitch"""
        return f"Protect your ${booking_value} investment for just ${cost:.2f} with {tier} coverage"
