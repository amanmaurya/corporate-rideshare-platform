-- Migration to fix user_id field in ride_requests table
-- Change employee_id back to user_id to maintain compatibility

-- Rename the column from employee_id to user_id
ALTER TABLE ride_requests RENAME COLUMN employee_id TO user_id;

-- Drop the old index
DROP INDEX IF EXISTS idx_ride_requests_employee_id;

-- Create new index on user_id
CREATE INDEX idx_ride_requests_user_id ON ride_requests(user_id);

-- Update the foreign key constraint name to match
ALTER TABLE ride_requests DROP CONSTRAINT IF EXISTS ride_requests_user_id_fkey;
ALTER TABLE ride_requests ADD CONSTRAINT ride_requests_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id);

-- Verify the change
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'ride_requests' AND column_name = 'user_id';
