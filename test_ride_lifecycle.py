#!/usr/bin/env python3
"""
Test script for Ride Lifecycle Management
Tests the complete ride flow: create -> assign -> start -> progress -> pickup -> complete
"""

import requests
import json
import time
from datetime import datetime, timedelta, timezone

# Configuration
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/v1"

# Test data
TEST_COMPANY_ID = "company-1"
TEST_ADMIN = {
    "email": "admin@techcorp.com",
    "password": "admin123",
    "company_id": TEST_COMPANY_ID
}
TEST_DRIVER = {
    "email": "mike.driver@techcorp.com",
    "password": "driver123",
    "company_id": TEST_COMPANY_ID
}
TEST_RIDER = {
    "email": "john.doe@techcorp.com",
    "password": "user123",
    "company_id": TEST_COMPANY_ID
}

class RideLifecycleTester:
    def __init__(self):
        self.admin_token = None
        self.driver_token = None
        self.rider_token = None
        self.test_ride_id = None
        self.test_request_id = None
        
    def login_user(self, credentials):
        """Login user and return token"""
        response = requests.post(
            f"{API_BASE}/auth/login",
            json=credentials
        )
        
        if response.status_code == 200:
            data = response.json()
            return data.get('access_token')
        else:
            print(f"❌ Login failed for {credentials['email']}: {response.text}")
            return None
    
    def setup_tokens(self):
        """Setup authentication tokens for all test users"""
        print("🔐 Setting up authentication tokens...")
        
        self.admin_token = self.login_user(TEST_ADMIN)
        self.driver_token = self.login_user(TEST_DRIVER)
        self.rider_token = self.login_user(TEST_RIDER)
        
        if all([self.admin_token, self.driver_token, self.rider_token]):
            print("✅ All tokens obtained successfully")
        else:
            print("❌ Failed to obtain some tokens")
            return False
        
        return True
    
    def create_test_ride(self):
        """Create a test ride as the rider"""
        print("\n🚗 Creating test ride...")
        
        ride_data = {
            "pickup_location": "Tech Corp Office",
            "destination": "Downtown Mall",
            "pickup_latitude": 37.7749,
            "pickup_longitude": -122.4194,
            "destination_latitude": 37.7849,
            "destination_longitude": -122.4094,
            "notes": "Test ride for lifecycle testing",
            "max_passengers": 2
        }
        
        headers = {"Authorization": f"Bearer {self.rider_token}"}
        response = requests.post(
            f"{API_BASE}/rides/",
            json=ride_data,
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            self.test_ride_id = ride['id']
            print(f"✅ Test ride created: {self.test_ride_id}")
            print(f"   Status: {ride['status']}")
            return True
        else:
            print(f"❌ Failed to create ride: {response.text}")
            return False
    
    def driver_offer_to_ride(self):
        """Driver offers to drive the ride"""
        print("\n🚙 Driver offering to drive...")
        
        offer_data = {
            "ride_id": self.test_ride_id,
            "message": "I can drive this ride"
        }
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/offer-driving",
            json=offer_data,
            headers=headers
        )
        
        if response.status_code == 200:
            offer = response.json()
            print(f"✅ Driver offer submitted: {offer.get('offer_id')}")
            return True
        else:
            print(f"❌ Failed to submit driver offer: {response.text}")
            return False
    
    def assign_driver_to_ride(self):
        """Admin assigns driver to the ride"""
        print("\n👨‍💼 Admin assigning driver...")
        
        # Get driver info
        headers = {"Authorization": f"Bearer {self.admin_token}"}
        response = requests.get(
            f"{API_BASE}/users/",
            headers=headers
        )
        
        if response.status_code != 200:
            print(f"❌ Failed to get users: {response.text}")
            return False
        
        users = response.json()
        driver = next((u for u in users if u['email'] == TEST_DRIVER['email']), None)
        
        if not driver:
            print("❌ Driver not found")
            return False
        
        # Assign driver
        assign_data = {"driver_id": driver['id']}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/assign-driver",
            json=assign_data,
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ Driver assigned successfully")
            return True
        else:
            print(f"❌ Failed to assign driver: {response.text}")
            return False
    
    def start_ride(self):
        """Driver starts the ride"""
        print("\n▶️ Driver starting ride...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/start",
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Ride started successfully")
            print(f"   Status: {ride['status']}")
            print(f"   Start time: {ride['actual_start_time']}")
            return True
        else:
            print(f"❌ Failed to start ride: {response.text}")
            return False
    
    def update_ride_progress(self):
        """Driver updates ride progress and location"""
        print("\n📍 Updating ride progress...")
        
        progress_data = {
            "ride_id": self.test_ride_id,
            "status": "in_progress",
            "current_latitude": 37.7799,
            "current_longitude": -122.4144,
            "ride_progress": 0.3,
            "estimated_pickup_time": (datetime.now(timezone.utc) + timedelta(minutes=5)).isoformat(),
            "estimated_dropoff_time": (datetime.now(timezone.utc) + timedelta(minutes=25)).isoformat()
        }
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/update-progress",
            json=progress_data,
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Progress updated successfully")
            print(f"   Progress: {ride['ride_progress']}")
            print(f"   Current location: {ride['current_latitude']}, {ride['current_longitude']}")
            return True
        else:
            print(f"❌ Failed to update progress: {response.text}")
            return False
    
    def update_ride_location(self):
        """Update ride location for real-time tracking"""
        print("\n🗺️ Updating ride location...")
        
        location_data = {
            "ride_id": self.test_ride_id,
            "latitude": 37.7799,
            "longitude": -122.4144,
            "accuracy": 5.0,
            "speed": 25.0,
            "heading": 90.0,
            "is_driver": True
        }
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/location",
            json=location_data,
            headers=headers
        )
        
        if response.status_code == 200:
            location = response.json()
            print(f"✅ Location updated successfully")
            print(f"   Location ID: {location['id']}")
            return True
        else:
            print(f"❌ Failed to update location: {response.text}")
            return False
    
    def pickup_passenger(self):
        """Driver marks passenger as picked up"""
        print("\n👥 Picking up passenger...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/pickup",
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Passenger picked up successfully")
            print(f"   Pickup time: {ride['pickup_time']}")
            print(f"   Progress: {ride['ride_progress']}")
            return True
        else:
            print(f"❌ Failed to pickup passenger: {response.text}")
            return False
    
    def complete_ride(self):
        """Driver completes the ride"""
        print("\n🏁 Completing ride...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/complete",
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Ride completed successfully")
            print(f"   Status: {ride['status']}")
            print(f"   End time: {ride['actual_end_time']}")
            print(f"   Duration: {ride['duration']} minutes")
            return True
        else:
            print(f"❌ Failed to complete ride: {response.text}")
            return False
    
    def rate_ride(self):
        """Rider rates the completed ride"""
        print("\n⭐ Rating the ride...")
        
        rating_data = {
            "ride_id": self.test_ride_id,
            "rating": 5.0,
            "feedback": "Great ride! Driver was very professional and punctual."
        }
        
        headers = {"Authorization": f"Bearer {self.rider_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/rate",
            json=rating_data,
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Ride rated successfully")
            print(f"   Rating: {ride['ride_rating']}")
            print(f"   Feedback: {ride['ride_feedback']}")
            return True
        else:
            print(f"❌ Failed to rate ride: {response.text}")
            return False
    
    def get_ride_locations(self):
        """Get ride location history"""
        print("\n🗺️ Getting ride location history...")
        
        headers = {"Authorization": f"Bearer {self.rider_token}"}
        response = requests.get(
            f"{API_BASE}/rides/{self.test_ride_id}/location",
            headers=headers
        )
        
        if response.status_code == 200:
            locations = response.json()
            print(f"✅ Retrieved {len(locations)} location records")
            for loc in locations[:3]:  # Show first 3
                print(f"   - {loc['timestamp']}: {loc['latitude']}, {loc['longitude']}")
            return True
        else:
            print(f"❌ Failed to get locations: {response.text}")
            return False
    
    def run_full_lifecycle_test(self):
        """Run the complete ride lifecycle test"""
        print("🚀 Starting Ride Lifecycle Management Test")
        print("=" * 50)
        
        # Setup
        if not self.setup_tokens():
            return False
        
        # Test steps
        steps = [
            ("Create Test Ride", self.create_test_ride),
            ("Driver Offer", self.driver_offer_to_ride),
            ("Assign Driver", self.assign_driver_to_ride),
            ("Start Ride", self.start_ride),
            ("Update Progress", self.update_ride_progress),
            ("Update Location", self.update_ride_location),
            ("Pickup Passenger", self.pickup_passenger),
            ("Complete Ride", self.complete_ride),
            ("Rate Ride", self.rate_ride),
            ("Get Locations", self.get_ride_locations),
        ]
        
        passed = 0
        total = len(steps)
        
        for step_name, step_func in steps:
            try:
                if step_func():
                    passed += 1
                    print(f"✅ {step_name}: PASSED")
                else:
                    print(f"❌ {step_name}: FAILED")
            except Exception as e:
                print(f"❌ {step_name}: ERROR - {str(e)}")
            
            time.sleep(1)  # Small delay between steps
        
        # Results
        print("\n" + "=" * 50)
        print(f"🎯 Test Results: {passed}/{total} steps passed")
        
        if passed == total:
            print("🎉 All tests passed! Ride lifecycle is working correctly.")
        else:
            print("⚠️ Some tests failed. Check the implementation.")
        
        return passed == total

def main():
    """Main test execution"""
    tester = RideLifecycleTester()
    
    try:
        success = tester.run_full_lifecycle_test()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⏹️ Test interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n💥 Test failed with error: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()
