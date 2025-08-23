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
    notes: Optional[str] = None
    max_passengers: Optional[int] = 4

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
    notes: Optional[str] = None
    max_passengers: Optional[int] = None
    status: Optional[str] = None

class RideResponse(RideBase):
    id: str
    company_id: str
    rider_id: str
    driver_id: Optional[str] = None
    status: str
    fare: Optional[float] = None
    distance: Optional[float] = None
    duration: Optional[int] = None
    current_passengers: int
    actual_start_time: Optional[datetime] = None
    actual_end_time: Optional[datetime] = None
    created_at: datetime
    rider_name: Optional[str] = None
    rider_email: Optional[str] = None

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
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class RideMatch(BaseModel):
    ride_id: str
    driver_name: str
    driver_phone: str
    pickup_time: datetime
    distance_to_pickup: float
    compatibility_score: float
