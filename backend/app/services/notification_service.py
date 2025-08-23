import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum
from dataclasses import dataclass
from app.services.websocket_service import websocket_service

logger = logging.getLogger(__name__)

class NotificationType(str, Enum):
    RIDE_REQUEST = "ride_request"
    RIDE_ACCEPTED = "ride_accepted"
    RIDE_DECLINED = "ride_declined"
    RIDE_STARTED = "ride_started"
    RIDE_COMPLETED = "ride_completed"
    RIDE_CANCELLED = "ride_cancelled"
    LOCATION_UPDATE = "location_update"
    PAYMENT_PROCESSED = "payment_processed"
    PAYMENT_FAILED = "payment_failed"
    SYSTEM_MESSAGE = "system_message"
    REMINDER = "reminder"

class NotificationPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

@dataclass
class NotificationData:
    user_id: str
    company_id: str
    notification_type: NotificationType
    title: str
    message: str
    data: Optional[Dict[str, Any]] = None
    priority: NotificationPriority = NotificationPriority.MEDIUM
    scheduled_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None

class NotificationService:
    """Service for managing notifications and push messages"""
    
    def __init__(self):
        self.notifications: Dict[str, Dict] = {}
        self.user_preferences: Dict[str, Dict] = {}
        
    def create_notification(self, notification_data: NotificationData) -> str:
        """Create a new notification"""
        notification_id = f"notif_{len(self.notifications) + 1}"
        
        notification = {
            "id": notification_id,
            "user_id": notification_data.user_id,
            "company_id": notification_data.company_id,
            "type": notification_data.notification_type.value,
            "title": notification_data.title,
            "message": notification_data.message,
            "data": notification_data.data or {},
            "priority": notification_data.priority.value,
            "is_read": False,
            "created_at": datetime.utcnow(),
            "scheduled_at": notification_data.scheduled_at,
            "expires_at": notification_data.expires_at
        }
        
        self.notifications[notification_id] = notification
        
        # Send real-time notification via WebSocket
        self.send_realtime_notification(notification_data.user_id, notification)
        
        logger.info(f"Notification created: {notification_id} for user {notification_data.user_id}")
        return notification_id
    
    def send_realtime_notification(self, user_id: str, notification: Dict):
        """Send notification via WebSocket in real-time"""
        try:
            websocket_service.manager.send_notification(user_id, {
                "id": notification["id"],
                "type": notification["type"],
                "title": notification["title"],
                "message": notification["message"],
                "data": notification["data"],
                "priority": notification["priority"],
                "timestamp": notification["created_at"].isoformat()
            })
        except Exception as e:
            logger.error(f"Failed to send real-time notification: {e}")
    
    def notify_ride_request(self, ride_id: str, rider_id: str, driver_id: str, 
                           company_id: str, pickup_location: str, destination: str):
        """Notify driver about a ride request"""
        notification_data = NotificationData(
            user_id=driver_id,
            company_id=company_id,
            notification_type=NotificationType.RIDE_REQUEST,
            title="New Ride Request",
            message=f"Ride request from {pickup_location} to {destination}",
            data={
                "ride_id": ride_id,
                "rider_id": rider_id,
                "pickup_location": pickup_location,
                "destination": destination,
                "action_required": True
            },
            priority=NotificationPriority.HIGH
        )
        
        return self.create_notification(notification_data)
    
    def notify_ride_accepted(self, ride_id: str, rider_id: str, driver_id: str, 
                            company_id: str, driver_name: str):
        """Notify rider that their ride request was accepted"""
        notification_data = NotificationData(
            user_id=rider_id,
            company_id=company_id,
            notification_type=NotificationType.RIDE_ACCEPTED,
            title="Ride Accepted!",
            message=f"Your ride has been accepted by {driver_name}",
            data={
                "ride_id": ride_id,
                "driver_id": driver_id,
                "driver_name": driver_name,
                "status": "accepted"
            },
            priority=NotificationPriority.HIGH
        )
        
        return self.create_notification(notification_data)
    
    def notify_ride_started(self, ride_id: str, rider_id: str, driver_id: str, 
                           company_id: str):
        """Notify rider that their ride has started"""
        notification_data = NotificationData(
            user_id=rider_id,
            company_id=company_id,
            notification_type=NotificationType.RIDE_STARTED,
            title="Ride Started",
            message="Your ride has started. Track your journey in real-time.",
            data={
                "ride_id": ride_id,
                "driver_id": driver_id,
                "status": "in_progress"
            },
            priority=NotificationPriority.MEDIUM
        )
        
        return self.create_notification(notification_data)
    
    def notify_ride_completed(self, ride_id: str, rider_id: str, driver_id: str, 
                             company_id: str, fare: float):
        """Notify rider that their ride has completed"""
        notification_data = NotificationData(
            user_id=rider_id,
            company_id=company_id,
            notification_type=NotificationType.RIDE_COMPLETED,
            title="Ride Completed",
            message=f"Your ride has been completed. Fare: ${fare:.2f}",
            data={
                "ride_id": ride_id,
                "driver_id": driver_id,
                "fare": fare,
                "status": "completed",
                "action_required": True
            },
            priority=NotificationPriority.MEDIUM
        )
        
        return self.create_notification(notification_data)
    
    def notify_payment_processed(self, user_id: str, company_id: str, 
                                payment_id: str, amount: float, ride_id: Optional[str] = None):
        """Notify user about successful payment processing"""
        title = "Payment Processed"
        message = f"Payment of ${amount:.2f} has been processed successfully"
        
        if ride_id:
            title = "Ride Payment Processed"
            message = f"Ride payment of ${amount:.2f} has been processed"
        
        notification_data = NotificationData(
            user_id=user_id,
            company_id=company_id,
            notification_type=NotificationType.PAYMENT_PROCESSED,
            title=title,
            message=message,
            data={
                "payment_id": payment_id,
                "amount": amount,
                "ride_id": ride_id,
                "status": "completed"
            },
            priority=NotificationPriority.MEDIUM
        )
        
        return self.create_notification(notification_data)
    
    def notify_payment_failed(self, user_id: str, company_id: str, 
                             payment_id: str, amount: float, error_message: str):
        """Notify user about failed payment"""
        notification_data = NotificationData(
            user_id=user_id,
            company_id=company_id,
            notification_type=NotificationType.PAYMENT_FAILED,
            title="Payment Failed",
            message=f"Payment of ${amount:.2f} failed: {error_message}",
            data={
                "payment_id": payment_id,
                "amount": amount,
                "error_message": error_message,
                "action_required": True
            },
            priority=NotificationPriority.HIGH
        )
        
        return self.create_notification(notification_data)
    
    def notify_location_update(self, user_id: str, company_id: str, 
                              ride_id: str, driver_name: str, 
                              estimated_arrival: Optional[int] = None):
        """Notify rider about driver location update"""
        message = f"{driver_name} is on the way"
        if estimated_arrival:
            message += f". Estimated arrival: {estimated_arrival} minutes"
        
        notification_data = NotificationData(
            user_id=user_id,
            company_id=company_id,
            notification_type=NotificationType.LOCATION_UPDATE,
            title="Driver Update",
            message=message,
            data={
                "ride_id": ride_id,
                "driver_name": driver_name,
                "estimated_arrival": estimated_arrival
            },
            priority=NotificationPriority.LOW
        )
        
        return self.create_notification(notification_data)
    
    def send_system_message(self, user_id: str, company_id: str, 
                           title: str, message: str, priority: NotificationPriority = NotificationPriority.MEDIUM):
        """Send system message to user"""
        notification_data = NotificationData(
            user_id=user_id,
            company_id=company_id,
            notification_type=NotificationType.SYSTEM_MESSAGE,
            title=title,
            message=message,
            priority=priority
        )
        
        return self.create_notification(notification_data)
    
    def send_reminder(self, user_id: str, company_id: str, 
                      title: str, message: str, scheduled_at: datetime):
        """Schedule a reminder notification"""
        notification_data = NotificationData(
            user_id=user_id,
            company_id=company_id,
            notification_type=NotificationType.REMINDER,
            title=title,
            message=message,
            scheduled_at=scheduled_at,
            priority=NotificationPriority.MEDIUM
        )
        
        return self.create_notification(notification_data)
    
    def get_user_notifications(self, user_id: str, limit: int = 50, unread_only: bool = False) -> List[Dict]:
        """Get notifications for a specific user"""
        user_notifications = [
            notif for notif in self.notifications.values() 
            if notif["user_id"] == user_id
        ]
        
        if unread_only:
            user_notifications = [notif for notif in user_notifications if not notif["is_read"]]
        
        # Sort by creation date (newest first)
        user_notifications.sort(key=lambda x: x["created_at"], reverse=True)
        
        return user_notifications[:limit]
    
    def mark_notification_read(self, notification_id: str, user_id: str) -> bool:
        """Mark a notification as read"""
        if notification_id in self.notifications:
            notification = self.notifications[notification_id]
            if notification["user_id"] == user_id:
                notification["is_read"] = True
                return True
        return False
    
    def mark_all_notifications_read(self, user_id: str) -> int:
        """Mark all notifications as read for a user"""
        count = 0
        for notification in self.notifications.values():
            if notification["user_id"] == user_id and not notification["is_read"]:
                notification["is_read"] = True
                count += 1
        return count
    
    def delete_notification(self, notification_id: str, user_id: str) -> bool:
        """Delete a notification"""
        if notification_id in self.notifications:
            notification = self.notifications[notification_id]
            if notification["user_id"] == user_id:
                del self.notifications[notification_id]
                return True
        return False
    
    def get_notification_stats(self, user_id: str) -> Dict[str, int]:
        """Get notification statistics for a user"""
        user_notifications = [
            notif for notif in self.notifications.values() 
            if notif["user_id"] == user_id
        ]
        
        total = len(user_notifications)
        unread = len([notif for notif in user_notifications if not notif["is_read"]])
        
        return {
            "total": total,
            "unread": unread,
            "read": total - unread
        }

# Global notification service instance
notification_service = NotificationService()
