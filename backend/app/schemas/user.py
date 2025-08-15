from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    name: str
    email: EmailStr
    phone: str
    department: str
    role: str
    company_id: str

class UserCreate(UserBase):
    password: str
    is_driver: bool = False

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    department: Optional[str] = None
    role: Optional[str] = None
    is_driver: Optional[bool] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str
    company_id: str

class UserResponse(UserBase):
    id: str
    is_driver: bool
    is_active: bool
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    profile_picture: Optional[str] = None
    rating: float
    total_rides: int
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse
