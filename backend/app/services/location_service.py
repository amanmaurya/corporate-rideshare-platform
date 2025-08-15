import math
import logging
from typing import Tuple, List, Dict, Optional
from datetime import datetime, timedelta
import asyncio

logger = logging.getLogger(__name__)

class LocationService:
    """Service for handling location-based operations"""
    
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate distance between two points using Haversine formula
        Returns distance in kilometers
        """
        R = 6371  # Earth's radius in kilometers
        
        # Convert to radians
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        # Haversine formula
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        
        return R * c
    
    @staticmethod
    def calculate_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate bearing from point 1 to point 2
        Returns bearing in degrees (0-360)
        """
        # Convert to radians
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlon = lon2 - lon1
        
        # Calculate bearing
        y = math.sin(dlon) * math.cos(lat2)
        x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dlon)
        bearing = math.atan2(y, x)
        
        # Convert to degrees and normalize to 0-360
        bearing = math.degrees(bearing)
        return (bearing + 360) % 360
    
    @staticmethod
    def is_within_radius(center_lat: float, center_lon: float, 
                         point_lat: float, point_lon: float, 
                         radius_km: float) -> bool:
        """Check if a point is within specified radius of center"""
        distance = LocationService.calculate_distance(center_lat, center_lon, point_lat, point_lon)
        return distance <= radius_km
    
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
                    point['distance_km'] = LocationService.calculate_distance(
                        center_lat, center_lon, point_lat, point_lon
                    )
                    nearby_points.append(point)
        
        # Sort by distance (closest first)
        nearby_points.sort(key=lambda x: x['distance_km'])
        return nearby_points
    
    @staticmethod
    def estimate_travel_time(distance_km: float, 
                           traffic_condition: str = "normal",
                           vehicle_type: str = "car") -> int:
        """
        Estimate travel time in minutes
        """
        # Base speeds in km/h for different conditions
        base_speeds = {
            "car": {"normal": 50, "heavy": 30, "light": 70},
            "bike": {"normal": 25, "heavy": 20, "light": 30},
            "walk": {"normal": 5, "heavy": 4, "light": 6}
        }
        
        # Get base speed
        vehicle_speeds = base_speeds.get(vehicle_type, base_speeds["car"])
        speed = vehicle_speeds.get(traffic_condition, vehicle_speeds["normal"])
        
        # Calculate time in minutes
        time_hours = distance_km / speed
        time_minutes = int(time_hours * 60)
        
        # Add buffer for traffic lights, stops, etc.
        buffer_minutes = max(5, int(time_minutes * 0.1))
        
        return time_minutes + buffer_minutes
    
    @staticmethod
    def calculate_fare(distance_km: float, 
                      base_rate: float = 2.0,
                      per_km_rate: float = 1.5,
                      time_multiplier: float = 1.0) -> float:
        """
        Calculate ride fare based on distance and time
        """
        # Base fare + distance-based fare
        fare = base_rate + (distance_km * per_km_rate)
        
        # Apply time multiplier (rush hour, etc.)
        fare *= time_multiplier
        
        # Round to 2 decimal places
        return round(fare, 2)
    
    @staticmethod
    def get_optimal_route(pickup: Tuple[float, float], 
                          destination: Tuple[float, float],
                          waypoints: List[Tuple[float, float]] = None) -> Dict:
        """
        Calculate optimal route between pickup and destination
        Returns route information including distance, time, and waypoints
        """
        pickup_lat, pickup_lon = pickup
        dest_lat, dest_lon = destination
        
        # Calculate direct distance
        direct_distance = LocationService.calculate_distance(
            pickup_lat, pickup_lon, dest_lat, dest_lon
        )
        
        # Calculate direct travel time
        direct_time = LocationService.estimate_travel_time(direct_distance)
        
        # Calculate direct fare
        direct_fare = LocationService.calculate_fare(direct_distance)
        
        route_info = {
            "pickup": {"latitude": pickup_lat, "longitude": pickup_lon},
            "destination": {"latitude": dest_lat, "longitude": dest_lon},
            "waypoints": waypoints or [],
            "total_distance_km": direct_distance,
            "estimated_time_minutes": direct_time,
            "estimated_fare": direct_fare,
            "route_type": "direct"
        }
        
        # If waypoints are provided, calculate route with stops
        if waypoints:
            total_distance = direct_distance
            total_time = direct_time
            
            # Add distance and time for each waypoint
            current_point = pickup
            for waypoint in waypoints:
                wp_lat, wp_lon = waypoint
                leg_distance = LocationService.calculate_distance(
                    current_point[0], current_point[1], wp_lat, wp_lon
                )
                leg_time = LocationService.estimate_travel_time(leg_distance)
                
                total_distance += leg_distance
                total_time += leg_time
                current_point = waypoint
            
            # Update route info
            route_info.update({
                "total_distance_km": round(total_distance, 2),
                "estimated_time_minutes": total_time,
                "estimated_fare": LocationService.calculate_fare(total_distance),
                "route_type": "with_waypoints"
            })
        
        return route_info
    
    @staticmethod
    def validate_coordinates(lat: float, lon: float) -> bool:
        """Validate if coordinates are within valid ranges"""
        return -90 <= lat <= 90 and -180 <= lon <= 180
    
    @staticmethod
    def get_location_info(lat: float, lon: float) -> Dict:
        """Get basic location information from coordinates"""
        if not LocationService.validate_coordinates(lat, lon):
            return {"error": "Invalid coordinates"}
        
        # This would typically integrate with a geocoding service
        # For now, return basic info
        return {
            "latitude": lat,
            "longitude": lon,
            "coordinates_valid": True,
            "location_type": "coordinates"
        }

# Global instance
location_service = LocationService()
