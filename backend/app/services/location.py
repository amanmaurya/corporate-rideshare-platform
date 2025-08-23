import math
from typing import Tuple, List, Optional, Dict
from geopy.distance import geodesic
from geopy.geocoders import Nominatim

class LocationService:
    def __init__(self):
        self.geolocator = Nominatim(user_agent="corporate-rideshare")

    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates in kilometers"""
        return geodesic((lat1, lon1), (lat2, lon2)).kilometers

    @staticmethod
    def calculate_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate bearing between two coordinates"""
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])

        dlon = lon2 - lon1
        y = math.sin(dlon) * math.cos(lat2)
        x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dlon)

        bearing = math.atan2(y, x)
        bearing = math.degrees(bearing)
        bearing = (bearing + 360) % 360

        return bearing

    def geocode_address(self, address: str) -> Optional[Tuple[float, float]]:
        """Convert address to coordinates"""
        try:
            location = self.geolocator.geocode(address)
            if location:
                return location.latitude, location.longitude
            return None
        except Exception:
            return None

    def reverse_geocode(self, latitude: float, longitude: float) -> Optional[str]:
        """Convert coordinates to address"""
        try:
            location = self.geolocator.reverse(f"{latitude}, {longitude}")
            if location:
                return location.address
            return None
        except Exception:
            return None

    @staticmethod
    def is_within_radius(center_lat: float, center_lon: float, 
                        point_lat: float, point_lon: float, radius_km: float) -> bool:
        """Check if point is within radius of center"""
        distance = LocationService.calculate_distance(center_lat, center_lon, point_lat, point_lon)
        return distance <= radius_km

    @staticmethod
    def get_route_compatibility(pickup1: Tuple[float, float], dest1: Tuple[float, float],
                               pickup2: Tuple[float, float], dest2: Tuple[float, float]) -> float:
        """Calculate route compatibility score (0-1)"""
        # Calculate if routes are compatible
        pickup_distance = LocationService.calculate_distance(pickup1[0], pickup1[1], pickup2[0], pickup2[1])
        dest_distance = LocationService.calculate_distance(dest1[0], dest1[1], dest2[0], dest2[1])

        # Maximum acceptable distance for pickup and destination (in km)
        max_pickup_distance = 2.0  # 2km
        max_dest_distance = 2.0    # 2km

        # Calculate compatibility score
        pickup_score = max(0, 1 - (pickup_distance / max_pickup_distance))
        dest_score = max(0, 1 - (dest_distance / max_dest_distance))

        return (pickup_score + dest_score) / 2

    @staticmethod
    def find_nearby_points(center_lat: float, center_lon: float, 
                           points: List[Dict], radius_km: float) -> List[Dict]:
        """Find all points within radius of center"""
        nearby_points = []
        
        for point in points:
            point_lat = point.get('latitude')
            point_lon = point.get('longitude')
            
            if point_lat and point_lon:
                if LocationService.is_within_radius(center_lat, center_lon, point_lat, point_lon, radius_km):
                    # Add distance to the point data
                    point_copy = point.copy()
                    point_copy['distance_km'] = LocationService.calculate_distance(
                        center_lat, center_lon, point_lat, point_lon
                    )
                    nearby_points.append(point_copy)
        
        # Sort by distance (closest first)
        nearby_points.sort(key=lambda x: x['distance_km'])
        return nearby_points

    @staticmethod
    def calculate_fare(distance_km: float, duration_minutes: int = 0, 
                      base_rate: float = 2.0, distance_rate: float = 1.5, 
                      time_rate: float = 0.5) -> float:
        """Calculate fare for a ride"""
        fare = base_rate + (distance_km * distance_rate) + (duration_minutes * time_rate)
        return round(fare, 2)

    @staticmethod
    def calculate_estimated_duration(distance_km: float, 
                                   average_speed_kmh: float = 30.0) -> int:
        """Calculate estimated duration for a ride in minutes"""
        duration_hours = distance_km / average_speed_kmh
        duration_minutes = int(duration_hours * 60)
        return duration_minutes

# Initialize global location service
location_service = LocationService()
