from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
from pydantic import BaseModel
from app.database import get_database
from app.models.ride import Ride, RideRequest, RideLocation
from app.models.user import User
from app.schemas.ride import (
    RideBase, RideCreate, RideUpdate, RideResponse, RideRequestBase, 
    RideRequestCreate, RideRequestResponse, RideLocationUpdate, 
    RideLocationResponse, RideProgressUpdate, RidePaymentUpdate, RideRating
)
from app.services.auth import verify_token

from app.services.location import location_service

router = APIRouter()
security = HTTPBearer()

def convert_ride_to_dict(ride: Ride, driver_name: str = None, driver_email: str = None) -> dict:
    """Convert SQLAlchemy Ride model to dictionary for Pydantic serialization"""
    ride_dict = {
        'id': ride.id,
        'company_id': ride.company_id,
        'driver_id': ride.driver_id,
        'pickup_location': ride.pickup_location,
        'destination': ride.destination,
        'pickup_latitude': ride.pickup_latitude,
        'pickup_longitude': ride.pickup_longitude,
        'destination_latitude': ride.destination_latitude,
        'destination_longitude': ride.destination_longitude,
        'scheduled_time': ride.scheduled_time,
        'vehicle_capacity': ride.vehicle_capacity,
        'notes': ride.notes,
        'status': ride.status,
        'fare': ride.fare,
        'distance': ride.distance,
        'duration': ride.duration,
        'confirmed_passengers': ride.confirmed_passengers,
        'actual_start_time': ride.actual_start_time,
        'actual_end_time': ride.actual_end_time,
        'created_at': ride.created_at,
        'current_latitude': getattr(ride, 'current_latitude', None),
        'current_longitude': getattr(ride, 'current_longitude', None),
        'pickup_time': getattr(ride, 'pickup_time', None),
        'dropoff_time': getattr(ride, 'dropoff_time', None),
        'estimated_pickup_time': getattr(ride, 'estimated_pickup_time', None),
        'estimated_dropoff_time': getattr(ride, 'estimated_dropoff_time', None),
        'ride_progress': getattr(ride, 'ride_progress', None),
        'payment_status': getattr(ride, 'payment_status', None),
        'payment_method': getattr(ride, 'payment_method', None),
        'ride_rating': getattr(ride, 'ride_rating', None),
        'ride_feedback': getattr(ride, 'feedback', None),
        'route_polyline': getattr(ride, 'route_polyline', None),
    }
    
    if driver_name:
        ride_dict['driver_name'] = driver_name
    if driver_email:
        ride_dict['driver_email'] = driver_email
    
    return ride_dict

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
    """Create a new ride (Driver only)"""
    # Only drivers can create rides
    if not current_user.is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can create rides"
        )

    # Calculate distance
    distance = location_service.calculate_distance(
        ride.pickup_latitude, ride.pickup_longitude,
        ride.destination_latitude, ride.destination_longitude
    )

    db_ride = Ride(
        company_id=current_user.company_id,
        driver_id=current_user.id,  # Driver creates the ride
        pickup_location=ride.pickup_location,
        destination=ride.destination,
        pickup_latitude=ride.pickup_latitude,
        pickup_longitude=ride.pickup_longitude,
        destination_latitude=ride.destination_latitude,
        destination_longitude=ride.destination_longitude,
        scheduled_time=ride.scheduled_time,
        vehicle_capacity=ride.vehicle_capacity,  # Vehicle capacity
        notes=ride.notes,
        fare=ride.fare,
        distance=distance,
        status="available"  # Starts as available for employees to request
    )

    db.add(db_ride)
    db.commit()
    db.refresh(db_ride)

    return convert_ride_to_dict(db_ride)

