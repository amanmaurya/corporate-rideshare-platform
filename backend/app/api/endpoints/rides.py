from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
from app.database import get_database
from app.models.ride import Ride, RideRequest
from app.models.user import User
from app.schemas.ride import RideCreate, RideUpdate, RideResponse, RideRequestCreate, RideRequestResponse, RideMatch
from app.services.auth import verify_token
from app.services.ride_matching import RideMatchingService
from app.services.location import location_service

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

@router.post("/", response_model=RideResponse)
async def create_ride(ride: RideCreate, current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Create a new ride"""
    # Calculate distance
    distance = location_service.calculate_distance(
        ride.pickup_latitude, ride.pickup_longitude,
        ride.destination_latitude, ride.destination_longitude
    )

    db_ride = Ride(
        company_id=current_user.company_id,
        rider_id=current_user.id,
        pickup_location=ride.pickup_location,
        destination=ride.destination,
        pickup_latitude=ride.pickup_latitude,
        pickup_longitude=ride.pickup_longitude,
        destination_latitude=ride.destination_latitude,
        destination_longitude=ride.destination_longitude,
        scheduled_time=ride.scheduled_time,
        notes=ride.notes,
        max_passengers=ride.max_passengers,
        distance=distance
    )

    db.add(db_ride)
    db.commit()
    db.refresh(db_ride)

    return db_ride

@router.get("/", response_model=List[RideResponse])
async def get_rides(current_user: User = Depends(get_current_user), 
                   db: Session = Depends(get_database),
                   status: Optional[str] = None,
                   limit: int = 50):
    """Get rides for current user's company"""
    # Join with User table to get rider information
    query = db.query(Ride, User.name.label('rider_name'), User.email.label('rider_email'))\
              .join(User, Ride.rider_id == User.id)\
              .filter(Ride.company_id == current_user.company_id)

    if status:
        query = query.filter(Ride.status == status)

    results = query.limit(limit).all()
    
    # Convert to RideResponse with rider information
    rides = []
    for ride, rider_name, rider_email in results:
        ride_dict = {
            'id': ride.id,
            'company_id': ride.company_id,
            'rider_id': ride.rider_id,
            'driver_id': ride.driver_id,
            'pickup_location': ride.pickup_location,
            'destination': ride.destination,
            'pickup_latitude': ride.pickup_latitude,
            'pickup_longitude': ride.pickup_longitude,
            'destination_latitude': ride.destination_latitude,
            'destination_longitude': ride.destination_longitude,
            'scheduled_time': ride.scheduled_time,
            'notes': ride.notes,
            'max_passengers': ride.max_passengers,
            'status': ride.status,
            'fare': ride.fare,
            'distance': ride.distance,
            'duration': ride.duration,
            'current_passengers': ride.current_passengers,
            'actual_start_time': ride.actual_start_time,
            'actual_end_time': ride.actual_end_time,
            'created_at': ride.created_at,
            'rider_name': rider_name,
            'rider_email': rider_email,
        }
        rides.append(ride_dict)
    
    return rides

@router.get("/my-rides", response_model=List[RideResponse])
async def get_my_rides(current_user: User = Depends(get_current_user), 
                      db: Session = Depends(get_database)):
    """Get rides created by current user"""
    rides = db.query(Ride).filter(Ride.rider_id == current_user.id).all()
    return rides

@router.get("/{ride_id}", response_model=RideResponse)
async def get_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                  db: Session = Depends(get_database)):
    """Get specific ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    return ride

@router.put("/{ride_id}", response_model=RideResponse)
async def update_ride(ride_id: str, ride_update: RideUpdate, 
                     current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Update a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.rider_id == current_user.id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    # Update fields
    update_data = ride_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(ride, field, value)

    db.commit()
    db.refresh(ride)

    return ride

@router.delete("/{ride_id}")
async def delete_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Delete a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.rider_id == current_user.id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    db.delete(ride)
    db.commit()

    return {"message": "Ride deleted successfully"}

@router.get("/{ride_id}/matches", response_model=List[RideMatch])
async def find_ride_matches(ride_id: str, current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_database)):
    """Find matching rides for a specific ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    matching_service = RideMatchingService(db)
    matches = matching_service.find_matching_rides(
        current_user.id,
        ride.pickup_latitude,
        ride.pickup_longitude,
        ride.destination_latitude,
        ride.destination_longitude,
        ride.scheduled_time
    )

    return matches

