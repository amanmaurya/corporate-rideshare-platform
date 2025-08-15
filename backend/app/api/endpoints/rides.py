from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
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
    query = db.query(Ride).filter(Ride.company_id == current_user.company_id)

    if status:
        query = query.filter(Ride.status == status)

    rides = query.limit(limit).all()
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

@router.post("/{ride_id}/accept")
async def accept_ride_request(ride_id: str, request_id: str, 
                            current_user: User = Depends(get_current_user), 
                            db: Session = Depends(get_database)):
    """Accept a ride request (for ride creator)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.rider_id == current_user.id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    ride_request = db.query(RideRequest).filter(
        RideRequest.id == request_id,
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

@router.post("/{ride_id}/start")
async def start_ride(ride_id: str, current_user: User = Depends(get_current_user), 
                    db: Session = Depends(get_database)):
    """Start a ride (for ride creator)"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.rider_id == current_user.id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or not authorized"
        )

    if ride.status != "matched":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride must be matched before starting"
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
        Ride.rider_id == current_user.id
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
    
    # Calculate actual fare based on distance
    actual_distance = location_service.calculate_distance(
        ride.pickup_latitude, ride.pickup_longitude,
        ride.destination_latitude, ride.destination_longitude
    )
    ride.actual_fare = location_service.calculate_fare(actual_distance)
    
    db.commit()

    return {"message": "Ride completed successfully", "fare": ride.actual_fare}

@router.get("/nearby/drivers")
async def find_nearby_drivers(current_user: User = Depends(get_current_user), 
                             db: Session = Depends(get_database),
                             latitude: float = None,
                             longitude: float = None,
                             radius_km: float = 5.0):
    """Find nearby available drivers"""
    if not latitude or not longitude:
        # Use user's current location
        latitude = current_user.latitude
        longitude = current_user.longitude

    # Get all drivers in the company
    drivers = db.query(User).filter(
        User.company_id == current_user.company_id,
        User.is_driver == True,
        User.is_active == True
    ).all()

    # Convert to list of dicts for location service
    driver_points = []
    for driver in drivers:
        if driver.latitude and driver.longitude:
            driver_points.append({
                "id": driver.id,
                "name": driver.name,
                "latitude": driver.latitude,
                "longitude": driver.longitude,
                "rating": driver.rating,
                "is_available": True  # This should come from driver status
            })

    # Find nearby drivers
    nearby_drivers = location_service.find_nearby_points(
        latitude, longitude, driver_points, radius_km
    )

    return {
        "nearby_drivers": nearby_drivers,
        "search_center": {"latitude": latitude, "longitude": longitude},
        "search_radius_km": radius_km
    }

@router.post("/{ride_id}/update-location")
async def update_ride_location(ride_id: str, 
                             latitude: float, 
                             longitude: float,
                             current_user: User = Depends(get_current_user), 
                             db: Session = Depends(get_database)):
    """Update current location during a ride"""
    ride = db.query(Ride).filter(
        Ride.id == ride_id,
        Ride.company_id == current_user.company_id
    ).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found"
        )

    # Update user's location
    current_user.latitude = latitude
    current_user.longitude = longitude
    current_user.updated_at = datetime.utcnow()
    db.commit()

    return {"message": "Location updated successfully"}
