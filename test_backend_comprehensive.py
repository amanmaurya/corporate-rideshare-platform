#!/usr/bin/env python3
"""
Comprehensive Backend Test Script for Corporate RideShare Platform
Tests all API endpoints, authentication, and business logic
"""

import requests
import json
import time
import sys
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/v1"

class TestResults:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.errors = []
        self.auth_token = None
        self.test_user = None
        self.test_company = None

    def add_result(self, test_name, success, error=None):
        if success:
            self.passed += 1
            print(f"✅ {test_name}")
        else:
            self.failed += 1
            self.errors.append(f"{test_name}: {error}")
            print(f"❌ {test_name}: {error}")

    def print_summary(self):
        print("\n" + "=" * 60)
        print("📊 COMPREHENSIVE TEST RESULTS SUMMARY")
        print("=" * 60)
        print(f"✅ Passed: {self.passed}")
        print(f"❌ Failed: {self.failed}")
        print(f"📈 Success Rate: {(self.passed / (self.passed + self.failed)) * 100:.1f}%")
        
        if self.errors:
            print("\n🚨 Errors:")
            for error in self.errors:
                print(f"   • {error}")

def test_health_check(results):
    """Test basic health and root endpoints"""
    try:
        # Health check
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            results.add_result("Health Check", True)
        else:
            results.add_result("Health Check", False, f"Status: {response.status_code}")

        # Root endpoint
        response = requests.get(f"{BASE_URL}/")
        if response.status_code == 200:
            data = response.json()
            results.add_result("Root Endpoint", True)
        else:
            results.add_result("Root Endpoint", False, f"Status: {response.status_code}")

        # Admin dashboard
        response = requests.get(f"{BASE_URL}/admin")
        if response.status_code == 200:
            results.add_result("Admin Dashboard", True)
        else:
            results.add_result("Admin Dashboard", False, f"Status: {response.status_code}")

        # API docs
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code == 200:
            results.add_result("API Documentation", True)
        else:
            results.add_result("API Documentation", False, f"Status: {response.status_code}")

    except Exception as e:
        results.add_result("Basic Endpoints", False, str(e))

def test_authentication(results):
    """Test authentication endpoints"""
    try:
        # Test registration
        user_data = {
            "name": "Test User",
            "email": "testuser@testcorp.com",
            "phone": "+1-555-9999",
            "department": "Testing",
            "role": "employee",
            "company_id": "company-1",
            "password": "testpass123",
            "is_driver": False
        }
        
        response = requests.post(f"{API_BASE}/auth/register", json=user_data)
        if response.status_code == 200:
            results.add_result("User Registration", True)
            results.test_user = response.json()
        else:
            results.add_result("User Registration", False, f"Status: {response.status_code}, Response: {response.text}")

        # Test login
        login_data = {
            "email": "admin@techcorp.com",
            "password": "admin123",
            "company_id": "company-1"
        }
        
        response = requests.post(f"{API_BASE}/auth/login", json=login_data)
        if response.status_code == 200:
            data = response.json()
            results.auth_token = data.get('access_token')
            results.add_result("User Login", True)
        else:
            results.add_result("User Login", False, f"Status: {response.status_code}, Response: {response.text}")

        # Test get current user
        if results.auth_token:
            headers = {"Authorization": f"Bearer {results.auth_token}"}
            response = requests.get(f"{API_BASE}/auth/me", headers=headers)
            if response.status_code == 200:
                results.add_result("Get Current User", True)
            else:
                results.add_result("Get Current User", False, f"Status: {response.status_code}")

    except Exception as e:
        results.add_result("Authentication", False, str(e))

def test_companies_api(results):
    """Test company management endpoints"""
    if not results.auth_token:
        results.add_result("Companies API", False, "No auth token")
        return

    try:
        headers = {"Authorization": f"Bearer {results.auth_token}"}
        
        # Get companies
        response = requests.get(f"{API_BASE}/companies/", headers=headers)
        if response.status_code == 200:
            companies = response.json()
            results.add_result("Get Companies", True)
            if companies:
                results.test_company = companies[0]
        else:
            results.add_result("Get Companies", False, f"Status: {response.status_code}")

        # Get specific company
        if results.test_company:
            company_id = results.test_company['id']
            response = requests.get(f"{API_BASE}/companies/{company_id}", headers=headers)
            if response.status_code == 200:
                results.add_result("Get Specific Company", True)
            else:
                results.add_result("Get Specific Company", False, f"Status: {response.status_code}")

    except Exception as e:
        results.add_result("Companies API", False, str(e))

