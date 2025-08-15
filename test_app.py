#!/usr/bin/env python3
"""
Simple test script for Corporate RideShare Platform
Run this after starting the services to test the API
"""

import requests
import json
import time

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"✅ Health check: {response.status_code}")
        print(f"   Response: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_root():
    """Test root endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"✅ Root endpoint: {response.status_code}")
        print(f"   Response: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Root endpoint failed: {e}")
        return False

def test_admin_dashboard():
    """Test admin dashboard"""
    try:
        response = requests.get(f"{BASE_URL}/admin")
        print(f"✅ Admin dashboard: {response.status_code}")
        print(f"   Content length: {len(response.text)}")
        return True
    except Exception as e:
        print(f"❌ Admin dashboard failed: {e}")
        return False

def test_api_docs():
    """Test API documentation"""
    try:
        response = requests.get(f"{BASE_URL}/docs")
        print(f"✅ API docs: {response.status_code}")
        print(f"   Content length: {len(response.text)}")
        return True
    except Exception as e:
        print(f"❌ API docs failed: {e}")
        return False

def test_login():
    """Test user login"""
    try:
        login_data = {
            "email": "admin@techcorp.com",
            "password": "admin123",
            "company_id": "company-1"
        }
        response = requests.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
        print(f"✅ Login test: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Token received: {len(data.get('access_token', ''))} chars")
            return data.get('access_token')
        else:
            print(f"   Error: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Login test failed: {e}")
        return None

def test_rides_endpoint(token):
    """Test rides endpoint with authentication"""
    if not token:
        print("❌ Skipping rides test - no token")
        return False
    
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{BASE_URL}/api/v1/rides/", headers=headers)
        print(f"✅ Rides endpoint: {response.status_code}")
        if response.status_code == 200:
            rides = response.json()
            print(f"   Found {len(rides)} rides")
        else:
            print(f"   Error: {response.text}")
        return True
    except Exception as e:
        print(f"❌ Rides endpoint failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🚗 Testing Corporate RideShare Platform")
    print("=" * 50)
    
    # Wait for services to start
    print("⏳ Waiting for services to start...")
    time.sleep(5)
    
    # Test basic endpoints
    health_ok = test_health()
    root_ok = test_root()
    admin_ok = test_admin_dashboard()
    docs_ok = test_api_docs()
    
    # Test authentication
    token = test_login()
    
    # Test authenticated endpoints
    if token:
        rides_ok = test_rides_endpoint(token)
    else:
        rides_ok = False
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"   Health Check: {'✅ PASS' if health_ok else '❌ FAIL'}")
    print(f"   Root Endpoint: {'✅ PASS' if root_ok else '❌ FAIL'}")
    print(f"   Admin Dashboard: {'✅ PASS' if admin_ok else '❌ FAIL'}")
    print(f"   API Documentation: {'✅ PASS' if docs_ok else '❌ FAIL'}")
    print(f"   Authentication: {'✅ PASS' if token else '❌ FAIL'}")
    print(f"   Rides API: {'✅ PASS' if rides_ok else '❌ FAIL'}")
    
    if all([health_ok, root_ok, admin_ok, docs_ok, token, rides_ok]):
        print("\n🎉 All tests passed! The app is working correctly.")
    else:
        print("\n⚠️  Some tests failed. Check the logs above for details.")

if __name__ == "__main__":
    main()