@router.get("/", response_model=List[RideResponse])
async def get_rides(current_user: User = Depends(get_current_user), 
                   db: Session = Depends(get_database),
                   status: Optional[str] = None,
                   limit: int = 50):
    """Get available rides for employees to request seats"""
    # Join with User table to get driver information
    query = db.query(Ride, User.name.label('driver_name'), User.email.label('driver_email'))\
              .join(User, Ride.driver_id == User.id)\
              .filter(
                  Ride.company_id == current_user.company_id,
                  Ride.status == "available"  # Only show available rides
              )

    if status:
        query = query.filter(Ride.status == status)

    results = query.limit(limit).all()
    
    # Convert to RideResponse with driver information
    rides = []
    for ride, driver_name, driver_email in results:
        ride_dict = {
            'id': ride.id,
            'company_id': ride.company_id,
            'driver_id': ride.driver_id,
            'pickup_location': ride.pickup_location,
            'destination': ride.destination,
            'pickup_latitude': ride.pickup_latitude,
            'pickup_longitude': ride.pickup_longitude,
            'destination_latitude': ride.destination_latitude,
            'destination_longitude': ride.destination_longitude,
            'scheduled_time': ride.scheduled_time,
            'vehicle_capacity': ride.vehicle_capacity,
            'notes': ride.notes,
            'status': ride.status,
            'fare': ride.fare,
            'distance': ride.distance,
            'duration': ride.duration,
            'confirmed_passengers': ride.confirmed_passengers,
            'actual_start_time': ride.actual_start_time,
            'actual_end_time': ride.actual_end_time,
            'created_at': ride.created_at,
            'driver_name': driver_name,
            'driver_email': driver_email,
            # Add new fields that RideResponse expects
            'current_latitude': getattr(ride, 'current_latitude', None),
            'current_longitude': getattr(ride, 'current_longitude', None),
            'pickup_time': getattr(ride, 'pickup_time', None),
            'dropoff_time': getattr(ride, 'dropoff_time', None),
            'estimated_pickup_time': getattr(ride, 'estimated_pickup_time', None),
            'estimated_dropoff_time': getattr(ride, 'estimated_dropoff_time', None),
            'ride_progress': getattr(ride, 'ride_progress', None),
            'payment_status': getattr(ride, 'payment_status', None),
            'payment_method': getattr(ride, 'payment_method', None),
            'ride_rating': getattr(ride, 'ride_rating', None),
            'ride_feedback': getattr(ride, 'ride_feedback', None),
            'route_polyline': getattr(ride, 'route_polyline', None),
        }
        rides.append(ride_dict)
    
    return rides

@router.get("/my-rides", response_model=List[RideResponse])
async def get_my_rides(current_user: User = Depends(get_current_user), 
                      db: Session = Depends(get_database)):
    """Get rides based on user role:
    - Drivers: rides they created
    - Employees: rides they have requested seats for
    """
    if current_user.is_driver:
        # Driver: get rides they created
        rides = db.query(Ride).filter(Ride.driver_id == current_user.id).all()
        return [convert_ride_to_dict(ride) for ride in rides]
    else:
        # Employee: get rides they have requested seats for
        # Get accepted ride requests
        accepted_requests = db.query(RideRequest).filter(
            RideRequest.user_id == current_user.id,
            RideRequest.status == "accepted"
        ).all()
        
        # Get the actual rides for these requests
        ride_ids = [req.ride_id for req in accepted_requests]
        rides = db.query(Ride).filter(Ride.id.in_(ride_ids)).all()
        return [convert_ride_to_dict(ride) for ride in rides]

# Driver functionality endpoints - MUST come before {ride_id} routes
@router.get("/available-for-drivers", response_model=List[RideResponse])
async def get_rides_available_for_drivers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database),
    limit: int = 50
):
    """Get rides available for drivers to offer to drive (Legacy - not needed in new flow)"""
    # This endpoint is no longer needed in the new flow
    # Drivers create rides, employees request seats
    raise HTTPException(
        status_code=status.HTTP_410_GONE,
        detail="This endpoint is deprecated. Drivers now create rides directly."
    )

