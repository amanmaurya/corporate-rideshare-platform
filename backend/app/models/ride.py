from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Text, Integer, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

class Ride(Base):
    __tablename__ = "rides"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    company_id = Column(String, ForeignKey("companies.id"), nullable=False)
    driver_id = Column(String, ForeignKey("users.id"), nullable=False)  # Driver creates the ride
    pickup_location = Column(Text, nullable=False)
    destination = Column(Text, nullable=False)
    pickup_latitude = Column(Float, nullable=False)
    pickup_longitude = Column(Float, nullable=False)
    destination_latitude = Column(Float, nullable=False)
    destination_longitude = Column(Float, nullable=False)
    scheduled_time = Column(DateTime(timezone=True), nullable=True)
    actual_start_time = Column(DateTime(timezone=True), nullable=True)
    actual_end_time = Column(DateTime(timezone=True), nullable=True)
    
    # Strict status flow: Available → Confirmed → In Progress → Completed
    status = Column(String, default="available")  # available, confirmed, in_progress, completed, cancelled
    
    fare = Column(Float, nullable=True)
    distance = Column(Float, nullable=True)
    duration = Column(Integer, nullable=True)  # in minutes
    
    # Vehicle capacity management
    vehicle_capacity = Column(Integer, nullable=False)  # Total seats in vehicle
    confirmed_passengers = Column(Integer, default=0)  # Number of confirmed passengers
    
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Ride progress tracking
    current_latitude = Column(Float, nullable=True)
    current_longitude = Column(Float, nullable=True)
    pickup_time = Column(DateTime(timezone=True), nullable=True)
    dropoff_time = Column(DateTime(timezone=True), nullable=True)
    estimated_pickup_time = Column(DateTime(timezone=True), nullable=True)
    estimated_dropoff_time = Column(DateTime(timezone=True), nullable=True)
    ride_progress = Column(Float, default=0.0)  # 0.0 to 1.0 (0% to 100%)
    
    # Payment and rating (only after completion)
    payment_status = Column(String, default="pending")  # pending, paid, failed
    payment_method = Column(String, nullable=True)  # cash, card, wallet
    ride_rating = Column(Float, nullable=True)  # Rider rating for the driver
    ride_feedback = Column(Text, nullable=True)  # Rider feedback
    route_polyline = Column(Text, nullable=True)  # Google Maps polyline for route

    # Relationships
    company = relationship("Company", back_populates="rides")
    driver = relationship("User", foreign_keys=[driver_id], back_populates="rides_as_driver")
    ride_requests = relationship("RideRequest", back_populates="ride")
    ride_locations = relationship("RideLocation", back_populates="ride")

class RideRequest(Base):
    __tablename__ = "ride_requests"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ride_id = Column(String, ForeignKey("rides.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)  # User requesting seat
    status = Column(String, default="pending")  # pending, accepted, rejected, cancelled
    message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    ride = relationship("Ride", back_populates="ride_requests")
    user = relationship("User", foreign_keys=[user_id], back_populates="ride_requests")

class RideLocation(Base):
    __tablename__ = "ride_locations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ride_id = Column(String, ForeignKey("rides.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)  # Driver or rider
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    accuracy = Column(Float, nullable=True)
    speed = Column(Float, nullable=True)  # Speed in km/h
    heading = Column(Float, nullable=True)  # Direction in degrees
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    is_driver = Column(Boolean, default=False)  # True if this is driver location

    # Relationships
    ride = relationship("Ride", back_populates="ride_locations")
    user = relationship("User", foreign_keys=[user_id], back_populates="ride_locations")
