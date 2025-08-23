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
        # Store company connections for broadcasting
        self.company_connections: Dict[str, Set[str]] = {}
        
    async def connect(self, websocket: WebSocket, user_id: str, company_id: str):
        """Connect a new user"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        # Add to company connections
        if company_id not in self.company_connections:
            self.company_connections[company_id] = set()
        self.company_connections[company_id].add(user_id)
        
        logger.info(f"User {user_id} connected to company {company_id}")
        
        # Send welcome message
        await self.send_personal_message({
            "type": "connection",
            "message": "Connected successfully",
            "timestamp": datetime.utcnow().isoformat()
        }, user_id)
        
    def disconnect(self, user_id: str, company_id: str):
        """Disconnect a user"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            
        # Remove from company connections
        if company_id in self.company_connections:
            self.company_connections[company_id].discard(user_id)
            if not self.company_connections[company_id]:
                del self.company_connections[company_id]
                
        logger.info(f"User {user_id} disconnected from company {company_id}")
        
    async def send_personal_message(self, message: dict, user_id: str):
        """Send message to specific user"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error sending message to user {user_id}: {e}")
                # Remove broken connection
                del self.active_connections[user_id]
                
    async def broadcast_to_company(self, message: dict, company_id: str, exclude_user: Optional[str] = None):
        """Broadcast message to all users in a company"""
        if company_id in self.company_connections:
            for user_id in self.company_connections[company_id]:
                if user_id != exclude_user:
                    await self.send_personal_message(message, user_id)
                    
    async def broadcast_ride_update(self, ride_data: dict, company_id: str, exclude_user: Optional[str] = None):
        """Broadcast ride update to company"""
        message = {
            "type": "ride_update",
            "data": ride_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast_to_company(message, company_id, exclude_user)
        
    async def broadcast_ride_request(self, request_data: dict, company_id: str, exclude_user: Optional[str] = None):
        """Broadcast ride request to company"""
        message = {
            "type": "ride_request",
            "data": request_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast_to_company(message, company_id, exclude_user)
        
    async def broadcast_location_update(self, user_id: str, location_data: dict, company_id: str):
        """Broadcast location update to company"""
        message = {
            "type": "location_update",
            "user_id": user_id,
            "data": location_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast_to_company(message, company_id, exclude_user=user_id)
        
    async def send_notification(self, user_id: str, notification_data: dict):
        """Send notification to specific user"""
        message = {
            "type": "notification",
            "data": notification_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.send_personal_message(message, user_id)

# Global connection manager instance
manager = ConnectionManager()

class WebSocketService:
    def __init__(self):
        self.manager = manager
        
    async def handle_websocket(self, websocket: WebSocket, user_id: str, company_id: str):
        """Handle WebSocket connection for a user"""
        await self.manager.connect(websocket, user_id, company_id)
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_text()
                message = json.loads(data)
                
                # Handle different message types
                await self.handle_message(message, user_id, company_id)
                
        except WebSocketDisconnect:
            self.manager.disconnect(user_id, company_id)
        except Exception as e:
            logger.error(f"WebSocket error for user {user_id}: {e}")
            self.manager.disconnect(user_id, company_id)
            
    async def handle_message(self, message: dict, user_id: str, company_id: str):
        """Handle incoming WebSocket messages"""
        message_type = message.get("type")
        
        if message_type == "ping":
            # Respond to ping with pong
            await self.manager.send_personal_message({
                "type": "pong",
                "timestamp": datetime.utcnow().isoformat()
            }, user_id)
            
        elif message_type == "location_update":
            # Handle location update
            location_data = message.get("data", {})
            await self.manager.broadcast_location_update(user_id, location_data, company_id)
            
        elif message_type == "ride_status":
            # Handle ride status update
            ride_data = message.get("data", {})
            await self.manager.broadcast_ride_update(ride_data, company_id, exclude_user=user_id)
            
        else:
            logger.warning(f"Unknown message type: {message_type}")

# Global WebSocket service instance
websocket_service = WebSocketService()
