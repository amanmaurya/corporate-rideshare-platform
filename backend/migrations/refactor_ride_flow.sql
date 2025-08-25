-- Migration: Refactor Ride Flow to Strict Driver/Employee Roles
-- Date: 2025-08-23
-- Description: Update rides table to follow strict flow: Available → Confirmed → In Progress → Completed

-- Step 1: Add new columns
ALTER TABLE rides ADD COLUMN IF NOT EXISTS vehicle_capacity INTEGER NOT NULL DEFAULT 4;
ALTER TABLE rides ADD COLUMN IF NOT EXISTS confirmed_passengers INTEGER NOT NULL DEFAULT 0;

-- Step 2: Update existing rides to have driver_id (required field)
-- Note: This assumes existing rides have a driver assigned
UPDATE rides SET driver_id = rider_id WHERE driver_id IS NULL;

-- Step 3: Make driver_id NOT NULL
ALTER TABLE rides ALTER COLUMN driver_id SET NOT NULL;

-- Step 4: Update status values to match new flow
UPDATE rides SET status = 'available' WHERE status = 'pending';
UPDATE rides SET status = 'confirmed' WHERE status = 'assigned';
UPDATE rides SET status = 'in_progress' WHERE status = 'in_progress';
UPDATE rides SET status = 'completed' WHERE status = 'completed';

-- Step 5: Update ride_requests table
ALTER TABLE ride_requests RENAME COLUMN user_id TO employee_id;

-- Step 6: Update status values in ride_requests
UPDATE ride_requests SET status = 'rejected' WHERE status = 'declined';

-- Step 7: Add constraints to ensure proper flow
ALTER TABLE rides ADD CONSTRAINT check_ride_status 
    CHECK (status IN ('available', 'confirmed', 'in_progress', 'completed', 'cancelled'));

ALTER TABLE rides ADD CONSTRAINT check_passenger_capacity 
    CHECK (confirmed_passengers <= vehicle_capacity);

ALTER TABLE ride_requests ADD CONSTRAINT check_request_status 
    CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled'));

-- Step 8: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_rides_driver_id ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_company_id ON rides(company_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_employee_id ON ride_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests(status);

-- Step 9: Update existing data to match new schema
-- Set confirmed_passengers based on accepted ride requests
UPDATE rides 
SET confirmed_passengers = (
    SELECT COUNT(*) 
    FROM ride_requests 
    WHERE ride_requests.ride_id = rides.id 
    AND ride_requests.status = 'accepted'
);

-- Step 10: Remove old columns that are no longer needed
-- Note: Keep these commented out until we're sure the migration works
-- ALTER TABLE rides DROP COLUMN IF EXISTS rider_id;
-- ALTER TABLE rides DROP COLUMN IF EXISTS max_passengers;
-- ALTER TABLE rides DROP COLUMN IF EXISTS current_passengers;

