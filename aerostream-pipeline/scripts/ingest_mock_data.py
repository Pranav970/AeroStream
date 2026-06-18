import requests
import json
import time
import random
import threading

# ⚠️ PASTE YOUR TERRAFORM OUTPUT URL HERE ⚠️
API_URL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/ingest"

# Use a session for connection pooling (much faster for high velocity)
session = requests.Session()
session.headers.update({"Content-Type": "application/json"})

def send_payload(payload_id, inject_error=False):
    payload = {
        "event_id": f"evt_{payload_id}",
        "user_id": f"usr_{random.randint(100, 999)}",
        "action": random.choice(["click", "purchase", "sign_up", "view_item"]),
        "timestamp": int(time.time())
    }
    
    if inject_error:
        # Intentionally corrupt the payload to test the DLQ
        del payload["user_id"]
        print(f"[⚠️ WARNING] Injecting corrupted payload ID {payload_id} to test DLQ.")

    try:
        response = session.post(API_URL, json=payload)
        if response.status_code in [200, 202]:
            print(f"[✅ SUCCESS] Dispatched Event ID: {payload_id}")
        else:
            print(f"[❌ FAILED] Event ID: {payload_id} | Status: {response.status_code} | {response.text}")
    except Exception as e:
        print(f"[🚨 NETWORK ERROR] Event ID: {payload_id} | {e}")

def run_stress_test():
    print(f"🚀 Initiating ZeroScale API Ingestion Test...")
    print(f"Target URL: {API_URL}\n")
    
    threads = []
    
    # Fire 20 events rapidly
    for i in range(1, 21):
        # Make the 7th and 14th payloads fail on purpose
        inject_error = (i == 7 or i == 14)
        
        # Using threading to simulate concurrent user load
        t = threading.Thread(target=send_payload, args=(i, inject_error))
        threads.append(t)
        t.start()
        time.sleep(0.1) # Slight offset to prevent local port exhaustion
        
    for t in threads:
        t.join()
        
    print("\n🏁 Stress test complete. Check AWS CloudWatch and SQS Queues!")

if __name__ == "__main__":
    if "YOUR_API_ID" in API_URL:
        print("❌ ERROR: You must replace the API_URL variable with your actual Terraform output URL.")
    else:
        run_stress_test()
