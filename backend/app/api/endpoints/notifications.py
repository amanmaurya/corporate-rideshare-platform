from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_database
from app.models.user import User
from app.services.auth import verify_token
from app.services.notification_service import notification_service, NotificationType
from app.schemas.notification import (
    NotificationResponse, 
    PushTokenRequest, 
    NotificationStats
)

router = APIRouter()
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), 
                    db: Session = Depends(get_database)):
    """Get current authenticated user"""
    token = credentials.credentials
    payload = verify_token(token)

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user

@router.get("/", response_model=List[NotificationResponse])
async def get_notifications(
    current_user: User = Depends(get_current_user),
    limit: int = 50,
    unread_only: bool = False
):
    """Get notifications for current user"""
    notifications = notification_service.get_user_notifications(current_user.id, limit)
    
    if unread_only:
        notifications = [n for n in notifications if not n["read"]]
    
    return notifications

@router.get("/stats", response_model=NotificationStats)
async def get_notification_stats(current_user: User = Depends(get_current_user)):
    """Get notification statistics for current user"""
    return notification_service.get_notification_stats(current_user.id)

@router.post("/mark-read/{notification_id}")
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user)
):
    """Mark a specific notification as read"""
    success = notification_service.mark_notification_read(current_user.id, notification_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    return {"message": "Notification marked as read"}

@router.post("/mark-all-read")
async def mark_all_notifications_read(current_user: User = Depends(get_current_user)):
    """Mark all notifications as read for current user"""
    success = notification_service.mark_all_notifications_read(current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to mark notifications as read"
        )
    
    return {"message": "All notifications marked as read"}

@router.post("/register-push-token")
async def register_push_token(
    token_request: PushTokenRequest,
    current_user: User = Depends(get_current_user)
):
    """Register push notification token for current user"""
    success = notification_service.register_push_token(current_user.id, token_request.token)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to register push token"
        )
    
    return {"message": "Push token registered successfully"}

@router.delete("/unregister-push-token")
async def unregister_push_token(current_user: User = Depends(get_current_user)):
    """Unregister push notification token for current user"""
    success = notification_service.unregister_push_token(current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to unregister push token"
        )
    
    return {"message": "Push token unregistered successfully"}

@router.post("/test")
async def send_test_notification(current_user: User = Depends(get_current_user)):
    """Send a test notification to current user (for testing purposes)"""
    success = await notification_service.send_notification(
        user_id=current_user.id,
        notification_type=NotificationType.RIDE_REQUEST,
        title="Test Notification",
        message="This is a test notification to verify the system is working",
        data={"test": True},
        priority=NotificationType.NORMAL
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send test notification"
        )
    
    return {"message": "Test notification sent successfully"}

@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a specific notification"""
    # This would need to be implemented in the notification service
    # For now, just return a message
    return {"message": "Notification deletion not yet implemented"}

@router.get("/types")
async def get_notification_types():
    """Get available notification types"""
    from app.services.notification_service import NotificationPriority
    
    return {
        "types": [t.value for t in NotificationType],
        "priorities": [p.value for p in NotificationPriority]
    }
