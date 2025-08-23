#!/usr/bin/env python3
"""
Test script to verify the ride accept endpoint works correctly
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"
API_VERSION = "v1"
API_BASE = f"{BASE_URL}/api/{API_VERSION}"

def test_ride_accept_endpoint():
    """Test the ride accept endpoint with proper request body"""
    
    # Test data - you'll need to replace these with actual IDs from your database
    ride_id = "ba32b2c7-dcbd-4e57-8e01-74996815e5d6"  # From your error message
    request_id = "test-request-id"  # You'll need a real request ID
    
    # Test the endpoint
    url = f"{API_BASE}/rides/{ride_id}/accept"
    
    # Request body matching the new backend expectation
    payload = {
        "request_id": request_id
    }
    
    headers = {
        "Content-Type": "application/json",
        # Note: You'll need to add Authorization header with a valid token
        # "Authorization": "Bearer YOUR_TOKEN_HERE"
    }
    
    print(f"Testing endpoint: {url}")
    print(f"Request payload: {json.dumps(payload, indent=2)}")
    print(f"Headers: {json.dumps(headers, indent=2)}")
    print("-" * 50)
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 401:
            print("✅ Endpoint is working but requires authentication")
            print("   This is expected behavior - the endpoint exists and accepts the request format")
        elif response.status_code == 404:
            print("✅ Endpoint is working but ride/request not found")
            print("   This is expected if the IDs don't exist in your database")
        elif response.status_code == 422:
            print("❌ Still getting 422 error - backend validation issue")
            print(f"   Response: {response.text}")
        elif response.status_code == 200:
            print("✅ Endpoint working perfectly!")
            print(f"   Response: {response.text}")
        else:
            print(f"⚠️  Unexpected status code: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - make sure the backend is running on localhost:8000")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_backend_health():
    """Test if the backend is running and accessible"""
    
    try:
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code == 200:
            print("✅ Backend is running and accessible")
            return True
        else:
            print(f"⚠️  Backend responded with status: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Backend is not running or not accessible")
        return False
    except Exception as e:
        print(f"❌ Error checking backend: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Ride Accept Endpoint")
    print("=" * 50)
    
    # First check if backend is running
    if test_backend_health():
        print()
        test_ride_accept_endpoint()
    else:
        print("\n❌ Cannot test endpoint - backend not accessible")
        print("   Please start the backend first:")
        print("   cd backend && python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
