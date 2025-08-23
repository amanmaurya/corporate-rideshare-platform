from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_database
from app.models.user import User
from app.models.ride import Ride
from app.services.auth import verify_token
from app.services.payment_service import payment_service
from app.schemas.payment import PaymentCreate, PaymentResponse, RefundCreate, RefundResponse
import logging

router = APIRouter()
security = HTTPBearer()
logger = logging.getLogger(__name__)

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

@router.post("/ride/{ride_id}", response_model=PaymentResponse)
async def process_ride_payment(ride_id: str, 
                             payment_data: PaymentCreate,
                             current_user: User = Depends(get_current_user),
                             db: Session = Depends(get_database)):
    """Process payment for a completed ride"""
    
    # Verify ride exists and belongs to user's company
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()
    
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )
    
    # Verify ride is completed
    if ride.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride must be completed before processing payment"
        )
    
    # Calculate fare if not provided
    if not payment_data.amount:
        if ride.distance and ride.actual_duration:
            amount = payment_service.calculate_ride_fare(
                ride.distance, 
                ride.actual_duration
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ride distance and duration required for fare calculation"
            )
    else:
        amount = payment_data.amount
    
    try:
        # Process payment
        payment_response = payment_service.process_ride_payment(
            ride_id=ride_id,
            user_id=current_user.id,
            company_id=current_user.company_id,
            distance_km=ride.distance or 0,
            duration_minutes=ride.actual_duration or 0
        )
        
        # Update ride with payment information
        ride.fare = amount
        ride.payment_status = "completed"
        db.commit()
        
        logger.info(f"Payment processed for ride {ride_id}: {payment_response.payment_id}")
        
        return payment_response
        
    except Exception as e:
        logger.error(f"Payment processing failed for ride {ride_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment processing failed"
        )

@router.post("/corporate", response_model=PaymentResponse)
async def process_corporate_payment(payment_data: PaymentCreate,
                                 current_user: User = Depends(get_current_user),
                                 db: Session = Depends(get_database)):
    """Process corporate payment (subscriptions, premium features, etc.)"""
    
    try:
        payment_response = payment_service.process_corporate_payment(
            ride_id="",  # Not applicable for corporate payments
            user_id=current_user.id,
            company_id=current_user.company_id,
            amount=payment_data.amount,
            description=payment_data.description or "Corporate service payment"
        )
        
        logger.info(f"Corporate payment processed: {payment_response.payment_id}")
        
        return payment_response
        
    except Exception as e:
        logger.error(f"Corporate payment processing failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment processing failed"
        )

@router.post("/refund", response_model=RefundResponse)
async def process_refund(refund_data: RefundCreate,
                        current_user: User = Depends(get_current_user),
                        db: Session = Depends(get_database)):
    """Process a refund request"""
    
    try:
        refund_response = payment_service.refund_payment(
            payment_id=refund_data.payment_id,
            amount=refund_data.amount,
            reason=refund_data.reason,
            user_id=current_user.id
        )
        
        if not refund_response:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found"
            )
        
        logger.info(f"Refund processed: {refund_data.payment_id}")
        
        return RefundResponse(
            refund_id=refund_response.payment_id,
            payment_id=refund_data.payment_id,
            amount=refund_data.amount,
            status="completed",
            reason=refund_data.reason,
            created_at=refund_response.updated_at
        )
        
    except Exception as e:
        logger.error(f"Refund processing failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Refund processing failed"
        )

@router.get("/history", response_model=List[dict])
async def get_payment_history(current_user: User = Depends(get_current_user),
                            db: Session = Depends(get_database)):
    """Get payment history for current user"""
    
    try:
        payments = payment_service.get_payment_history(current_user.id)
        return payments
        
    except Exception as e:
        logger.error(f"Failed to get payment history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve payment history"
        )

@router.get("/company/summary", response_model=dict)
async def get_company_payment_summary(current_user: User = Depends(get_current_user),
                                    db: Session = Depends(get_database)):
    """Get payment summary for user's company (admin only)"""
    
    # Check if user is admin
    if current_user.role.lower() not in ["admin", "manager", "hr"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    try:
        summary = payment_service.get_company_payment_summary(current_user.company_id)
        return summary
        
    except Exception as e:
        logger.error(f"Failed to get company payment summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve company payment summary"
        )

@router.get("/status/{payment_id}", response_model=dict)
async def get_payment_status(payment_id: str,
                           current_user: User = Depends(get_current_user),
                           db: Session = Depends(get_database)):
    """Get status of a specific payment"""
    
    try:
        payment_status = payment_service.processor.get_payment_status(payment_id)
        
        if not payment_status:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found"
            )
        
        # Verify user has access to this payment
        if (payment_status["user_id"] != current_user.id and 
            payment_status["company_id"] != current_user.company_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        return payment_status
        
    except Exception as e:
        logger.error(f"Failed to get payment status: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve payment status"
        )

@router.get("/fare/calculate")
async def calculate_fare(distance_km: float, duration_minutes: int,
                        current_user: User = Depends(get_current_user)):
    """Calculate estimated fare for a ride"""
    
    try:
        fare = payment_service.calculate_ride_fare(distance_km, duration_minutes)
        
        return {
            "estimated_fare": fare,
            "currency": "USD",
            "breakdown": {
                "base_rate": 2.0,
                "distance_cost": distance_km * 1.5,
                "time_cost": duration_minutes * 0.5
            }
        }
        
    except Exception as e:
        logger.error(f"Fare calculation failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Fare calculation failed"
        )
