-- Initialize Corporate RideShare Database
-- This script creates the PostGIS extension and sample data if it doesn't exist
--
-- Test Credentials:
-- Admin: admin@techcorp.com / admin123
-- User: john.doe@techcorp.com / user123  
-- Driver: mike.driver@techcorp.com / driver123
-- Company ID: company-1

-- Create extension for PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create a function to insert sample data
CREATE OR REPLACE FUNCTION insert_sample_data_if_needed()
RETURNS void AS $$
BEGIN
    -- Check if sample company exists, if not insert it
    IF NOT EXISTS (SELECT 1 FROM companies WHERE id = 'company-1') THEN
        INSERT INTO companies (id, name, address, latitude, longitude, contact_email, contact_phone, settings, logo_url, is_active, created_at, updated_at)
        VALUES (
            'company-1',
            'TechCorp Inc.',
            '123 Innovation Drive, Tech City, TC 12345',
            37.7749,
            -122.4194,
            'admin@techcorp.com',
            '+1-555-0123',
            '{"max_ride_distance": 50, "fare_base_rate": 2.0}',
            'https://via.placeholder.com/150x50/007bff/ffffff?text=TechCorp',
            true,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Sample company inserted';
    ELSE
        RAISE NOTICE 'Sample company already exists';
    END IF;

    -- Check if sample admin user exists, if not insert it
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'user-admin-1') THEN
        INSERT INTO users (id, name, email, phone, department, role, company_id, hashed_password, is_driver, is_active, latitude, longitude, profile_picture, rating, total_rides, created_at, updated_at)
        VALUES (
            'user-admin-1',
            'Admin User',
            'admin@techcorp.com',
            '+1-555-0001',
            'IT',
            'admin',
            'company-1',
            '$2b$12$oOMU0T4iWR0riNGFBtdaX.1fcbawNFpL4KP9IJLbWtIK9Tq0ycUr6', -- password: admin123
            false,
            true,
            37.7749,
            -122.4194,
            'https://via.placeholder.com/100x100/007bff/ffffff?text=A',
            5.0,
            0,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Sample admin user inserted';
    ELSE
        RAISE NOTICE 'Sample admin user already exists';
    END IF;

    -- Check if sample regular user exists, if not insert it
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'user-1') THEN
        INSERT INTO users (id, name, email, phone, department, role, company_id, hashed_password, is_driver, is_active, latitude, longitude, profile_picture, rating, total_rides, created_at, updated_at)
        VALUES (
            'user-1',
            'John Doe',
            'john.doe@techcorp.com',
            '+1-555-0002',
            'Engineering',
            'employee',
            'company-1',
            '$2b$12$SSAkwYEeGvtr/D7zlZah6e.OhH6fANf4X.5IcNuNRIAGc5KGqgDkG', -- password: user123
            false,
            true,
            37.7849,
            -122.4094,
            'https://via.placeholder.com/100x100/28a745/ffffff?text=J',
            4.8,
            5,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Sample regular user inserted';
    ELSE
        RAISE NOTICE 'Sample regular user already exists';
    END IF;

    -- Check if sample driver exists, if not insert it
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = 'driver-1') THEN
        INSERT INTO users (id, name, email, phone, department, role, company_id, hashed_password, is_driver, is_active, latitude, longitude, profile_picture, rating, total_rides, created_at, updated_at)
        VALUES (
            'driver-1',
            'Mike Driver',
            'mike.driver@techcorp.com',
            '+1-555-0003',
            'Transportation',
            'driver',
            'company-1',
            '$2b$12$YGrnBpBph.ePM48oKFzK9edEu3qF5i/p9ue2XnLnLrbSCydwjQt/y', -- password: driver123
            true,
            true,
            37.7649,
            -122.4294,
            'https://via.placeholder.com/100x100/dc3545/ffffff?text=M',
            4.9,
            25,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Sample driver inserted';
    ELSE
        RAISE NOTICE 'Sample driver already exists';
    END IF;

    -- Check if sample ride exists, if not insert it
    IF NOT EXISTS (SELECT 1 FROM rides WHERE id = 'ride-1') THEN
        INSERT INTO rides (id, company_id, rider_id, driver_id, pickup_location, destination, pickup_latitude, pickup_longitude, destination_latitude, destination_longitude, scheduled_time, status, fare, distance, max_passengers, current_passengers, notes, created_at, updated_at)
        VALUES (
            'ride-1',
            'company-1',
            'user-1',
            'driver-1',
            'TechCorp Office',
            'Downtown Conference Center',
            37.7749,
            -122.4194,
            37.7849,
            -122.4094,
            NOW() + INTERVAL '1 hour',
            'matched',
            15.50,
            2.5,
            4,
            1,
            'Business meeting',
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Sample ride inserted';
    ELSE
        RAISE NOTICE 'Sample ride already exists';
    END IF;

    RAISE NOTICE 'Sample data check completed';
END;
$$ LANGUAGE plpgsql;

-- Note: This function will be called by the backend after tables are created
-- The backend will execute: SELECT insert_sample_data_if_needed();