@router.post("/{ride_id}/offer-driving")
async def offer_to_drive_ride(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Allow a driver to offer to drive a ride"""
    # Check if user is a driver
    if not current_user.is_driver:
        raise HTTPException(status_code=403, detail="Only drivers can offer to drive rides")
    
    # Get the ride
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if ride is available for drivers
    if ride.status != "pending":
        raise HTTPException(status_code=400, detail="Ride is not available for drivers")
    
    if ride.driver_id:
        raise HTTPException(status_code=400, detail="Ride already has a driver assigned")
    
    # Check if user is trying to drive their own ride
    if ride.driver_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot drive your own ride")
    
    # Check if user already made an offer
    existing_offer = db.query(RideRequest).filter(
        RideRequest.ride_id == ride_id,
        RideRequest.user_id == current_user.id,
        RideRequest.status == "driver_offer"
    ).first()
    
    if existing_offer:
        raise HTTPException(status_code=400, detail="You already offered to drive this ride")
    
    # Create a driver offer
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

@router.get("/driver/offers", response_model=List[RideRequestResponse])
async def get_driver_offers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Get all driver offers made by the current user"""
    # Check if user is a driver
    if not current_user.is_driver:
        raise HTTPException(status_code=403, detail="Only drivers can access this endpoint")
    
    offers = db.query(RideRequest).filter(
        RideRequest.user_id == current_user.id,
        RideRequest.status == "driver_offer"
    ).all()
    
    return offers

@router.post("/{ride_id}/assign-driver")
async def assign_driver_to_ride(
    ride_id: str,
    driver_data: dict = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Assign a driver to a ride (ride creator or admin only)"""
    try:
        driver_id = driver_data.get('driver_id')
        if not driver_id:
            raise HTTPException(status_code=400, detail="driver_id is required")
        
        print(f"DEBUG: Assigning driver {driver_id} to ride {ride_id}")
        print(f"DEBUG: Current user: {current_user.id}, role: {current_user.role}")
        
        ride = db.query(Ride).filter(Ride.id == ride_id).first()
        if not ride:
            raise HTTPException(status_code=404, detail="Ride not found")
        
        print(f"DEBUG: Found ride: {ride.id}, driver_id: {ride.driver_id}, status: {ride.status}")
        
        # Only ride creator or admin can assign drivers
        if ride.driver_id != current_user.id and current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Not authorized to assign drivers")
        
        # Verify driver exists and is a driver
        driver = db.query(User).filter(
            User.id == driver_id,
            User.company_id == current_user.company_id,
            User.is_driver == True,
            User.is_active == True
        ).first()
        
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found or not available")
        
        print(f"DEBUG: Found driver: {driver.id}, name: {driver.name}, is_driver: {driver.is_driver}")
        
        # Check if driver has offered to drive this ride
        driver_offer = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.user_id == driver_id,
            RideRequest.status == "driver_offer"
        ).first()
        
        if not driver_offer:
            raise HTTPException(status_code=400, detail="Driver must offer to drive before being assigned")
        
        print(f"DEBUG: Found driver offer: {driver_offer.id}, status: {driver_offer.status}")
        
        # Update ride with driver assignment
        ride.driver_id = driver_id
        ride.status = "assigned"
        ride.updated_at = datetime.now(timezone.utc)
        
        # Update driver offer status
        driver_offer.status = "accepted"
        driver_offer.updated_at = datetime.now(timezone.utc)
        
        db.commit()
        db.refresh(ride)
        
        print(f"DEBUG: Successfully assigned driver {driver.name} to ride")
        return {"message": f"Driver {driver.name} assigned to ride successfully"}
        
    except Exception as e:
        print(f"DEBUG: Error in assign_driver_to_ride: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

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

    # Check authorization: driver can see their own rides, passengers can see confirmed rides
    if ride.driver_id == current_user.id:
        # Driver: get ride details
        return convert_ride_to_dict(ride)
    else:
        # Check if user has a confirmed request for this ride
        user_request = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.user_id == current_user.id
        ).first()
        
        if user_request and user_request.status == "accepted":
            # Confirmed passenger: get ride details
            return convert_ride_to_dict(ride)
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view this ride"
            )

@router.put("/{ride_id}", response_model=RideResponse)
async def update_ride(ride_id: str, ride_update: RideUpdate, 
                     current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Update a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.driver_id == current_user.id
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

    return convert_ride_to_dict(ride)

@router.delete("/{ride_id}")
async def delete_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                     db: Session = Depends(get_database)):
    """Delete a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.driver_id == current_user.id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    db.delete(ride)
    db.commit()

    return {"message": "Ride deleted successfully"}

@router.post("/{ride_id}/request", response_model=RideRequestResponse)
async def request_ride(ride_id: str, request_data: RideRequestCreate, 
                      current_user: User = Depends(get_current_user), 
                      db: Session = Depends(get_database)):
    """Request to join a ride (Employee only)"""
    # Only employees can request seats (not drivers)
    if current_user.is_driver:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Drivers cannot request seats. They create rides."
        )

    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Check if ride is available for requests
    if ride.status != "available":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is not available for requests"
        )

    # Check if ride has available capacity
    if ride.confirmed_passengers >= ride.vehicle_capacity:
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
        user_id=current_user.id,  # User requesting seat
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
    """Accept a ride request (Driver only)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Only the driver who created the ride can accept requests
    if ride.driver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the driver who created this ride can accept requests"
        )

    # Check if ride is still available for requests
    if ride.status != "available":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is no longer available for requests"
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

    # Check if ride has available capacity
    if ride.confirmed_passengers >= ride.vehicle_capacity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride is full"
        )

    # Accept the request
    ride_request.status = "accepted"
    ride.confirmed_passengers += 1
    
    # If this is the first accepted request, change status to "confirmed"
    if ride.confirmed_passengers == 1:
        ride.status = "confirmed"
    
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
    # 1. Ride creator (driver)
    # 2. Assigned driver for this ride
    # 3. Admin
    if (ride.driver_id != current_user.id and 
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
    ride.confirmed_passengers += 1
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
    if (ride.driver_id != current_user.id and 
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

# New endpoints for ride lifecycle management
@router.post("/{ride_id}/start", response_model=RideResponse)
async def start_ride(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Start a ride (Driver only) - Follows flow: confirmed → in_progress"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is the driver who created the ride
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the driver who created this ride can start it")
    
    # Check if ride is in correct status (must be confirmed)
    if ride.status != "confirmed":
        raise HTTPException(
            status_code=400, 
            detail=f"Ride must be confirmed before starting. Current status: {ride.status}"
        )
    
    # Check if ride has confirmed passengers
    if ride.confirmed_passengers == 0:
        raise HTTPException(
            status_code=400, 
            detail="Cannot start ride without confirmed passengers"
        )
    
    # Update ride status and start time
    ride.status = "in_progress"
    ride.actual_start_time = datetime.now(timezone.utc)
    ride.ride_progress = 0.0
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/update-progress", response_model=RideResponse)
async def update_ride_progress(
    ride_id: str,
    progress_update: RideProgressUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Update ride progress and location (driver only)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is the assigned driver
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only assigned driver can update ride progress")
    
    # Check if ride is in progress
    if ride.status != "in_progress":
        raise HTTPException(status_code=400, detail="Ride must be in progress to update")
    
    # Update ride progress
    if progress_update.current_latitude is not None:
        ride.current_latitude = progress_update.current_latitude
    if progress_update.current_longitude is not None:
        ride.current_longitude = progress_update.current_longitude
    if progress_update.ride_progress is not None:
        ride.ride_progress = progress_update.ride_progress
    if progress_update.estimated_pickup_time is not None:
        ride.estimated_pickup_time = progress_update.estimated_pickup_time
    if progress_update.estimated_dropoff_time is not None:
        ride.estimated_dropoff_time = progress_update.estimated_dropoff_time
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/pickup", response_model=RideResponse)
async def pickup_passenger(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Mark passenger as picked up (driver only)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is the assigned driver
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only assigned driver can pickup passenger")
    
    # Check if ride is in progress
    if ride.status != "in_progress":
        raise HTTPException(status_code=400, detail="Ride must be in progress to pickup passenger")
    
    # Update pickup time and progress
    ride.pickup_time = datetime.now(timezone.utc)
    ride.ride_progress = 0.5  # 50% complete after pickup
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/complete", response_model=RideResponse)
async def complete_ride(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Complete a ride (Driver only) - Follows flow: in_progress → completed"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is the driver who created the ride
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the driver who created this ride can complete it")
    
    # Check if ride is in progress
    if ride.status != "in_progress":
        raise HTTPException(
            status_code=400, 
            detail=f"Ride must be in progress to complete. Current status: {ride.status}"
        )
    
    # Calculate duration and update ride
    if ride.actual_start_time:
        duration = int((datetime.now(timezone.utc) - ride.actual_start_time).total_seconds() / 60)
        ride.duration = duration
    
    ride.status = "completed"
    ride.actual_end_time = datetime.now(timezone.utc)
    ride.dropoff_time = datetime.now(timezone.utc)
    ride.ride_progress = 1.0  # 100% complete
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/cancel", response_model=RideResponse)
async def cancel_ride(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Cancel a ride (Driver only)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Only the driver who created the ride can cancel it
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the driver who created this ride can cancel it")
    
    # Check if ride can be cancelled
    if ride.status in ["completed", "cancelled"]:
        raise HTTPException(status_code=400, detail="Ride cannot be cancelled in current status")
    
    # If ride has confirmed passengers, reject all pending requests
    if ride.confirmed_passengers > 0:
        pending_requests = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.status == "pending"
        ).all()
        
        for request in pending_requests:
            request.status = "cancelled"
    
    ride.status = "cancelled"
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/location", response_model=RideLocationResponse)
async def update_ride_location(
    ride_id: str,
    location_update: RideLocationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Update ride location (real-time tracking)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is part of the ride (driver or confirmed passenger)
    if ride.driver_id != current_user.id:
        # Check if user is a confirmed passenger
        confirmed_request = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.user_id == current_user.id,
            RideRequest.status == "accepted"
        ).first()
        
        if not confirmed_request:
            raise HTTPException(status_code=403, detail="Only ride participants can update location")
    
    # Create new location record
    ride_location = RideLocation(
        ride_id=ride_id,
        user_id=current_user.id,
        latitude=location_update.latitude,
        longitude=location_update.longitude,
        accuracy=location_update.accuracy,
        speed=location_update.speed,
        heading=location_update.heading,
        is_driver=location_update.is_driver
    )
    
    db.add(ride_location)
    db.commit()
    db.refresh(ride_location)
    
    return ride_location

@router.get("/{ride_id}/location", response_model=List[RideLocationResponse])
async def get_ride_locations(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database),
    limit: int = 100
):
    """Get ride location history"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is part of the ride
    if ride.driver_id != current_user.id:
        # Check if user is a confirmed passenger
        confirmed_request = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.user_id == current_user.id,
            RideRequest.status == "accepted"
        ).first()
        
        if not confirmed_request:
            raise HTTPException(status_code=403, detail="Only ride participants can view locations")
    
    locations = db.query(RideLocation)\
        .filter(RideLocation.ride_id == ride_id)\
        .order_by(RideLocation.timestamp.desc())\
        .limit(limit)\
        .all()
    
    return locations

