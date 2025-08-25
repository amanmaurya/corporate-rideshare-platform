#!/usr/bin/env python3
"""
Test the complete authentication flow to identify the issue
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/v1"

# Test user credentials
TEST_USER = {
    "email": "john.doe@techcorp.com",
    "password": "user123",
    "company_id": "company-1"
}

def test_auth_flow():
    """Test complete authentication flow"""
    print("🔐 Testing Authentication Flow...")
    print("=" * 50)
    
    # Step 1: Test login
    print("\n1️⃣ Testing Login...")
    try:
        response = requests.post(
            f"{API_BASE}/auth/login",
            json=TEST_USER
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('access_token')
            user = data.get('user')
            print(f"✅ Login successful!")
            print(f"   Token: {token[:20]}..." if token else "   No token!")
            print(f"   User: {user.get('name') if user else 'No user data'}")
            
            if not token:
                print("❌ CRITICAL: No access token received!")
                return False
                
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Login error: {e}")
        return False
    
    # Step 2: Test authenticated rides endpoint
    print("\n2️⃣ Testing Authenticated Rides Endpoint...")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(
            f"{API_BASE}/rides/",
            headers=headers
        )
        
        if response.status_code == 200:
            rides = response.json()
            print(f"✅ Rides endpoint working!")
            print(f"   Found {len(rides)} rides")
            print(f"   CORS Headers:")
            for header, value in response.headers.items():
                if 'access-control' in header.lower():
                    print(f"     {header}: {value}")
        else:
            print(f"❌ Rides endpoint failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Rides endpoint error: {e}")
        return False
    
    # Step 3: Test my-rides endpoint
    print("\n3️⃣ Testing My-Rides Endpoint...")
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(
            f"{API_BASE}/rides/my-rides",
            headers=headers
        )
        
        if response.status_code == 200:
            my_rides = response.json()
            print(f"✅ My-rides endpoint working!")
            print(f"   Found {len(my_rides)} user rides")
        else:
            print(f"❌ My-rides endpoint failed: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except Exception as e:
        print(f"❌ My-rides endpoint error: {e}")
    
    # Step 4: Test without token (should fail)
    print("\n4️⃣ Testing Without Token (Should Fail)...")
    try:
        response = requests.get(f"{API_BASE}/rides/")
        
        if response.status_code == 403:
            print(f"✅ Correctly rejected without token!")
            print(f"   Response: {response.text}")
        else:
            print(f"⚠️ Unexpected response without token: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error testing without token: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Authentication Flow Test Complete!")
    return True

def test_cors_specific():
    """Test CORS specifically for the problematic endpoints"""
    print("\n🌐 Testing CORS for Problematic Endpoints...")
    print("=" * 50)
    
    # Test the exact endpoints that were failing
    endpoints = [
        f"{API_BASE}/rides/?status=pending",
        f"{API_BASE}/rides/my-rides"
    ]
    
    for endpoint in endpoints:
        print(f"\n🔍 Testing: {endpoint}")
        
        # Test with CORS preflight
        try:
            headers = {
                'Origin': 'http://localhost:59167',
                'Access-Control-Request-Method': 'GET',
                'Access-Control-Request-Headers': 'Content-Type, Authorization'
            }
            response = requests.options(endpoint, headers=headers)
            print(f"   OPTIONS: {response.status_code}")
            print(f"   CORS Headers:")
            for header, value in response.headers.items():
                if 'access-control' in header.lower():
                    print(f"     {header}: {value}")
        except Exception as e:
            print(f"   OPTIONS Error: {e}")
        
        # Test actual GET (should fail without auth, but CORS should work)
        try:
            headers = {'Origin': 'http://localhost:59167'}
            response = requests.get(endpoint, headers=headers)
            print(f"   GET: {response.status_code}")
            print(f"   CORS Headers:")
            for header, value in response.headers.items():
                if 'access-control' in header.lower():
                    print(f"     {header}: {value}")
        except Exception as e:
            print(f"   GET Error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Authentication & CORS Tests...")
    
    # Run main auth flow test
    auth_success = test_auth_flow()
    
    # Run CORS specific tests
    test_cors_specific()
    
    if auth_success:
        print("\n🎉 Authentication flow is working correctly!")
        print("   The issue is likely in the mobile app's token handling.")
    else:
        print("\n❌ Authentication flow has issues!")
        print("   Check the backend authentication setup.")

