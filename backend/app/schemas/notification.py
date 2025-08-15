from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime

class NotificationBase(BaseModel):
    """Base notification schema"""
    type: str
    title: str
    message: str
    data: Optional[Dict[str, Any]] = None
    priority: str = "normal"

class NotificationResponse(NotificationBase):
    """Notification response schema"""
    id: str
    user_id: str
    timestamp: datetime
    read: bool
    
    class Config:
        from_attributes = True

class PushTokenRequest(BaseModel):
    """Push token registration request"""
    token: str
    platform: Optional[str] = None  # "ios", "android", "web"

class NotificationStats(BaseModel):
    """Notification statistics"""
    total_notifications: int
    unread_notifications: int
    read_notifications: int

class NotificationCreate(NotificationBase):
    """Create notification request"""
    user_id: str

class NotificationUpdate(BaseModel):
    """Update notification request"""
    read: Optional[bool] = None
    data: Optional[Dict[str, Any]] = None
