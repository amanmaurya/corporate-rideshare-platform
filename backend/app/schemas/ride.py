from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class RideBase(BaseModel):
    pickup_location: str
    destination: str
    pickup_latitude: float
    pickup_longitude: float
    destination_latitude: float
    destination_longitude: float
    scheduled_time: Optional[datetime] = None
    vehicle_capacity: int  # Total seats in vehicle
    notes: Optional[str] = None
    fare: Optional[float] = None

class RideCreate(RideBase):
    pass

class RideUpdate(BaseModel):
    pickup_location: Optional[str] = None
    destination: Optional[str] = None
    pickup_latitude: Optional[float] = None
    pickup_longitude: Optional[float] = None
    destination_latitude: Optional[float] = None
    destination_longitude: Optional[float] = None
    scheduled_time: Optional[datetime] = None
    vehicle_capacity: Optional[int] = None
    notes: Optional[str] = None
    fare: Optional[float] = None
    status: Optional[str] = None
    current_latitude: Optional[float] = None
    current_longitude: Optional[float] = None
    ride_progress: Optional[float] = None
    estimated_pickup_time: Optional[datetime] = None
    estimated_dropoff_time: Optional[datetime] = None

class RideResponse(RideBase):
    id: str
    company_id: str
    driver_id: str
    status: str  # available, confirmed, in_progress, completed, cancelled
    distance: Optional[float] = None
    duration: Optional[int] = None
    confirmed_passengers: int
    actual_start_time: Optional[datetime] = None
    actual_end_time: Optional[datetime] = None
    created_at: datetime
    driver_name: Optional[str] = None
    driver_email: Optional[str] = None
    
    # Ride progress tracking
    current_latitude: Optional[float] = None
    current_longitude: Optional[float] = None
    pickup_time: Optional[datetime] = None
    dropoff_time: Optional[datetime] = None
    estimated_pickup_time: Optional[datetime] = None
    estimated_dropoff_time: Optional[datetime] = None
    ride_progress: Optional[float] = None
    
    # Payment and rating (only after completion)
    payment_status: Optional[str] = None
    payment_method: Optional[str] = None
    ride_rating: Optional[float] = None
    ride_feedback: Optional[str] = None
    route_polyline: Optional[str] = None

    class Config:
        from_attributes = True

class RideRequestBase(BaseModel):
    ride_id: str
    message: Optional[str] = None

class RideRequestCreate(RideRequestBase):
    pass

class RideRequestResponse(RideRequestBase):
    id: str
    user_id: str
    status: str  # pending, accepted, rejected, cancelled
    created_at: datetime
    user_name: Optional[str] = None  # Name of the user requesting the seat
    user_email: Optional[str] = None  # Email of the user requesting the seat

    class Config:
        from_attributes = True

# Ride lifecycle management schemas
class RideLocationUpdate(BaseModel):
    ride_id: str
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    speed: Optional[float] = None
    heading: Optional[float] = None
    is_driver: bool = False

class RideLocationResponse(BaseModel):
    id: str
    ride_id: str
    user_id: str
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    speed: Optional[float] = None
    heading: Optional[float] = None
    timestamp: datetime
    is_driver: bool

    class Config:
        from_attributes = True

class RideProgressUpdate(BaseModel):
    ride_id: str
    status: str  # Must follow: available → confirmed → in_progress → completed
    current_latitude: Optional[float] = None
    current_longitude: Optional[float] = None
    ride_progress: Optional[float] = None
    estimated_pickup_time: Optional[datetime] = None
    estimated_dropoff_time: Optional[datetime] = None

class RidePaymentUpdate(BaseModel):
    ride_id: str
    payment_status: str  # pending, paid, failed
    payment_method: Optional[str] = None
    fare: Optional[float] = None

class RideRating(BaseModel):
    ride_id: str
    rating: float  # 1.0 to 5.0
    feedback: Optional[str] = None
