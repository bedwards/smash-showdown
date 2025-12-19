#!/usr/bin/env python3
"""
Upload FBX files to Roblox using Open Cloud API.

Usage:
    python tools/upload-fbx-to-roblox.py

This script:
1. Reads FBX files from assets/models/structures/
2. Uploads each to Roblox via Open Cloud API
3. Prints the resulting asset IDs for use in the game

Requirements:
    pip install requests

API Key:
    Stored in .secrets/roblox-api-key
    Must have "Create and update assets" permission
"""

import os
import sys
import json
import time
import requests

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
SECRETS_PATH = os.path.join(PROJECT_ROOT, ".secrets", "roblox-api-key")
FBX_DIR = os.path.join(PROJECT_ROOT, "assets", "models", "structures")
OUTPUT_FILE = os.path.join(PROJECT_ROOT, "assets", "faultline-fear", "uploaded-assets.json")

# Roblox Open Cloud API endpoint
API_BASE = "https://apis.roblox.com/assets/v1"

# Creator info - you may need to update this
CREATOR_TYPE = "User"  # or "Group"
CREATOR_ID = "5514421781"  # Your Roblox user ID (from previous session)


def load_api_key() -> str:
    """Load API key from secrets file."""
    if not os.path.exists(SECRETS_PATH):
        print(f"ERROR: API key not found at {SECRETS_PATH}")
        print("Please create the file with your Roblox Open Cloud API key.")
        sys.exit(1)

    with open(SECRETS_PATH, "r") as f:
        key = f.read().strip()

    if not key:
        print("ERROR: API key file is empty")
        sys.exit(1)

    return key


def upload_fbx(filepath: str, api_key: str, name: str, description: str) -> dict:
    """
    Upload an FBX file to Roblox.

    Returns the asset info including the asset ID.
    """
    print(f"Uploading: {name}...")

    # Prepare the request
    url = f"{API_BASE}/assets"

    headers = {
        "x-api-key": api_key,
    }

    # The request body for asset creation
    request_body = {
        "assetType": "Model",
        "displayName": name,
        "description": description,
        "creationContext": {
            "creator": {
                "userId": CREATOR_ID
            }
        }
    }

    # Read the FBX file
    with open(filepath, "rb") as f:
        file_content = f.read()

    # Multipart form data
    files = {
        "request": (None, json.dumps(request_body), "application/json"),
        "fileContent": (os.path.basename(filepath), file_content, "model/fbx")
    }

    try:
        response = requests.post(url, headers=headers, files=files)
        response.raise_for_status()
        result = response.json()
        print(f"  Success! Operation ID: {result.get('path', 'unknown')}")
        return result
    except requests.exceptions.HTTPError as e:
        print(f"  ERROR: {e}")
        print(f"  Response: {response.text}")
        return {"error": str(e), "response": response.text}
    except Exception as e:
        print(f"  ERROR: {e}")
        return {"error": str(e)}


def check_operation_status(operation_id: str, api_key: str) -> dict:
    """Check the status of an upload operation."""
    url = f"{API_BASE}/{operation_id}"
    headers = {"x-api-key": api_key}

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        return {"error": str(e)}


def main():
    print("=" * 60)
    print("Faultline Fear: FBX Upload to Roblox")
    print("=" * 60)

    # Load API key
    api_key = load_api_key()
    print(f"API key loaded (length: {len(api_key)})")

    # Find FBX files
    if not os.path.exists(FBX_DIR):
        print(f"ERROR: FBX directory not found: {FBX_DIR}")
        sys.exit(1)

    fbx_files = [f for f in os.listdir(FBX_DIR) if f.endswith(".fbx")]

    if not fbx_files:
        print(f"No FBX files found in {FBX_DIR}")
        sys.exit(0)

    print(f"Found {len(fbx_files)} FBX files to upload:")
    for f in fbx_files:
        print(f"  - {f}")
    print()

    # Upload each file
    results = {}
    operations = []

    for fbx_file in fbx_files:
        filepath = os.path.join(FBX_DIR, fbx_file)

        # Create a nice name from filename
        name = fbx_file.replace(".fbx", "").replace("_", " ").title()
        name = f"Structures_{name.replace(' ', '')}"

        description = f"Faultline Fear structure: {name}"

        result = upload_fbx(filepath, api_key, name, description)
        results[fbx_file] = result

        if "path" in result:
            operations.append({
                "file": fbx_file,
                "operation": result["path"]
            })

        # Rate limiting - wait between uploads
        time.sleep(1)

    print()
    print("=" * 60)
    print("Upload Results")
    print("=" * 60)

    # Check operation statuses
    print("\nChecking operation statuses...")
    time.sleep(5)  # Wait for processing

    final_results = {}
    for op in operations:
        status = check_operation_status(op["operation"], api_key)
        print(f"\n{op['file']}:")

        if "done" in status and status["done"]:
            if "response" in status:
                asset_info = status["response"]
                asset_id = asset_info.get("assetId", "unknown")
                print(f"  Asset ID: {asset_id}")
                print(f"  State: {asset_info.get('state', 'unknown')}")
                final_results[op["file"]] = {
                    "assetId": asset_id,
                    "name": asset_info.get("displayName", ""),
                    "state": asset_info.get("state", "")
                }
            elif "error" in status:
                print(f"  Error: {status['error']}")
                final_results[op["file"]] = {"error": status["error"]}
        else:
            print(f"  Status: Still processing...")
            print(f"  Check operation: {op['operation']}")
            final_results[op["file"]] = {
                "operation": op["operation"],
                "status": "processing"
            }

    # Save results
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(final_results, f, indent=2)

    print(f"\nResults saved to: {OUTPUT_FILE}")
    print("\nTo use these assets in the game:")
    print("1. Find them in Roblox Studio: Toolbox > Inventory > My Models")
    print("2. Insert into ServerStorage.AssetTemplates")
    print("3. Or use the asset IDs directly in code")


if __name__ == "__main__":
    main()
