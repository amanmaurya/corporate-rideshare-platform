#!/usr/bin/env python3
"""
Final Comprehensive Test Script for Corporate RideShare Platform
Tests all completed functionality including mobile app features and web admin
"""

import requests
import json
import time
import sys
import subprocess
import os
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/v1"

class FinalComprehensiveTester:
    def __init__(self):
        self.test_results = {
            'passed': 0,
            'failed': 0,
            'errors': []
        }
        self.auth_token = None
        self.test_user = None
        self.test_company = None
        self.test_ride = None

    def log_result(self, test_name, success, error=None):
        """Log test result"""
        if success:
            self.test_results['passed'] += 1
            print(f"✅ {test_name}")
        else:
            self.test_results['failed'] += 1
            self.test_results['errors'].append(f"{test_name}: {error}")
            print(f"❌ {test_name}: {error}")

    def print_summary(self):
        """Print test summary"""
        print("\n" + "=" * 80)
        print("🎯 FINAL COMPREHENSIVE TEST RESULTS SUMMARY")
        print("=" * 80)
        print(f"✅ Passed: {self.test_results['passed']}")
        print(f"❌ Failed: {self.test_results['failed']}")
        print(f"📈 Success Rate: {(self.test_results['passed'] / (self.test_results['passed'] + self.test_results['failed'])) * 100:.1f}%")
        
        if self.test_results['errors']:
            print("\n🚨 Errors:")
            for error in self.test_results['errors']:
                print(f"   • {error}")

    def wait_for_services(self):
        """Wait for all services to be ready"""
        print("⏳ Waiting for services to start...")
        max_attempts = 30
        attempt = 0
        
        while attempt < max_attempts:
            try:
                response = requests.get(f"{BASE_URL}/health", timeout=5)
                if response.status_code == 200:
                    print("✅ Backend is ready!")
                    return True
            except:
                pass
            
            attempt += 1
            time.sleep(2)
            print(f"   Attempt {attempt}/{max_attempts}...")
        
        print("❌ Services failed to start within expected time")
        return False

    def test_system_health(self):
        """Test basic system health"""
        try:
            # Health check
            response = requests.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                self.log_result("System Health Check", True)
            else:
                self.log_result("System Health Check", False, f"Status: {response.status_code}")

            # Root endpoint
            response = requests.get(f"{BASE_URL}/")
            if response.status_code == 200:
                self.log_result("Root Endpoint", True)
            else:
                self.log_result("Root Endpoint", False, f"Status: {response.status_code}")

            # Admin dashboard
            response = requests.get(f"{BASE_URL}/admin")
            if response.status_code == 200:
                self.log_result("Admin Dashboard", True)
            else:
                self.log_result("Admin Dashboard", False, f"Status: {response.status_code}")

            # API docs
            response = requests.get(f"{BASE_URL}/docs")
            if response.status_code == 200:
                self.log_result("API Documentation", True)
            else:
                self.log_result("API Documentation", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("System Health", False, str(e))

    def test_authentication_flow(self):
        """Test complete authentication flow"""
        try:
            # Test user registration
            user_data = {
                "name": "Final Test User",
                "email": "finaltest@testcorp.com",
                "phone": "+1-555-FINAL-TEST",
                "department": "Testing",
                "role": "employee",
                "company_id": "company-1",
                "password": "finaltest123",
                "is_driver": False
            }
            
            response = requests.post(f"{API_BASE}/auth/register", json=user_data)
            if response.status_code == 200:
                self.test_user = response.json()
                self.log_result("User Registration", True)
            else:
                self.log_result("User Registration", False, f"Status: {response.status_code}")

            # Test user login
            login_data = {
                "email": "admin@techcorp.com",
                "password": "admin123",
                "company_id": "company-1"
            }
            
            response = requests.post(f"{API_BASE}/auth/login", json=login_data)
            if response.status_code == 200:
                data = response.json()
                self.auth_token = data.get('access_token')
                self.log_result("User Login", True)
            else:
                self.log_result("User Login", False, f"Status: {response.status_code}")

            # Test get current user
            if self.auth_token:
                headers = {"Authorization": f"Bearer {self.auth_token}"}
                response = requests.get(f"{API_BASE}/auth/me", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get Current User", True)
                else:
                    self.log_result("Get Current User", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("Authentication Flow", False, str(e))

    def test_company_management(self):
        """Test company management functionality"""
        if not self.auth_token:
            self.log_result("Company Management", False, "No auth token")
            return

        try:
            headers = {"Authorization": f"Bearer {self.auth_token}"}
            
            # Get all companies
            response = requests.get(f"{API_BASE}/companies/", headers=headers)
            if response.status_code == 200:
                companies = response.json()
                if companies:
                    self.test_company = companies[0]
                    self.log_result("Get Companies", True)
                else:
                    self.log_result("Get Companies", False, "No companies returned")
            else:
                self.log_result("Get Companies", False, f"Status: {response.status_code}")

            # Get specific company
            if self.test_company:
                company_id = self.test_company['id']
                response = requests.get(f"{API_BASE}/companies/{company_id}", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get Specific Company", True)
                else:
                    self.log_result("Get Specific Company", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("Company Management", False, str(e))

    def test_user_management(self):
        """Test user management functionality"""
        if not self.auth_token:
            self.log_result("User Management", False, "No auth token")
            return

        try:
            headers = {"Authorization": f"Bearer {self.auth_token}"}
            
            # Get all users
            response = requests.get(f"{API_BASE}/users/", headers=headers)
            if response.status_code == 200:
                users = response.json()
                self.log_result("Get Users", True)
            else:
                self.log_result("Get Users", False, f"Status: {response.status_code}")

            # Get specific user
            if self.test_user:
                user_id = self.test_user['id']
                response = requests.get(f"{API_BASE}/users/{user_id}", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get Specific User", True)
                else:
                    self.log_result("Get Specific User", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("User Management", False, str(e))

    def test_ride_lifecycle(self):
        """Test complete ride lifecycle"""
        if not self.auth_token:
            self.log_result("Ride Lifecycle", False, "No auth token")
            return

        try:
            headers = {"Authorization": f"Bearer {self.auth_token}"}
            
            # Create a test ride
            ride_data = {
                "pickup_location": "123 Final Test Street",
                "destination": "456 Final Test Avenue",
                "pickup_latitude": 37.7749,
                "pickup_longitude": -122.4194,
                "destination_latitude": 37.7849,
                "destination_longitude": -122.4094,
                "scheduled_time": (datetime.now() + timedelta(hours=1)).isoformat(),
                "notes": "Final comprehensive test ride",
                "max_passengers": 4
            }
            
            response = requests.post(f"{API_BASE}/rides/", json=ride_data, headers=headers)
            if response.status_code == 200:
                self.test_ride = response.json()
                self.log_result("Create Ride", True)
                
                # Test ride retrieval
                ride_id = self.test_ride['id']
                
                # Get all rides
                response = requests.get(f"{API_BASE}/rides/", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get All Rides", True)
                else:
                    self.log_result("Get All Rides", False, f"Status: {response.status_code}")

                # Get my rides
                response = requests.get(f"{API_BASE}/rides/my-rides", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get My Rides", True)
                else:
                    self.log_result("Get My Rides", False, f"Status: {response.status_code}")

                # Get specific ride
                response = requests.get(f"{API_BASE}/rides/{ride_id}", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get Specific Ride", True)
                else:
                    self.log_result("Get Specific Ride", False, f"Status: {response.status_code}")

                # Test ride matching
                response = requests.get(f"{API_BASE}/rides/{ride_id}/matches", headers=headers)
                if response.status_code == 200:
                    self.log_result("Ride Matching", True)
                else:
                    self.log_result("Ride Matching", False, f"Status: {response.status_code}")

                # Test ride requests endpoint
                response = requests.get(f"{API_BASE}/rides/{ride_id}/requests", headers=headers)
                if response.status_code == 200:
                    self.log_result("Get Ride Requests", True)
                else:
                    self.log_result("Get Ride Requests", False, f"Status: {response.status_code}")

                # Clean up - delete test ride
                response = requests.delete(f"{API_BASE}/rides/{ride_id}", headers=headers)
                if response.status_code == 200:
                    self.log_result("Delete Ride", True)
                else:
                    self.log_result("Delete Ride", False, f"Status: {response.status_code}")

            else:
                self.log_result("Create Ride", False, f"Status: {response.status_code}, Response: {response.text}")

        except Exception as e:
            self.log_result("Ride Lifecycle", False, str(e))

    def test_websocket_functionality(self):
        """Test WebSocket functionality"""
        if not self.auth_token:
            self.log_result("WebSocket Functionality", False, "No auth token")
            return

        try:
            headers = {"Authorization": f"Bearer {self.auth_token}"}
            
            # Test WebSocket status
            response = requests.get(f"{API_BASE}/websocket/active-connections", headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_result("WebSocket Status", True)
            else:
                self.log_result("WebSocket Status", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("WebSocket Functionality", False, str(e))

    def test_mobile_app_integration(self):
        """Test mobile app integration with backend"""
        try:
            # Check if mobile app can access backend APIs
            if self.auth_token:
                headers = {"Authorization": f"Bearer {self.auth_token}"}
                
                # Test companies endpoint for mobile
                response = requests.get(f"{API_BASE}/companies/", headers=headers)
                if response.status_code == 200:
                    self.log_result("Mobile Companies API", True)
                else:
                    self.log_result("Mobile Companies API", False, f"Status: {response.status_code}")

                # Test rides endpoint for mobile
                response = requests.get(f"{API_BASE}/rides/", headers=headers)
                if response.status_code == 200:
                    self.log_result("Mobile Rides API", True)
                else:
                    self.log_result("Mobile Rides API", False, f"Status: {response.status_code}")

            else:
                self.log_result("Mobile App Integration", False, "No auth token")

        except Exception as e:
            self.log_result("Mobile App Integration", False, str(e))

    def test_web_admin_functionality(self):
        """Test web admin dashboard functionality"""
        try:
            # Test admin dashboard accessibility
            response = requests.get(f"{BASE_URL}/admin")
            if response.status_code == 200:
                self.log_result("Admin Dashboard Access", True)
            else:
                self.log_result("Admin Dashboard Access", False, f"Status: {response.status_code}")

            # Test admin static files
            response = requests.get(f"{BASE_URL}/static/js/admin.js")
            if response.status_code == 200:
                self.log_result("Admin JavaScript", True)
            else:
                self.log_result("Admin JavaScript", False, f"Status: {response.status_code}")

            # Test admin CSS
            response = requests.get(f"{BASE_URL}/static/css/admin.css")
            if response.status_code == 200:
                self.log_result("Admin CSS", True)
            else:
                self.log_result("Admin CSS", False, f"Status: {response.status_code}")

        except Exception as e:
            self.log_result("Web Admin Functionality", False, str(e))

    def test_flutter_app_components(self):
        """Test Flutter app component files"""
        try:
            # Check if mobile app files exist
            mobile_files = [
                "mobile/lib/screens/profile/profile_edit_screen.dart",
                "mobile/lib/screens/settings/settings_screen.dart",
                "mobile/lib/services/company_service.dart",
                "mobile/lib/services/ride_service.dart"
            ]

            for file_path in mobile_files:
                if os.path.exists(file_path):
                    self.log_result(f"Mobile App File: {os.path.basename(file_path)}", True)
                else:
                    self.log_result(f"Mobile App File: {os.path.basename(file_path)}", False, "File not found")

        except Exception as e:
            self.log_result("Flutter App Components", False, str(e))

    def run_all_tests(self):
        """Run all final comprehensive tests"""
        print("🎯 Corporate RideShare Platform - Final Comprehensive Testing")
        print("=" * 80)
        
        # Wait for services to be ready
        if not self.wait_for_services():
            print("❌ Services not ready. Exiting.")
            return False
        
        print("\n🔍 Starting final comprehensive tests...")
        print("-" * 60)
        
        # Run all test suites
        self.test_system_health()
        self.test_authentication_flow()
        self.test_company_management()
        self.test_user_management()
        self.test_ride_lifecycle()
        self.test_websocket_functionality()
        self.test_mobile_app_integration()
        self.test_web_admin_functionality()
        self.test_flutter_app_components()
        
        # Print final results
        self.print_summary()
        
        # Return success/failure
        return self.test_results['failed'] == 0

def main():
    """Main final comprehensive test runner"""
    print("🚗 Corporate RideShare Platform - Final Comprehensive System Test")
    print("=" * 90)
    
    tester = FinalComprehensiveTester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎉 All final comprehensive tests passed!")
        print("   The Corporate RideShare Platform is now COMPLETE and ready for production!")
        print("\n🚀 Next Steps:")
        print("   1. Deploy to production environment")
        print("   2. Configure production database and services")
        print("   3. Set up monitoring and logging")
        print("   4. Train users and administrators")
        print("   5. Launch the platform!")
        sys.exit(0)
    else:
        print(f"\n⚠️  {tester.test_results['failed']} final comprehensive tests failed.")
        print("   Please review the errors above and ensure all functionality is working.")
        sys.exit(1)

if __name__ == "__main__":
    main()
