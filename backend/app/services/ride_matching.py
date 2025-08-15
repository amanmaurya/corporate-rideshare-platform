from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from app.models.ride import Ride, RideRequest
from app.models.user import User
from app.services.location import location_service
from app.schemas.ride import RideMatch
from datetime import datetime, timedelta

class RideMatchingService:
    def __init__(self, db: Session):
        self.db = db

    def find_matching_rides(self, user_id: str, pickup_lat: float, pickup_lon: float,
                           dest_lat: float, dest_lon: float, scheduled_time: Optional[datetime] = None,
                           max_distance: float = 5.0, max_results: int = 10) -> List[RideMatch]:
        """Find matching rides for a user"""

        # Get user's company
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return []

        # Base query for available rides
        query = self.db.query(Ride).filter(
            Ride.company_id == user.company_id,
            Ride.status == "pending",
            Ride.current_passengers < Ride.max_passengers,
            Ride.rider_id != user_id
        )

        # Filter by time if specified
        if scheduled_time:
            time_window = timedelta(minutes=30)  # 30 minute window
            query = query.filter(
                Ride.scheduled_time >= scheduled_time - time_window,
                Ride.scheduled_time <= scheduled_time + time_window
            )

        available_rides = query.all()
        matches = []

        for ride in available_rides:
            # Calculate compatibility
            compatibility = location_service.get_route_compatibility(
                (pickup_lat, pickup_lon),
                (dest_lat, dest_lon),
                (ride.pickup_latitude, ride.pickup_longitude),
                (ride.destination_latitude, ride.destination_longitude)
            )

            # Check if within acceptable distance
            pickup_distance = location_service.calculate_distance(
                pickup_lat, pickup_lon, ride.pickup_latitude, ride.pickup_longitude
            )

            if pickup_distance <= max_distance and compatibility > 0.5:
                # Get driver info
                driver = self.db.query(User).filter(User.id == ride.driver_id).first()

                match = RideMatch(
                    ride_id=ride.id,
                    driver_name=driver.name if driver else "Unknown",
                    driver_phone=driver.phone if driver else "",
                    pickup_time=ride.scheduled_time or datetime.now(),
                    distance_to_pickup=pickup_distance,
                    compatibility_score=compatibility
                )
                matches.append(match)

        # Sort by compatibility score and distance
        matches.sort(key=lambda x: (x.compatibility_score, -x.distance_to_pickup), reverse=True)

        return matches[:max_results]

    def find_potential_passengers(self, ride_id: str, max_distance: float = 5.0) -> List[User]:
        """Find potential passengers for a ride"""

        ride = self.db.query(Ride).filter(Ride.id == ride_id).first()
        if not ride:
            return []

        # Find users in the same company who might be interested
        potential_passengers = self.db.query(User).filter(
            User.company_id == ride.company_id,
            User.id != ride.rider_id,
            User.is_active == True
        ).all()

        compatible_users = []
        for user in potential_passengers:
            if user.latitude and user.longitude:
                distance = location_service.calculate_distance(
                    ride.pickup_latitude, ride.pickup_longitude,
                    user.latitude, user.longitude
                )
                if distance <= max_distance:
                    compatible_users.append(user)

        return compatible_users

    def calculate_estimated_fare(self, distance: float, duration: int, base_rate: float = 2.0) -> float:
        """Calculate estimated fare for a ride"""
        # Simple fare calculation: base rate + distance rate + time rate
        distance_rate = 1.5  # per km
        time_rate = 0.5     # per minute

        fare = base_rate + (distance * distance_rate) + (duration * time_rate)
        return round(fare, 2)
