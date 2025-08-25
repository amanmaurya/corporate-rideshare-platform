import asyncio
import json
import logging
from typing import Dict, Set, Optional, List, Any
from fastapi import WebSocket, WebSocketDisconnect
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.database import get_database
from app.models.user import User
from app.models.ride import Ride, RideRequest

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
            "timestamp": datetime.now(timezone.utc).isoformat()
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
                "timestamp": datetime.now(timezone.utc).isoformat()
            }, driver_id)
            
    async def find_nearby_drivers(self, company_id: str, lat: float, lon: float, max_distance: float = 5.0):
        """Find nearby available drivers in the same company"""
        nearby_drivers = []
        
        for user_id, user_info in self.user_locations.items():
            if (user_info.get("company_id") == company_id and 
                user_info.get("is_driver") and 
                user_info.get("is_available") and
                user_info.get("latitude") and 
                user_info.get("longitude")):
                
                # Calculate distance (simple Euclidean distance for demo)
                driver_lat = user_info["latitude"]
                driver_lon = user_info["longitude"]
                distance = ((lat - driver_lat) ** 2 + (lon - driver_lon) ** 2) ** 0.5
                
                if distance <= max_distance:
                    nearby_drivers.append({
                        "user_id": user_id,
                        "distance": distance,
                        "location": user_info
                    })
        
        # Sort by distance
        nearby_drivers.sort(key=lambda x: x["distance"])
        return nearby_drivers

    async def send_ride_notification(self, user_id: str, notification_type: str, data: dict):
        """Send ride-related notification to user"""
        message = {
            "type": "ride_notification",
            "notification_type": notification_type,
            "data": data,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        await self.send_personal_message(message, user_id)

    async def broadcast_company_message(self, company_id: str, message: dict):
        """Broadcast message to all users in a company"""
        for user_id, websocket in self.active_connections.items():
            if user_id in self.user_locations:
                user_info = self.user_locations[user_id]
                if user_info.get("company_id") == company_id:
                    await self.send_personal_message(message, user_id)

    async def get_connection_stats(self):
        """Get connection statistics"""
        return {
            "active_connections": len(self.active_connections),
            "users_with_location": len(self.user_locations),
            "pending_rides": len(self.pending_rides),
            "companies_online": len(set(
                user_info.get("company_id") 
                for user_info in self.user_locations.values() 
                if user_info.get("company_id")
            ))
        }

    async def cleanup_inactive_connections(self):
        """Clean up inactive connections"""
        inactive_users = []
        for user_id, websocket in self.active_connections.items():
            try:
                # Send ping to check if connection is alive
                await websocket.ping()
            except:
                inactive_users.append(user_id)
        
        for user_id in inactive_users:
            self.disconnect(user_id)

# Global instance
manager = ConnectionManager()