@router.post("/{ride_id}/request", response_model=RideRequestResponse)
async def request_ride(ride_id: str, request_data: RideRequestCreate, 
                      current_user: User = Depends(get_current_user), 
                      db: Session = Depends(get_database)):
    """Request to join a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    if ride.current_passengers >= ride.max_passengers:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is full"
        )

    # Check if user already requested
    existing_request = db.query(RideRequest).filter(
        RideRequest.ride_id == ride_id,
        RideRequest.user_id == current_user.id
    ).first()

    if existing_request:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already requested this ride"
        )

    ride_request = RideRequest(
        ride_id=ride_id,
        user_id=current_user.id,
        message=request_data.message
    )

    db.add(ride_request)
    db.commit()
    db.refresh(ride_request)

    return ride_request

class AcceptRequestData(BaseModel):
    request_id: str

@router.post("/{ride_id}/accept")
async def accept_ride_request(ride_id: str, 
                            request_data: AcceptRequestData = Body(...),
                            current_user: User = Depends(get_current_user), 
                            db: Session = Depends(get_database)):
    """Accept a ride request (for ride creator or assigned driver)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if user is authorized to accept requests for this ride
    # User can accept if they are:
    # 1. Ride creator (rider)
    # 2. Assigned driver for this ride
    # 3. Admin
    if (ride.rider_id != current_user.id and 
        ride.driver_id != current_user.id and 
        current_user.role != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to accept requests for this ride"
        )

    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_data.request_id,
        RideRequest.ride_id == ride_id
    ).first()

    if not ride_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride request not found"
        )

    # Accept the request
    ride_request.status = "accepted"
    ride.current_passengers += 1
    db.commit()

    return {"message": "Ride request accepted"}

@router.post("/{ride_id}/reject")
async def reject_ride_request(ride_id: str,
                            request_data: AcceptRequestData = Body(...),
                            current_user: User = Depends(get_current_user),
                            db: Session = Depends(get_database)):
    """Reject a ride request (for ride creator or assigned driver)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if user is authorized to reject requests for this ride
    # User can reject if they are:
    # 1. Ride creator (rider)
    # 2. Assigned driver for this ride
    # 3. Admin
    if (ride.rider_id != current_user.id and 
        ride.driver_id != current_user.id and 
        current_user.role != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to reject requests for this ride"
        )

    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_data.request_id,
        RideRequest.ride_id == ride_id
    ).first()

    if not ride_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride request not found"
        )

    # Reject the request
    ride_request.status = "declined"
    db.commit()

    return {"message": "Ride request rejected"}

@router.delete("/requests/{request_id}")
async def cancel_ride_request(request_id: str,
                            current_user: User = Depends(get_current_user),
                            db: Session = Depends(get_database)):
    """Cancel a ride request (only the requester can cancel)"""
    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_id,
        RideRequest.user_id == current_user.id  # Only the requester can cancel
    ).first()

    if not ride_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride request not found or not authorized"
        )

    # Check if the request can be cancelled
    if ride_request.status not in ['pending']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel request with status: ${ride_request.status}"
        )

    # Delete the request
    db.delete(ride_request)
    db.commit()

    return {"message": "Ride request cancelled successfully"}

@router.post("/{ride_id}/accept-passenger")
async def accept_passenger_request(ride_id: str, 
                                 request_data: AcceptRequestData = Body(...),
                                 current_user: User = Depends(get_current_user), 
                                 db: Session = Depends(get_database)):
    """Accept a passenger request (for assigned drivers)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if user is the assigned driver for this ride
    if ride.driver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only assigned drivers can accept passenger requests"
        )

    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_data.request_id,
        RideRequest.ride_id == ride_id,
        RideRequest.status == "pending"  # Only accept pending requests
    ).first()

    if not ride_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride request not found or not pending"
        )

    # Accept the passenger request
    ride_request.status = "accepted"
    ride.current_passengers += 1
    db.commit()

    return {"message": "Passenger request accepted"}

@router.post("/{ride_id}/reject-passenger")
async def reject_passenger_request(ride_id: str,
                                request_data: AcceptRequestData = Body(...),
                                current_user: User = Depends(get_current_user),
                                db: Session = Depends(get_database)):
    """Reject a passenger request (for ride creators or assigned drivers)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if user is authorized to reject passenger requests for this ride
    # User can reject if they are:
    # 1. Ride creator (rider)
    # 2. Assigned driver for this ride
    # 3. Admin
    if (ride.rider_id != current_user.id and 
        ride.driver_id != current_user.id and 
        current_user.role != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to reject passenger requests for this ride"
        )

    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_data.request_id,
        RideRequest.ride_id == ride_id
    ).first()

    if not ride_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride request not found"
        )

    # Reject the request
    ride_request.status = "declined"
    db.commit()

    return {"message": "Passenger request rejected"}

@router.post("/{ride_id}/start")
async def start_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                    db: Session = Depends(get_database)):
    """Start a ride (for ride creator)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    if ride.status != "assigned":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride must be assigned to a driver before starting"
        )

    ride.status = "in_progress"
    ride.actual_start_time = datetime.utcnow()
    db.commit()

    return {"message": "Ride started successfully"}

