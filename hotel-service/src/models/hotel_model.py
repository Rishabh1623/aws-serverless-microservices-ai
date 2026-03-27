"""
Hotel and Room Data Models

Defines the structure for hotels, rooms, and bookings in the travel platform.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, date
from decimal import Decimal
from enum import Enum


class RoomType(Enum):
    """Room types available"""
    STANDARD = "standard"
    DELUXE = "deluxe"
    SUITE = "suite"
    PRESIDENTIAL = "presidential"
    FAMILY = "family"
    ACCESSIBLE = "accessible"


class AmenityType(Enum):
    """Hotel amenities"""
    WIFI = "wifi"
    POOL = "pool"
    GYM = "gym"
    SPA = "spa"
    RESTAURANT = "restaurant"
    BAR = "bar"
    PARKING = "parking"
    AIRPORT_SHUTTLE = "airport_shuttle"
    BUSINESS_CENTER = "business_center"
    PET_FRIENDLY = "pet_friendly"
    BEACH_ACCESS = "beach_access"
    SKI_ACCESS = "ski_access"


class HotelCategory(Enum):
    """Hotel categories for personalization"""
    LUXURY = "luxury"
    BUSINESS = "business"
    BUDGET = "budget"
    BOUTIQUE = "boutique"
    RESORT = "resort"
    FAMILY = "family"
    ROMANTIC = "romantic"
    ADVENTURE = "adventure"


class TravelPurpose(Enum):
    """Why user is traveling - for personalization"""
    BUSINESS = "business"
    LEISURE = "leisure"
    FAMILY_VACATION = "family_vacation"
    ROMANTIC_GETAWAY = "romantic_getaway"
    ADVENTURE = "adventure"
    WELLNESS = "wellness"
    CULTURAL = "cultural"
    BEACH = "beach"
    SKIING = "skiing"
    CITY_BREAK = "city_break"


class Hotel:
    """Hotel entity with all details"""
    
    def __init__(
        self,
        hotel_id: str,
        name: str,
        location: Dict[str, Any],
        category: HotelCategory,
        star_rating: int,
        description: str,
        amenities: List[AmenityType],
        images: List[str],
        base_price_per_night: Decimal,
        total_rooms: int,
        check_in_time: str = "15:00",
        check_out_time: str = "11:00",
        cancellation_policy: str = "free_cancellation_24h",
        contact: Dict[str, str] = None
    ):
        self.hotel_id = hotel_id
        self.name = name
        self.location = location  # {city, country, address, lat, lng, nearby_attractions}
        self.category = category
        self.star_rating = star_rating  # 1-5
        self.description = description
        self.amenities = amenities
        self.images = images
        self.base_price_per_night = base_price_per_night
        self.total_rooms = total_rooms
        self.check_in_time = check_in_time
        self.check_out_time = check_out_time
        self.cancellation_policy = cancellation_policy
        self.contact = contact or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for DynamoDB"""
        return {
            'hotelId': self.hotel_id,
            'name': self.name,
            'location': self.location,
            'category': self.category.value,
            'starRating': self.star_rating,
            'description': self.description,
            'amenities': [a.value for a in self.amenities],
            'images': self.images,
            'basePricePerNight': float(self.base_price_per_night),
            'totalRooms': self.total_rooms,
            'checkInTime': self.check_in_time,
            'checkOutTime': self.check_out_time,
            'cancellationPolicy': self.cancellation_policy,
            'contact': self.contact
        }


class Room:
    """Room entity with availability and pricing"""
    
    def __init__(
        self,
        room_id: str,
        hotel_id: str,
        room_number: str,
        room_type: RoomType,
        capacity: int,
        bed_configuration: str,
        size_sqm: int,
        amenities: List[str],
        base_price: Decimal,
        images: List[str],
        floor: int = 1,
        view: str = "city"
    ):
        self.room_id = room_id
        self.hotel_id = hotel_id
        self.room_number = room_number
        self.room_type = room_type
        self.capacity = capacity  # Max guests
        self.bed_configuration = bed_configuration  # "1 King" or "2 Queens"
        self.size_sqm = size_sqm
        self.amenities = amenities
        self.base_price = base_price
        self.images = images
        self.floor = floor
        self.view = view  # city, ocean, mountain, garden
    
    def calculate_dynamic_price(
        self,
        check_in: date,
        check_out: date,
        occupancy_rate: float,
        season_multiplier: float = 1.0,
        event_multiplier: float = 1.0
    ) -> Decimal:
        """
        Calculate dynamic price based on:
        - Occupancy rate (higher occupancy = higher price)
        - Season (peak/off-peak)
        - Local events (conferences, festivals)
        - Day of week (weekends more expensive)
        - Advance booking (early bird discount)
        """
        nights = (check_out - check_in).days
        
        # Base price
        total_price = self.base_price * nights
        
        # Occupancy-based pricing (80%+ occupancy = 20% increase)
        if occupancy_rate > 0.8:
            total_price *= Decimal('1.2')
        elif occupancy_rate > 0.6:
            total_price *= Decimal('1.1')
        elif occupancy_rate < 0.3:
            total_price *= Decimal('0.9')  # Discount for low occupancy
        
        # Season multiplier
        total_price *= Decimal(str(season_multiplier))
        
        # Event multiplier
        total_price *= Decimal(str(event_multiplier))
        
        # Weekend premium (Friday-Sunday)
        weekend_nights = sum(
            1 for i in range(nights)
            if (check_in + timedelta(days=i)).weekday() >= 4
        )
        if weekend_nights > 0:
            total_price *= Decimal('1.05')
        
        # Early bird discount (30+ days advance)
        from datetime import timedelta
        days_advance = (check_in - date.today()).days
        if days_advance >= 30:
            total_price *= Decimal('0.9')  # 10% discount
        
        return total_price.quantize(Decimal('0.01'))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'roomId': self.room_id,
            'hotelId': self.hotel_id,
            'roomNumber': self.room_number,
            'roomType': self.room_type.value,
            'capacity': self.capacity,
            'bedConfiguration': self.bed_configuration,
            'sizeSqm': self.size_sqm,
            'amenities': self.amenities,
            'basePrice': float(self.base_price),
            'images': self.images,
            'floor': self.floor,
            'view': self.view
        }


