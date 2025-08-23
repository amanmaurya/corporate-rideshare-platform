from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Text, Integer
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

class Ride(Base):
    __tablename__ = "rides"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    company_id = Column(String, ForeignKey("companies.id"), nullable=False)
    rider_id = Column(String, ForeignKey("users.id"), nullable=False)
    driver_id = Column(String, ForeignKey("users.id"), nullable=True)
    pickup_location = Column(Text, nullable=False)
    destination = Column(Text, nullable=False)
    pickup_latitude = Column(Float, nullable=False)
    pickup_longitude = Column(Float, nullable=False)
    destination_latitude = Column(Float, nullable=False)
    destination_longitude = Column(Float, nullable=False)
    scheduled_time = Column(DateTime(timezone=True), nullable=True)
    actual_start_time = Column(DateTime(timezone=True), nullable=True)
    actual_end_time = Column(DateTime(timezone=True), nullable=True)
    status = Column(String, default="pending")  # pending, matched, in_progress, completed, cancelled
    fare = Column(Float, nullable=True)
    distance = Column(Float, nullable=True)
    duration = Column(Integer, nullable=True)  # in minutes
    actual_duration = Column(Integer, nullable=True)  # actual duration in minutes
    max_passengers = Column(Integer, default=4)
    current_passengers = Column(Integer, default=1)
    notes = Column(Text, nullable=True)
    payment_status = Column(String, default="pending")  # pending, completed, failed, refunded
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    company = relationship("Company", back_populates="rides")
    rider = relationship("User", foreign_keys=[rider_id], back_populates="rides_as_rider")
    driver = relationship("User", foreign_keys=[driver_id], back_populates="rides_as_driver")
    ride_requests = relationship("RideRequest", back_populates="ride")

class RideRequest(Base):
    __tablename__ = "ride_requests"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ride_id = Column(String, ForeignKey("rides.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    status = Column(String, default="pending")  # pending, accepted, declined
    message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    ride = relationship("Ride", back_populates="ride_requests")
    user = relationship("User", back_populates="ride_requests")
