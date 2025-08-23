from fastapi import APIRouter
from app.api.endpoints import auth, rides, companies, users, websocket, notifications, payments

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(rides.router, prefix="/rides", tags=["rides"])
api_router.include_router(companies.router, prefix="/companies", tags=["companies"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(websocket.router, prefix="/websocket", tags=["websocket"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(payments.router, prefix="/payments", tags=["payments"])