class Booking:
    """Booking/Reservation entity"""
    
    def __init__(
        self,
        booking_id: str,
        user_id: str,
        hotel_id: str,
        room_id: str,
        check_in: date,
        check_out: date,
        guests: int,
        total_price: Decimal,
        status: str = "confirmed",
        special_requests: str = "",
        guest_details: Dict[str, Any] = None,
        payment_status: str = "pending"
    ):
        self.booking_id = booking_id
        self.user_id = user_id
        self.hotel_id = hotel_id
        self.room_id = room_id
        self.check_in = check_in
        self.check_out = check_out
        self.guests = guests
        self.total_price = total_price
        self.status = status  # confirmed, cancelled, completed
        self.special_requests = special_requests
        self.guest_details = guest_details or {}
        self.payment_status = payment_status
        self.created_at = datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'bookingId': self.booking_id,
            'userId': self.user_id,
            'hotelId': self.hotel_id,
            'roomId': self.room_id,
            'checkIn': self.check_in.isoformat(),
            'checkOut': self.check_out.isoformat(),
            'guests': self.guests,
            'totalPrice': float(self.total_price),
            'status': self.status,
            'specialRequests': self.special_requests,
            'guestDetails': self.guest_details,
            'paymentStatus': self.payment_status,
            'createdAt': self.created_at.isoformat()
        }


class TravelPackage:
    """Complete travel package with hotel + activities"""
    
    def __init__(
        self,
        package_id: str,
        name: str,
        description: str,
        hotel_id: str,
        duration_nights: int,
        included_activities: List[Dict[str, Any]],
        price_per_person: Decimal,
        min_guests: int = 1,
        max_guests: int = 4,
        category: str = "leisure",
        images: List[str] = None
    ):
        self.package_id = package_id
        self.name = name
        self.description = description
        self.hotel_id = hotel_id
        self.duration_nights = duration_nights
        self.included_activities = included_activities
        self.price_per_person = price_per_person
        self.min_guests = min_guests
        self.max_guests = max_guests
        self.category = category
        self.images = images or []
    
    def calculate_package_price(self, num_guests: int) -> Decimal:
        """Calculate total package price with group discount"""
        base_total = self.price_per_person * num_guests
        
        # Group discount
        if num_guests >= 4:
            base_total *= Decimal('0.85')  # 15% discount
        elif num_guests >= 2:
            base_total *= Decimal('0.90')  # 10% discount
        
        return base_total.quantize(Decimal('0.01'))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'packageId': self.package_id,
            'name': self.name,
            'description': self.description,
            'hotelId': self.hotel_id,
            'durationNights': self.duration_nights,
            'includedActivities': self.included_activities,
            'pricePerPerson': float(self.price_per_person),
            'minGuests': self.min_guests,
            'maxGuests': self.max_guests,
            'category': self.category,
            'images': self.images
        }


class UserTravelProfile:
    """User's travel preferences for personalization"""
    
    def __init__(
        self,
        user_id: str,
        preferred_destinations: List[str] = None,
        preferred_hotel_categories: List[HotelCategory] = None,
        budget_range: Dict[str, int] = None,
        travel_purposes: List[TravelPurpose] = None,
        preferred_amenities: List[AmenityType] = None,
        dietary_restrictions: List[str] = None,
        accessibility_needs: List[str] = None,
        loyalty_tier: str = "bronze",
        past_bookings: List[str] = None
    ):
        self.user_id = user_id
        self.preferred_destinations = preferred_destinations or []
        self.preferred_hotel_categories = preferred_hotel_categories or []
        self.budget_range = budget_range or {'min': 50, 'max': 500}
        self.travel_purposes = travel_purposes or []
        self.preferred_amenities = preferred_amenities or []
        self.dietary_restrictions = dietary_restrictions or []
        self.accessibility_needs = accessibility_needs or []
        self.loyalty_tier = loyalty_tier  # bronze, silver, gold, platinum
        self.past_bookings = past_bookings or []
    
    def get_loyalty_discount(self) -> Decimal:
        """Get discount based on loyalty tier"""
        discounts = {
            'bronze': Decimal('0.00'),
            'silver': Decimal('0.05'),
            'gold': Decimal('0.10'),
            'platinum': Decimal('0.15')
        }
        return discounts.get(self.loyalty_tier, Decimal('0.00'))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'userId': self.user_id,
            'preferredDestinations': self.preferred_destinations,
            'preferredHotelCategories': [c.value for c in self.preferred_hotel_categories],
            'budgetRange': self.budget_range,
            'travelPurposes': [p.value for p in self.travel_purposes],
            'preferredAmenities': [a.value for a in self.preferred_amenities],
            'dietaryRestrictions': self.dietary_restrictions,
            'accessibilityNeeds': self.accessibility_needs,
            'loyaltyTier': self.loyalty_tier,
            'pastBookings': self.past_bookings
        }