@router.post("/{ride_id}/payment", response_model=RideResponse)
async def update_payment_status(
    ride_id: str,
    payment_update: RidePaymentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Update ride payment status"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Check if user is the driver or a confirmed passenger
    if ride.driver_id != current_user.id:
        # Check if user is a confirmed passenger
        confirmed_request = db.query(RideRequest).filter(
            RideRequest.ride_id == ride_id,
            RideRequest.user_id == current_user.id,
            RideRequest.status == "accepted"
        ).first()
        
        if not confirmed_request:
            raise HTTPException(status_code=403, detail="Only ride participants can update payment")
    
    # Update payment information
    ride.payment_status = payment_update.payment_status
    if payment_update.payment_method:
        ride.payment_method = payment_update.payment_method
    if payment_update.fare:
        ride.fare = payment_update.fare
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

@router.post("/{ride_id}/rate", response_model=RideResponse)
async def rate_ride(
    ride_id: str,
    rating_data: RideRating,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Rate a completed ride (Employee only) - Only after completion"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Only employees can rate rides (not drivers)
    if current_user.is_driver:
        raise HTTPException(status_code=403, detail="Drivers cannot rate rides")
    
    # Check if ride is completed
    if ride.status != "completed":
        raise HTTPException(
            status_code=400, 
            detail="Can only rate completed rides"
        )
    
    # Check if user was a confirmed passenger on this ride
    confirmed_request = db.query(RideRequest).filter(
        RideRequest.ride_id == ride_id,
        RideRequest.user_id == current_user.id,
        RideRequest.status == "accepted"
    ).first()
    
    if not confirmed_request:
        raise HTTPException(
            status_code=403, 
            detail="Only confirmed passengers can rate this ride"
        )
    
    # Check if user already rated this ride
    if ride.ride_rating is not None:
        raise HTTPException(
            status_code=400, 
            detail="You have already rated this ride"
        )
    
    # Update ride with rating
    ride.ride_rating = rating_data.rating
    ride.ride_feedback = rating_data.feedback
    
    db.commit()
    db.refresh(ride)
    
    return convert_ride_to_dict(ride)

# Dashboard endpoints for Driver and Employee roles
@router.get("/driver/dashboard", response_model=dict)
async def get_driver_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Get driver dashboard with filtered rides"""
    if not current_user.is_driver:
        raise HTTPException(status_code=403, detail="Only drivers can access driver dashboard")
    
    # Get rides created by this driver with different statuses
    upcoming_rides = db.query(Ride).filter(
        Ride.driver_id == current_user.id,
        Ride.status == "confirmed",
        Ride.scheduled_time > datetime.now(timezone.utc)
    ).all()
    
    scheduled_rides = db.query(Ride).filter(
        Ride.driver_id == current_user.id,
        Ride.status == "available"
    ).all()
    
    completed_rides = db.query(Ride).filter(
        Ride.driver_id == current_user.id,
        Ride.status == "completed"
    ).all()
    
    # Get pending ride requests for driver's rides
    pending_requests = db.query(RideRequest).join(Ride).filter(
        Ride.driver_id == current_user.id,
        RideRequest.status == "pending"
    ).all()
    
    # Convert RideRequest objects to dictionaries
    pending_requests_dict = []
    for request in pending_requests:
        # Get user information for the request
        user = db.query(User).filter(User.id == request.user_id).first()
        request_dict = {
            'id': request.id,
            'ride_id': request.ride_id,
            'user_id': request.user_id,
            'status': request.status,
            'message': request.message,
            'created_at': request.created_at,
            'user_name': user.name if user else None,
            'user_email': user.email if user else None
        }
        pending_requests_dict.append(request_dict)
    
    return {
        "upcoming_rides": len(upcoming_rides),
        "scheduled_rides": len(scheduled_rides),
        "completed_rides": len(completed_rides),
        "pending_requests": pending_requests_dict,
        "rides": {
            "upcoming": [convert_ride_to_dict(ride) for ride in upcoming_rides],
            "scheduled": [convert_ride_to_dict(ride) for ride in scheduled_rides],
            "completed": [convert_ride_to_dict(ride) for ride in completed_rides]
        }
    }

@router.get("/employee/dashboard", response_model=dict)
async def get_employee_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Get employee dashboard with filtered rides"""
    if current_user.is_driver:
        raise HTTPException(status_code=403, detail="Drivers cannot access employee dashboard")
    
    # Get upcoming rides (confirmed requests)
    upcoming_rides = db.query(Ride).join(RideRequest).filter(
        RideRequest.user_id == current_user.id,
        RideRequest.status == "accepted",
        Ride.status.in_(["confirmed", "in_progress"])
    ).all()
    
    # Get scheduled requests (pending) - return the actual rides
    scheduled_rides = db.query(Ride).join(RideRequest).filter(
        RideRequest.user_id == current_user.id,
        RideRequest.status == "pending"
    ).all()
    
    # Get completed rides
    completed_rides = db.query(Ride).join(RideRequest).filter(
        RideRequest.user_id == current_user.id,
        RideRequest.status == "accepted",
        Ride.status == "completed"
    ).all()
    
    # Get cancelled rides
    cancelled_rides = db.query(Ride).join(RideRequest).filter(
        RideRequest.user_id == current_user.id,
        RideRequest.status == "cancelled"
    ).all()
    
    return {
        "upcoming_rides": len(upcoming_rides),
        "scheduled_rides": len(scheduled_rides),
        "completed_rides": len(completed_rides),
        "cancelled_rides": len(cancelled_rides),
        "rides": {
            "upcoming": [convert_ride_to_dict(ride) for ride in upcoming_rides],
            "scheduled_rides": [convert_ride_to_dict(ride) for ride in scheduled_rides],
            "completed": [convert_ride_to_dict(ride) for ride in completed_rides],
            "cancelled": cancelled_rides
        }
    }

@router.get("/{ride_id}/requests", response_model=List[RideRequestResponse])
async def get_ride_requests(
    ride_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_database)
):
    """Get all requests for a specific ride (Driver only)"""
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(status_code=404, detail="Ride not found")
    
    # Only the driver who created the ride can see requests
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the driver who created this ride can view requests")
    
    # Get all requests for this ride with user information
    requests = db.query(RideRequest, User.name.label('user_name'), User.email.label('user_email'))\
                 .join(User, RideRequest.user_id == User.id)\
                 .filter(RideRequest.ride_id == ride_id)\
                 .all()
    
    # Convert to RideRequestResponse format
    ride_requests = []
    for request, user_name, user_email in requests:
        request_dict = {
            'id': request.id,
            'ride_id': request.ride_id,
            'message': request.message,
            'user_id': request.user_id,
            'status': request.status,
            'created_at': request.created_at,
            'user_name': user_name,
            'user_email': user_email
        }
        ride_requests.append(request_dict)
    
    return ride_requests

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
