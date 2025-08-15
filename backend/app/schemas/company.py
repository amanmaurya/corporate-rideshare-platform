from pydantic import BaseModel, EmailStr
from typing import Optional, Dict, Any
from datetime import datetime

class CompanyBase(BaseModel):
    name: str
    address: str
    latitude: float
    longitude: float
    contact_email: EmailStr
    contact_phone: str

class CompanyCreate(CompanyBase):
    settings: Optional[Dict[str, Any]] = {}
    logo_url: Optional[str] = None

class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None
    logo_url: Optional[str] = None

class CompanyResponse(CompanyBase):
    id: str
    settings: Dict[str, Any]
    logo_url: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
