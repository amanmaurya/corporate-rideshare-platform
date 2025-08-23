from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from app.services.websocket_service import websocket_service
from app.services.auth import verify_token
from app.database import get_database
from app.models.user import User
from sqlalchemy.orm import Session
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

async def get_user_from_token(token: str, db: Session) -> User:
    """Get user from JWT token"""
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user

@router.websocket("/ws/{token}")
async def websocket_endpoint(websocket: WebSocket, token: str):
    """WebSocket endpoint for real-time communication"""
    try:
        # Verify token and get user info
        from app.database import SessionLocal
        db = SessionLocal()
        
        try:
            user = await get_user_from_token(token, db)
            company_id = user.company_id
            user_id = user.id
            
            logger.info(f"WebSocket connection attempt for user {user_id} in company {company_id}")
            
            # Handle WebSocket connection
            await websocket_service.handle_websocket(websocket, user_id, company_id)
            
        except Exception as e:
            logger.error(f"WebSocket authentication failed: {e}")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        finally:
            db.close()
            
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        try:
            await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
        except:
            pass

@router.get("/status")
async def websocket_status():
    """Get WebSocket connection status"""
    active_connections = len(websocket_service.manager.active_connections)
    company_connections = len(websocket_service.manager.company_connections)
    
    return {
        "status": "active",
        "active_connections": active_connections,
        "company_connections": company_connections,
        "timestamp": websocket_service.manager.active_connections
    }
