-- Migration: Add ride lifecycle management fields
-- Date: 2024-01-XX
-- Description: Add new fields to support complete ride lifecycle management

-- Add new fields to rides table
ALTER TABLE rides 
ADD COLUMN IF NOT EXISTS current_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS current_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS pickup_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS dropoff_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS estimated_pickup_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS estimated_dropoff_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS ride_progress DOUBLE PRECISION DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
ADD COLUMN IF NOT EXISTS ride_rating DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS ride_feedback TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact TEXT,
ADD COLUMN IF NOT EXISTS route_polyline TEXT;

-- Create new ride_locations table for real-time tracking
CREATE TABLE IF NOT EXISTS ride_locations (
    id VARCHAR(255) PRIMARY KEY,
    ride_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_driver BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ride_locations_ride_id ON ride_locations(ride_id);
CREATE INDEX IF NOT EXISTS idx_ride_locations_user_id ON ride_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_ride_locations_timestamp ON ride_locations(timestamp);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_payment_status ON rides(payment_status);

-- Update existing rides to have default values
UPDATE rides SET 
    ride_progress = 0.0,
    payment_status = 'pending'
WHERE ride_progress IS NULL OR payment_status IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN rides.current_latitude IS 'Current ride location latitude for real-time tracking';
COMMENT ON COLUMN rides.current_longitude IS 'Current ride location longitude for real-time tracking';
COMMENT ON COLUMN rides.pickup_time IS 'When passenger was actually picked up';
COMMENT ON COLUMN rides.dropoff_time IS 'When passenger was actually dropped off';
COMMENT ON COLUMN rides.estimated_pickup_time IS 'ETA for pickup';
COMMENT ON COLUMN rides.estimated_dropoff_time IS 'ETA for destination';
COMMENT ON COLUMN rides.ride_progress IS 'Ride progress from 0.0 to 1.0 (0% to 100%)';
COMMENT ON COLUMN rides.payment_status IS 'Payment status: pending, paid, failed';
COMMENT ON COLUMN rides.payment_method IS 'Payment method: cash, card, wallet';
COMMENT ON COLUMN rides.ride_rating IS 'User rating for the ride (1.0 to 5.0)';
COMMENT ON COLUMN rides.ride_feedback IS 'User feedback about the ride';
COMMENT ON COLUMN rides.emergency_contact IS 'Emergency contact information';
COMMENT ON COLUMN rides.route_polyline IS 'Google Maps polyline for route visualization';

COMMENT ON TABLE ride_locations IS 'Real-time location tracking for rides';
COMMENT ON COLUMN ride_locations.latitude IS 'GPS latitude coordinate';
COMMENT ON COLUMN ride_locations.longitude IS 'GPS longitude coordinate';
COMMENT ON COLUMN ride_locations.accuracy IS 'GPS accuracy in meters';
COMMENT ON COLUMN ride_locations.speed IS 'Speed in km/h';
COMMENT ON COLUMN ride_locations.heading IS 'Direction in degrees (0-360)';
COMMENT ON COLUMN ride_locations.is_driver IS 'True if this is driver location, false for rider';