@router.post("/{ride_id}/complete")
async def complete_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                       db: Session = Depends(get_database)):
    """Complete a ride (for ride creator)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    if ride.status != "in_progress":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride must be in progress to complete"
        )

    ride.status = "completed"
    ride.actual_end_time = datetime.utcnow()
    db.commit()

    return {"message": "Ride completed successfully"}

@router.post("/{ride_id}/offer-driving")
async def offer_to_drive_ride(ride_id: str, 
                             current_user: User = Depends(get_current_user), 
                             db: Session = Depends(get_database)):
    """Allow a driver to offer to drive a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if user is a driver
    if not current_user.is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can offer to drive rides"
        )

    # Check if ride already has a driver
    if ride.driver_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride already has a driver assigned"
        )

    # Check if user is trying to drive their own ride
    if ride.rider_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot drive your own ride"
        )

    # Create a driver offer (similar to ride request but for drivers)
    driver_offer = RideRequest(
        ride_id=ride_id,
        user_id=current_user.id,
        status="driver_offer",
        message="Driver offering to drive this ride"
    )

    db.add(driver_offer)
    db.commit()
    db.refresh(driver_offer)

    return {"message": "Driver offer submitted successfully", "offer_id": driver_offer.id}

@router.post("/{ride_id}/assign-driver")
async def assign_driver_to_ride(ride_id: str, 
                               driver_id: str,
                               current_user: User = Depends(get_current_user), 
                               db: Session = Depends(get_database)):
    """Assign a driver to a ride (admin or ride creator only)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Only ride creator or admin can assign drivers
    if ride.rider_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to assign drivers"
        )

    # Verify driver exists and is a driver
    driver = db.query(User).filter(
        User.id == driver_id,
        User.company_id == current_user.company_id,
        User.is_driver == True,
        User.is_active == True
    ).first()

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found or not available"
        )

    # Check if driver has offered to drive this ride
    driver_offer = db.query(RideRequest).filter(
        RideRequest.ride_id == ride_id,
        RideRequest.user_id == driver_id,
        RideRequest.status == "driver_offer"
    ).first()

    if not driver_offer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Driver must offer to drive before being assigned"
        )

    # Update ride with driver assignment
    ride.driver_id = driver_id
    ride.status = "assigned"
    ride.updated_at = datetime.utcnow()
    
    # Update driver offer status
    driver_offer.status = "accepted"
    driver_offer.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(ride)

    return {"message": f"Driver {driver.name} assigned to ride successfully"}

@router.get("/{ride_id}/requests", response_model=List[RideRequestResponse])
async def get_ride_requests(ride_id: str, current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_database)):
    """Get all requests for a specific ride (only for users who can manage them)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Restrictive authorization: Only show requests to users who can actually manage them
    # 1. Ride creator (rider) - can see and manage all requests
    # 2. Assigned driver - can see and manage passenger requests
    # 3. Admin - can see and manage all requests
    can_manage_requests = (
        ride.rider_id == current_user.id or  # Ride creator
        ride.driver_id == current_user.id or  # Assigned driver
        current_user.role == "admin"          # Admin
    )

    if not can_manage_requests:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view or manage ride requests"
        )

    # Get all requests for this ride
    requests = db.query(RideRequest).filter(RideRequest.ride_id == ride_id).all()
    return requests

@router.get("/{ride_id}/my-request")
async def get_my_ride_request(ride_id: str, current_user: User = Depends(get_current_user), 
                             db: Session = Depends(get_database)):
    """Get the current user's request status for a specific ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Find the user's request for this ride
    user_request = db.query(RideRequest).filter(
        RideRequest.ride_id == ride_id,
        RideRequest.user_id == current_user.id
    ).first()

    if not user_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You have not requested this ride"
        )

    return user_request

@router.get("/user/my-requests", response_model=List[RideRequestResponse])
async def get_my_all_ride_requests(current_user: User = Depends(get_current_user), 
                                  db: Session = Depends(get_database)):
    """Get all ride requests for the current user across all rides"""
    # Get all requests where the current user is either:
    # 1. A passenger requesting to join a ride
    # 2. A driver offering to drive a ride
    user_requests = db.query(RideRequest).filter(
        RideRequest.user_id == current_user.id
    ).all()
    
    return user_requests
