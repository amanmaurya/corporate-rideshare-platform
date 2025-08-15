import asyncio
import json
import logging
from typing import Dict, Set, Optional
from fastapi import WebSocket, WebSocketDisconnect
from datetime import datetime

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # Store active connections by user_id
        self.active_connections: Dict[str, WebSocket] = {}
        # Store user's current location
        self.user_locations: Dict[str, Dict] = {}
        # Store ride requests waiting for matches
        self.pending_rides: Dict[str, Dict] = {}
        
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        logger.info(f"User {user_id} connected to WebSocket")
        
        # Send current ride status if user has active rides
        await self.send_ride_status(user_id)
        
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.user_locations:
            del self.user_locations[user_id]
        logger.info(f"User {user_id} disconnected from WebSocket")
        
    async def send_personal_message(self, message: dict, user_id: str):
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Failed to send message to user {user_id}: {e}")
                self.disconnect(user_id)
                
    async def broadcast_ride_request(self, ride_request: dict, company_id: str):
        """Broadcast ride request to all available drivers in the company"""
        message = {
            "type": "ride_request",
            "data": ride_request,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Send to all drivers in the company
        for user_id, websocket in self.active_connections.items():
            if user_id in self.user_locations:
                user_info = self.user_locations[user_id]
                if (user_info.get("company_id") == company_id and 
                    user_info.get("is_driver") and 
                    user_info.get("is_available")):
                    await self.send_personal_message(message, user_id)
                    
    async def update_user_location(self, user_id: str, location_data: dict):
        """Update user's current location"""
        self.user_locations[user_id] = location_data
        
        # Notify relevant users about location update
        await self.notify_location_update(user_id, location_data)
        
    async def notify_location_update(self, user_id: str, location_data: dict):
        """Notify other users about location update (e.g., driver location for active rides)"""
        if user_id in self.user_locations:
            user_info = self.user_locations[user_id]
            if user_info.get("is_driver"):
                # Notify riders about driver location
                await self.notify_riders_about_driver(user_id, location_data)
                
    async def notify_riders_about_driver(self, driver_id: str, location_data: dict):
        """Notify riders about their driver's location"""
        # This would need to be implemented based on active ride relationships
        pass
        
    async def send_ride_status(self, user_id: str):
        """Send current ride status to user"""
        # This would query the database for user's active rides
        pass
        
    async def handle_ride_request(self, ride_data: dict):
        """Handle new ride request and find matches"""
        company_id = ride_data.get("company_id")
        pickup_location = ride_data.get("pickup_location")
        destination = ride_data.get("destination")
        
        # Store pending ride
        ride_id = ride_data.get("id")
        self.pending_rides[ride_id] = ride_data
        
        # Find nearby available drivers
        nearby_drivers = await self.find_nearby_drivers(
            company_id, 
            ride_data.get("pickup_latitude"), 
            ride_data.get("pickup_longitude")
        )
        
        # Send ride request to nearby drivers
        for driver_id in nearby_drivers:
            await self.send_personal_message({
                "type": "ride_request",
                "data": ride_data,
                "timestamp": datetime.utcnow().isoformat()
            }, driver_id)
            
    async def find_nearby_drivers(self, company_id: str, lat: float, lon: float, radius_km: float = 5.0):
        """Find drivers within radius of pickup location"""
        nearby_drivers = []
        
        for user_id, user_info in self.user_locations.items():
            if (user_info.get("company_id") == company_id and 
                user_info.get("is_driver") and 
                user_info.get("is_available")):
                
                driver_lat = user_info.get("latitude")
                driver_lon = user_info.get("longitude")
                
                if driver_lat and driver_lon:
                    distance = self.calculate_distance(lat, lon, driver_lat, driver_lon)
                    if distance <= radius_km:
                        nearby_drivers.append(user_id)
                        
        return nearby_drivers
        
    def calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points using Haversine formula"""
        import math
        
        R = 6371  # Earth's radius in kilometers
        
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        
        return R * c

# Global connection manager instance
manager = ConnectionManager()
