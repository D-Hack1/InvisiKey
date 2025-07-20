#!/usr/bin/env python3
"""
Test script to verify the account lockout functionality.
This script tests the lockout mechanism by simulating failed login attempts.
"""

import requests
import json
import time

BASE_URL = "https://canara-backend-fjmu.onrender.com"

def test_lockout_functionality():
    """Test the complete lockout flow"""
    print("🧪 Testing Account Lockout Functionality")
    print("=" * 50)
    
    # Test data
    test_username = "lockout_test_user"
    test_password = "wrong_password"
    test_email = "test@example.com"
    admin_password = "admin123"
    
    # Step 1: Create a test user
    print("\n1. Creating test user...")
    signup_data = {
        "username": test_username,
        "email": test_email,
        "password": "correct_password",
        "rhythm_samples": [
            {"intervals": [100, 200, 300], "label": "valid_user"}
        ],
        "secret_button": "Contact Us"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/signup", json=signup_data)
        if response.status_code == 200:
            print("✅ Test user created successfully")
        else:
            print(f"⚠️ User might already exist: {response.json()}")
    except Exception as e:
        print(f"❌ Failed to create test user: {e}")
        return
    
    # Step 2: Test PIN lockout (failed login attempts)
    print("\n2. Testing PIN lockout...")
    for attempt in range(1, 5):  # Try 4 times to trigger lockout
        print(f"   Attempt {attempt}/4: Trying wrong password...")
        
        try:
            response = requests.post(f"{BASE_URL}/login", json={
                "username": test_username,
                "password": test_password
            })
            
            if response.status_code == 423:
                print(f"   ✅ Account locked after {attempt} attempts!")
                lockout_data = response.json()
                print(f"   📧 Lockout reason: {lockout_data.get('detail', 'Unknown')}")
                break
            elif response.status_code == 401:
                data = response.json()
                print(f"   ⚠️ Failed attempt {attempt}: {data.get('detail', 'Invalid credentials')}")
            else:
                print(f"   ❌ Unexpected response: {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ Request failed: {e}")
            break
    
    # Step 3: Test admin unlock
    print("\n3. Testing admin unlock...")
    try:
        response = requests.post(f"{BASE_URL}/admin/unlock-account", json={
            "username": test_username,
            "admin_password": admin_password
        })
        
        if response.status_code == 200:
            print("✅ Account unlocked successfully by admin")
            unlock_data = response.json()
            print(f"   📝 Message: {unlock_data.get('message', 'Unknown')}")
        else:
            print(f"❌ Failed to unlock account: {response.status_code}")
            print(f"   📝 Response: {response.json()}")
            
    except Exception as e:
        print(f"❌ Admin unlock failed: {e}")
    
    # Step 4: Test successful login after unlock
    print("\n4. Testing successful login after unlock...")
    try:
        response = requests.post(f"{BASE_URL}/login", json={
            "username": test_username,
            "password": "correct_password"
        })
        
        if response.status_code == 200:
            print("✅ Login successful after unlock")
            login_data = response.json()
            token = login_data.get("access_token")
            print(f"   🔑 Token received: {token[:20]}...")
            
            # Step 5: Test rhythm lockout
            print("\n5. Testing rhythm lockout...")
            for attempt in range(1, 5):  # Try 4 times to trigger lockout
                print(f"   Attempt {attempt}/4: Trying wrong rhythm...")
                
                try:
                    response = requests.post(f"{BASE_URL}/verify-tap", 
                        headers={"Authorization": f"Bearer {token}"},
                        json={
                            "tap_rhythm_attempt": [999, 999, 999],  # Wrong rhythm
                            "button": "Contact Us"
                        }
                    )
                    
                    if response.status_code == 423:
                        print(f"   ✅ Account locked after {attempt} rhythm attempts!")
                        lockout_data = response.json()
                        print(f"   📧 Lockout reason: {lockout_data.get('detail', 'Unknown')}")
                        break
                    elif response.status_code == 401:
                        data = response.json()
                        print(f"   ⚠️ Failed rhythm attempt {attempt}: {data.get('detail', 'Rhythm verification failed')}")
                    else:
                        print(f"   ❌ Unexpected response: {response.status_code}")
                        
                except Exception as e:
                    print(f"   ❌ Rhythm request failed: {e}")
                    break
                    
        else:
            print(f"❌ Login failed after unlock: {response.status_code}")
            print(f"   📝 Response: {response.json()}")
            
    except Exception as e:
        print(f"❌ Login test failed: {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Lockout functionality test completed!")

if __name__ == "__main__":
    print("Make sure the backend is running on https://canara-backend-fjmu.onrender.com")
    print("Press Enter to start testing...")
    input()
    
    test_lockout_functionality() 