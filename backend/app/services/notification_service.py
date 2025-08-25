import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
from enum import Enum
import json

logger = logging.getLogger(__name__)

class NotificationType(Enum):
    """Types of notifications"""
    RIDE_REQUEST = "ride_request"
    RIDE_ACCEPTED = "ride_accepted"
    RIDE_DECLINED = "ride_declined"
    RIDE_STARTED = "ride_started"
    RIDE_COMPLETED = "ride_completed"
    DRIVER_ARRIVING = "driver_arriving"
    LOCATION_UPDATE = "location_update"
    PAYMENT_RECEIVED = "payment_received"
    RIDE_CANCELLED = "ride_cancelled"

class NotificationPriority(Enum):
    """Notification priority levels"""
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"

class NotificationService:
    """Service for handling notifications"""
    
    def __init__(self):
        self.notifications = {}  # In-memory storage for demo
        self.push_tokens = {}    # Store push notification tokens
        
    async def send_notification(self, 
                               user_id: str, 
                               notification_type: NotificationType,
                               title: str, 
                               message: str, 
                               data: Dict = None,
                               priority: NotificationPriority = NotificationPriority.NORMAL) -> bool:
        """
        Send a notification to a user
        Returns True if successful, False otherwise
        """
        try:
            notification = {
                "id": f"notif_{datetime.now(timezone.utc).timestamp()}",
                "user_id": user_id,
                "type": notification_type.value,
                "title": title,
                "message": message,
                "data": data or {},
                "priority": priority.value,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "read": False
            }
            
            # Store notification
            if user_id not in self.notifications:
                self.notifications[user_id] = []
            self.notifications[user_id].append(notification)
            
            # Send push notification if token exists
            await self.send_push_notification(user_id, notification)
            
            # Send in-app notification via WebSocket
            await self.send_websocket_notification(user_id, notification)
            
            logger.info(f"Notification sent to user {user_id}: {title}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send notification to user {user_id}: {e}")
            return False
    
    async def send_push_notification(self, user_id: str, notification: Dict) -> bool:
        """Send push notification to user's device"""
        if user_id in self.push_tokens:
            token = self.push_tokens[user_id]
            
            # This would integrate with FCM, APNS, or other push services
            # For now, just log the attempt
            logger.info(f"Push notification would be sent to token {token}: {notification['title']}")
            
            # In production, you would:
            # 1. Send to FCM for Android
            # 2. Send to APNS for iOS
            # 3. Handle delivery receipts
            # 4. Retry failed deliveries
            
            return True
        return False
    
    async def send_websocket_notification(self, user_id: str, notification: Dict) -> bool:
        """Send notification via WebSocket for real-time delivery"""
        try:
            from app.services.websocket_service import manager
            
            await manager.send_personal_message({
                "type": "notification",
                "data": notification
            }, user_id)
            
            return True
        except Exception as e:
            logger.error(f"Failed to send WebSocket notification: {e}")
            return False
    
    async def send_ride_notification(self, 
                                   user_id: str, 
                                   ride_id: str, 
                                   notification_type: NotificationType,
                                   ride_data: Dict = None) -> bool:
        """Send ride-specific notifications"""
        
        notifications = {
            NotificationType.RIDE_REQUEST: {
                "title": "New Ride Request",
                "message": "You have a new ride request",
                "priority": NotificationPriority.HIGH
            },
            NotificationType.RIDE_ACCEPTED: {
                "title": "Ride Accepted!",
                "message": "Your ride request has been accepted",
                "priority": NotificationPriority.HIGH
            },
            NotificationType.RIDE_DECLINED: {
                "title": "Ride Declined",
                "message": "Your ride request was declined",
                "priority": NotificationPriority.NORMAL
            },
            NotificationType.RIDE_STARTED: {
                "title": "Ride Started",
                "message": "Your ride is now in progress",
                "priority": NotificationPriority.HIGH
            },
            NotificationType.RIDE_COMPLETED: {
                "title": "Ride Completed",
                "message": "Your ride has been completed",
                "priority": NotificationPriority.NORMAL
            },
            NotificationType.DRIVER_ARRIVING: {
                "title": "Driver Arriving",
                "message": "Your driver is arriving soon",
                "priority": NotificationPriority.HIGH
            },
            NotificationType.RIDE_CANCELLED: {
                "title": "Ride Cancelled",
                "message": "Your ride has been cancelled",
                "priority": NotificationPriority.NORMAL
            }
        }
        
        if notification_type in notifications:
            notif_info = notifications[notification_type]
            
            return await self.send_notification(
                user_id=user_id,
                notification_type=notification_type,
                title=notif_info["title"],
                message=notif_info["message"],
                data={"ride_id": ride_id, **(ride_data or {})},
                priority=notif_info["priority"]
            )
        
        return False
    
    async def send_bulk_notifications(self, 
                                    user_ids: List[str], 
                                    notification_type: NotificationType,
                                    title: str, 
                                    message: str, 
                                    data: Dict = None) -> Dict[str, bool]:
        """Send notifications to multiple users"""
        results = {}
        
        for user_id in user_ids:
            results[user_id] = await self.send_notification(
                user_id, notification_type, title, message, data
            )
        
        return results
    
    def register_push_token(self, user_id: str, token: str) -> bool:
        """Register a push notification token for a user"""
        try:
            self.push_tokens[user_id] = token
            logger.info(f"Push token registered for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to register push token for user {user_id}: {e}")
            return False
    
    def unregister_push_token(self, user_id: str) -> bool:
        """Unregister push notification token for a user"""
        try:
            if user_id in self.push_tokens:
                del self.push_tokens[user_id]
                logger.info(f"Push token unregistered for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to unregister push token for user {user_id}: {e}")
            return False
    
    def get_user_notifications(self, user_id: str, limit: int = 50) -> List[Dict]:
        """Get notifications for a specific user"""
        if user_id in self.notifications:
            # Return most recent notifications first
            return sorted(
                self.notifications[user_id], 
                key=lambda x: x["timestamp"], 
                reverse=True
            )[:limit]
        return []
    
    def mark_notification_read(self, user_id: str, notification_id: str) -> bool:
        """Mark a notification as read"""
        try:
            if user_id in self.notifications:
                for notification in self.notifications[user_id]:
                    if notification["id"] == notification_id:
                        notification["read"] = True
                        return True
            return False
        except Exception as e:
            logger.error(f"Failed to mark notification as read: {e}")
            return False
    
    def mark_all_notifications_read(self, user_id: str) -> bool:
        """Mark all notifications as read for a user"""
        try:
            if user_id in self.notifications:
                for notification in self.notifications[user_id]:
                    notification["read"] = True
                return True
            return False
        except Exception as e:
            logger.error(f"Failed to mark all notifications as read: {e}")
            return False
    
    def get_notification_stats(self, user_id: str) -> Dict:
        """Get notification statistics for a user"""
        if user_id in self.notifications:
            notifications = self.notifications[user_id]
            total = len(notifications)
            unread = len([n for n in notifications if not n["read"]])
            
            return {
                "total_notifications": total,
                "unread_notifications": unread,
                "read_notifications": total - unread
            }
        return {
            "total_notifications": 0,
            "unread_notifications": 0,
            "read_notifications": 0
        }

    def _create_notification_data(self, notification_type: str, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "id": f"notif_{datetime.now(timezone.utc).timestamp()}",
            "type": notification_type,
            "user_id": user_id,
            "data": data,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "read": False
        }

# Global notification service instance
notification_service = NotificationService()
