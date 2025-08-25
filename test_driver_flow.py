#!/usr/bin/env python3
"""
Test script for Complete Driver Flow
Tests the entire driver journey: browse rides -> offer to drive -> get assigned -> start ride -> complete ride
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

class DriverFlowTester:
    def __init__(self):
        self.admin_token = None
        self.driver_token = None
        self.rider_token = None
        self.test_ride_id = None
        self.driver_offer_id = None
        
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
            "notes": "Test ride for driver flow testing",
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
    
    def driver_browse_available_rides(self):
        """Driver browses available rides"""
        print("\n🔍 Driver browsing available rides...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.get(
            f"{API_BASE}/rides/available-for-drivers",
            headers=headers
        )
        
        if response.status_code == 200:
            rides = response.json()
            print(f"✅ Found {len(rides)} available rides")
            if rides:
                ride = rides[0]
                print(f"   First ride: {ride['pickup_location']} → {ride['destination']}")
            return True
        else:
            print(f"❌ Failed to get available rides: {response.text}")
            return False
    
    def driver_offer_to_drive(self):
        """Driver offers to drive the test ride"""
        print("\n🚙 Driver offering to drive...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/offer-driving",
            headers=headers
        )
        
        if response.status_code == 200:
            offer = response.json()
            print(f"✅ Driver offer submitted successfully")
            print(f"   Message: {offer.get('message')}")
            return True
        else:
            print(f"❌ Failed to submit driver offer: {response.text}")
            return False
    
    def rider_assign_driver(self):
        """Rider assigns the driver to the ride"""
        print("\n👤 Rider assigning driver...")
        
        # Get driver info
        headers = {"Authorization": f"Bearer {self.rider_token}"}
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
    
    def driver_start_ride(self):
        """Driver starts the assigned ride"""
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
    
    def driver_update_progress(self):
        """Driver updates ride progress"""
        print("\n📍 Driver updating ride progress...")
        
        progress_data = {
            "ride_id": self.test_ride_id,
            "status": "in_progress",  # Required field
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
            return True
        else:
            print(f"❌ Failed to update progress: {response.text}")
            return False
    
    def driver_pickup_passenger(self):
        """Driver marks passenger as picked up"""
        print("\n👥 Driver picking up passenger...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/pickup",
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Passenger picked up successfully")
            print(f"   Progress: {ride['ride_progress']}")
            return True
        else:
            print(f"❌ Failed to pickup passenger: {response.text}")
            return False
    
    def driver_complete_ride(self):
        """Driver completes the ride"""
        print("\n🏁 Driver completing ride...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.post(
            f"{API_BASE}/rides/{self.test_ride_id}/complete",
            headers=headers
        )
        
        if response.status_code == 200:
            ride = response.json()
            print(f"✅ Ride completed successfully")
            print(f"   Status: {ride['status']}")
            print(f"   Duration: {ride['duration']} minutes")
            return True
        else:
            print(f"❌ Failed to complete ride: {response.text}")
            return False
    
    def rider_rate_ride(self):
        """Rider rates the completed ride"""
        print("\n⭐ Rider rating the ride...")
        
        rating_data = {
            "ride_id": self.test_ride_id,
            "rating": 5.0,
            "feedback": "Excellent driver! Very professional and punctual."
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
            return True
        else:
            print(f"❌ Failed to rate ride: {response.text}")
            return False
    
    def check_driver_offers(self):
        """Check driver's submitted offers"""
        print("\n📋 Checking driver offers...")
        
        headers = {"Authorization": f"Bearer {self.driver_token}"}
        response = requests.get(
            f"{API_BASE}/rides/driver/offers",
            headers=headers
        )
        
        if response.status_code == 200:
            offers = response.json()
            print(f"✅ Found {len(offers)} driver offers")
            for offer in offers:
                print(f"   - Ride {offer['ride_id']}: {offer['status']}")
            return True
        else:
            print(f"❌ Failed to get driver offers: {response.text}")
            return False
    
    def run_complete_driver_flow(self):
        """Run the complete driver flow test"""
        print("🚀 Starting Complete Driver Flow Test")
        print("=" * 60)
        
        # Setup
        if not self.setup_tokens():
            return False
        
        # Test steps
        steps = [
            ("Create Test Ride", self.create_test_ride),
            ("Driver Browse Available Rides", self.driver_browse_available_rides),
            ("Driver Offer to Drive", self.driver_offer_to_drive),
            ("Check Driver Offers", self.check_driver_offers),
            ("Rider Assign Driver", self.rider_assign_driver),
            ("Driver Start Ride", self.driver_start_ride),
            ("Driver Update Progress", self.driver_update_progress),
            ("Driver Pickup Passenger", self.driver_pickup_passenger),
            ("Driver Complete Ride", self.driver_complete_ride),
            ("Rider Rate Ride", self.rider_rate_ride),
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
        print("\n" + "=" * 60)
        print(f"🎯 Test Results: {passed}/{total} steps passed")
        
        if passed == total:
            print("🎉 All tests passed! Complete driver flow is working correctly.")
        else:
            print("⚠️ Some tests failed. Check the implementation.")
        
        return passed == total

def main():
    """Main test execution"""
    tester = DriverFlowTester()
    
    try:
        success = tester.run_complete_driver_flow()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⏹️ Test interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n💥 Test failed with error: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()