def test_users_api(results):
    """Test user management endpoints"""
    if not results.auth_token:
        results.add_result("Users API", False, "No auth token")
        return

    try:
        headers = {"Authorization": f"Bearer {results.auth_token}"}
        
        # Get users
        response = requests.get(f"{API_BASE}/users/", headers=headers)
        if response.status_code == 200:
            users = response.json()
            results.add_result("Get Users", True)
        else:
            results.add_result("Get Users", False, f"Status: {response.status_code}")

        # Get specific user
        if results.test_user:
            user_id = results.test_user['id']
            response = requests.get(f"{API_BASE}/users/{user_id}", headers=headers)
            if response.status_code == 200:
                results.add_result("Get Specific User", True)
            else:
                results.add_result("Get Specific User", False, f"Status: {response.status_code}")

    except Exception as e:
        results.add_result("Users API", False, str(e))

def test_rides_api(results):
    """Test ride management endpoints"""
    if not results.auth_token:
        results.add_result("Rides API", False, "No auth token")
        return

    try:
        headers = {"Authorization": f"Bearer {results.auth_token}"}
        
        # Create a test ride
        ride_data = {
            "pickup_location": "123 Test Street",
            "destination": "456 Test Avenue",
            "pickup_latitude": 37.7749,
            "pickup_longitude": -122.4194,
            "destination_latitude": 37.7849,
            "destination_longitude": -122.4094,
            "scheduled_time": (datetime.now() + timedelta(hours=1)).isoformat(),
            "notes": "Test ride for API testing",
            "max_passengers": 4
        }
        
        response = requests.post(f"{API_BASE}/rides/", json=ride_data, headers=headers)
        if response.status_code == 200:
            test_ride = response.json()
            results.add_result("Create Ride", True)
            
            # Test get rides
            response = requests.get(f"{API_BASE}/rides/", headers=headers)
            if response.status_code == 200:
                results.add_result("Get Rides", True)
            else:
                results.add_result("Get Rides", False, f"Status: {response.status_code}")

            # Test get my rides
            response = requests.get(f"{API_BASE}/rides/my-rides", headers=headers)
            if response.status_code == 200:
                results.add_result("Get My Rides", True)
            else:
                results.add_result("Get My Rides", False, f"Status: {response.status_code}")

            # Test get specific ride
            ride_id = test_ride['id']
            response = requests.get(f"{API_BASE}/rides/{ride_id}", headers=headers)
            if response.status_code == 200:
                results.add_result("Get Specific Ride", True)
            else:
                results.add_result("Get Specific Ride", False, f"Status: {response.status_code}")

            # Test ride matching
            response = requests.get(f"{API_BASE}/rides/{ride_id}/matches", headers=headers)
            if response.status_code == 200:
                results.add_result("Ride Matching", True)
            else:
                results.add_result("Ride Matching", False, f"Status: {response.status_code}")

            # Clean up - delete test ride
            response = requests.delete(f"{API_BASE}/rides/{ride_id}", headers=headers)
            if response.status_code == 200:
                results.add_result("Delete Ride", True)
            else:
                results.add_result("Delete Ride", False, f"Status: {response.status_code}")

        else:
            results.add_result("Create Ride", False, f"Status: {response.status_code}, Response: {response.text}")

    except Exception as e:
        results.add_result("Rides API", False, str(e))

def test_websocket_status(results):
    """Test WebSocket connection status"""
    try:
        if results.auth_token:
            headers = {"Authorization": f"Bearer {results.auth_token}"}
            response = requests.get(f"{API_BASE}/websocket/active-connections", headers=headers)
            if response.status_code == 200:
                data = response.json()
                results.add_result("WebSocket Status", True)
            else:
                results.add_result("WebSocket Status", False, f"Status: {response.status_code}")
        else:
            results.add_result("WebSocket Status", False, "No auth token")
    except Exception as e:
        results.add_result("WebSocket Status", False, str(e))

def main():
    """Run all comprehensive tests"""
    print("🚗 Corporate RideShare Platform - Comprehensive Backend Testing")
    print("=" * 70)
    
    results = TestResults()
    
    # Wait for services to start
    print("⏳ Waiting for services to start...")
    time.sleep(10)
    
    print("\n🔍 Starting comprehensive backend tests...")
    print("-" * 50)
    
    # Run all test suites
    test_health_check(results)
    test_authentication(results)
    test_companies_api(results)
    test_users_api(results)
    test_rides_api(results)
    test_websocket_status(results)
    
    # Print final results
    results.print_summary()
    
    # Exit with appropriate code
    if results.failed == 0:
        print("\n🎉 All tests passed! The backend is fully functional.")
        sys.exit(0)
    else:
        print(f"\n⚠️  {results.failed} tests failed. Check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
