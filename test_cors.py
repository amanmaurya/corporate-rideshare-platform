#!/usr/bin/env python3
"""
Quick CORS test to verify backend accessibility
"""

import requests
import json

def test_cors():
    """Test CORS configuration"""
    base_url = "http://localhost:8000"
    
    print("🔍 Testing CORS Configuration...")
    print("=" * 40)
    
    # Test 1: Basic health check
    try:
        response = requests.get(f"{base_url}/health")
        print(f"✅ Health Check: {response.status_code}")
        print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ Health Check Failed: {e}")
    
    # Test 2: CORS headers on rides endpoint
    try:
        response = requests.options(f"{base_url}/api/v1/rides/")
        print(f"\n✅ CORS Preflight: {response.status_code}")
        print(f"   CORS Headers:")
        for header, value in response.headers.items():
            if 'access-control' in header.lower():
                print(f"     {header}: {value}")
    except Exception as e:
        print(f"❌ CORS Preflight Failed: {e}")
    
    # Test 3: Actual rides endpoint
    try:
        response = requests.get(f"{base_url}/api/v1/rides/")
        print(f"\n✅ Rides Endpoint: {response.status_code}")
        print(f"   CORS Headers:")
        for header, value in response.headers.items():
            if 'access-control' in header.lower():
                print(f"     {header}: {value}")
    except Exception as e:
        print(f"❌ Rides Endpoint Failed: {e}")
    
    # Test 4: Simulate browser request
    try:
        headers = {
            'Origin': 'http://localhost:59167',
            'Access-Control-Request-Method': 'GET',
            'Access-Control-Request-Headers': 'Content-Type, Authorization'
        }
        response = requests.options(f"{base_url}/api/v1/rides/", headers=headers)
        print(f"\n✅ Browser CORS Test: {response.status_code}")
        print(f"   Response Headers:")
        for header, value in response.headers.items():
            if 'access-control' in header.lower():
                print(f"     {header}: {value}")
    except Exception as e:
        print(f"❌ Browser CORS Test Failed: {e}")

if __name__ == "__main__":
    test_cors()

