from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException
from app.services.websocket_service import manager
import json
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time communication"""
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            await handle_websocket_message(user_id, message)
            
    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(user_id)

async def handle_websocket_message(user_id: str, message: dict):
    """Handle incoming WebSocket messages"""
    message_type = message.get("type")
    
    if message_type == "location_update":
        await handle_location_update(user_id, message)
    elif message_type == "ride_request":
        await handle_ride_request(user_id, message)
    elif message_type == "ride_response":
        await handle_ride_response(user_id, message)
    elif message_type == "driver_status":
        await handle_driver_status(user_id, message)
    else:
        logger.warning(f"Unknown message type: {message_type}")

async def handle_location_update(user_id: str, message: dict):
    """Handle user location updates"""
    location_data = message.get("data", {})
    location_data["user_id"] = user_id
    
    await manager.update_user_location(user_id, location_data)
    
    # Send confirmation back to user
    await manager.send_personal_message({
        "type": "location_updated",
        "status": "success",
        "timestamp": message.get("timestamp")
    }, user_id)

async def handle_ride_request(user_id: str, message: dict):
    """Handle ride request from rider"""
    ride_data = message.get("data", {})
    ride_data["rider_id"] = user_id
    
    # Process the ride request
    await manager.handle_ride_request(ride_data)
    
    # Send confirmation to rider
    await manager.send_personal_message({
        "type": "ride_request_sent",
        "status": "success",
        "message": "Ride request sent to nearby drivers",
        "timestamp": message.get("timestamp")
    }, user_id)

async def handle_ride_response(user_id: str, message: dict):
    """Handle driver's response to ride request"""
    response_data = message.get("data", {})
    ride_id = response_data.get("ride_id")
    response_type = response_data.get("response")  # "accept" or "decline"
    
    if response_type == "accept":
        # Update ride status and notify rider
        await handle_ride_accepted(user_id, ride_id, response_data)
    elif response_type == "decline":
        # Notify rider that ride was declined
        await handle_ride_declined(user_id, ride_id, response_data)

async def handle_ride_accepted(user_id: str, ride_id: str, response_data: dict):
    """Handle when a driver accepts a ride"""
    # Get ride details from pending rides
    if ride_id in manager.pending_rides:
        ride_data = manager.pending_rides[ride_id]
        rider_id = ride_data.get("rider_id")
        
        # Remove from pending rides
        del manager.pending_rides[ride_id]
        
        # Notify rider that ride was accepted
        await manager.send_personal_message({
            "type": "ride_accepted",
            "data": {
                "ride_id": ride_id,
                "driver_id": user_id,
                "driver_name": response_data.get("driver_name"),
                "estimated_arrival": response_data.get("estimated_arrival")
            },
            "timestamp": response_data.get("timestamp")
        }, rider_id)
        
        # Notify driver
        await manager.send_personal_message({
            "type": "ride_confirmed",
            "data": {
                "ride_id": ride_id,
                "rider_id": rider_id,
                "pickup_location": ride_data.get("pickup_location"),
                "destination": ride_data.get("destination")
            },
            "timestamp": response_data.get("timestamp")
        }, user_id)

async def handle_ride_declined(user_id: str, ride_id: str, response_data: dict):
    """Handle when a driver declines a ride"""
    if ride_id in manager.pending_rides:
        ride_data = manager.pending_rides[ride_id]
        rider_id = ride_data.get("rider_id")
        
        # Notify rider that ride was declined
        await manager.send_personal_message({
            "type": "ride_declined",
            "data": {
                "ride_id": ride_id,
                "driver_id": user_id,
                "reason": response_data.get("reason", "Driver unavailable")
            },
            "timestamp": response_data.get("timestamp")
        }, rider_id)

async def handle_driver_status(user_id: str, message: dict):
    """Handle driver availability status updates"""
    status_data = message.get("data", {})
    is_available = status_data.get("is_available", False)
    
    # Update driver status in location data
    if user_id in manager.user_locations:
        manager.user_locations[user_id]["is_available"] = is_available
        
        # Send confirmation
        await manager.send_personal_message({
            "type": "driver_status_updated",
            "status": "success",
            "data": {"is_available": is_available},
            "timestamp": message.get("timestamp")
        }, user_id)

@router.get("/status/{user_id}")
async def get_connection_status(user_id: str):
    """Get WebSocket connection status for a user"""
    is_connected = user_id in manager.active_connections
    has_location = user_id in manager.user_locations
    
    return {
        "user_id": user_id,
        "is_connected": is_connected,
        "has_location": has_location,
        "active_connections_count": len(manager.active_connections)
    }

@router.get("/active-connections")
async def get_active_connections():
    """Get count of active WebSocket connections"""
    return {
        "active_connections": len(manager.active_connections),
        "users_with_location": len(manager.user_locations),
        "pending_rides": len(manager.pending_rides)
    }
