#!/usr/bin/env python3
"""
Upload FBX assets to Roblox via Open Cloud API.

This script:
1. Reads FBX files from assets/faultline-fear/meshes/
2. Uploads each to Roblox Open Cloud API
3. Saves the resulting asset IDs to assets/faultline-fear/asset-ids.json

Usage:
    python tools/upload-assets-to-roblox.py

Requires:
    - .secrets/roblox-api-key file with your Open Cloud API key
    - requests library (pip install requests)
"""

import json
import os
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: requests library not installed")
    print("Run: pip install requests")
    sys.exit(1)

# Configuration
PROJECT_ROOT = Path(__file__).parent.parent
SECRETS_DIR = PROJECT_ROOT / ".secrets"
API_KEY_FILE = SECRETS_DIR / "roblox-api-key"
MESHES_DIR = PROJECT_ROOT / "assets" / "faultline-fear" / "meshes"
OUTPUT_FILE = PROJECT_ROOT / "assets" / "faultline-fear" / "asset-ids.json"

# Roblox Open Cloud API
ASSETS_API_URL = "https://apis.roblox.com/assets/v1/assets"
OPERATIONS_API_URL = "https://apis.roblox.com/assets/v1/operations"

def load_api_key() -> str:
    """Load the Roblox API key from .secrets/"""
    if not API_KEY_FILE.exists():
        print(f"ERROR: API key file not found: {API_KEY_FILE}")
        print("Create it with: echo 'YOUR_API_KEY' > .secrets/roblox-api-key")
        sys.exit(1)

    return API_KEY_FILE.read_text().strip()

def get_user_id_from_key(api_key: str) -> str:
    """Extract user ID from JWT token in API key."""
    # The API key contains a JWT - we can decode the payload to get the owner ID
    # Format: base64(header).base64(payload).signature
    import base64

    try:
        # The key has a prefix before the JWT
        parts = api_key.split('.')
        if len(parts) >= 2:
            # Decode the payload (second part)
            payload = parts[1]
            # Add padding if needed
            padding = 4 - len(payload) % 4
            if padding != 4:
                payload += '=' * padding
            decoded = base64.urlsafe_b64decode(payload)
            data = json.loads(decoded)
            if 'ownerId' in data:
                return data['ownerId']
    except Exception as e:
        print(f"Warning: Could not extract user ID from key: {e}")

    # Fallback - ask user or use a default
    print("ERROR: Could not determine user ID from API key")
    print("Please set ROBLOX_USER_ID environment variable")
    sys.exit(1)

def upload_fbx(api_key: str, user_id: str, fbx_path: Path, display_name: str) -> dict:
    """
    Upload an FBX file to Roblox and return the operation info.

    Returns dict with 'operationId' for polling status.
    """
    headers = {
        "x-api-key": api_key,
    }

    # Prepare the request metadata
    request_data = {
        "assetType": "Model",
        "displayName": display_name,
        "description": f"Faultline Fear asset: {display_name}",
        "creationContext": {
            "creator": {
                "userId": str(user_id)
            }
        }
    }

    # Read the FBX file
    with open(fbx_path, 'rb') as f:
        fbx_content = f.read()

    # Multipart form data
    files = {
        'request': (None, json.dumps(request_data), 'application/json'),
        'fileContent': (fbx_path.name, fbx_content, 'model/fbx')
    }

    print(f"  Uploading {fbx_path.name}...")
    response = requests.post(ASSETS_API_URL, headers=headers, files=files)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"  ERROR: Upload failed with status {response.status_code}")
        print(f"  Response: {response.text}")
        return None

def poll_operation(api_key: str, operation_path: str, max_attempts: int = 30) -> dict:
    """
    Poll an operation until it completes.

    Returns the final operation result with asset info.
    """
    headers = {
        "x-api-key": api_key,
    }

    # The operation path is like "operations/uuid"
    url = f"https://apis.roblox.com/assets/v1/{operation_path}"

    for attempt in range(max_attempts):
        response = requests.get(url, headers=headers)

        if response.status_code != 200:
            print(f"  Warning: Poll failed with status {response.status_code}")
            time.sleep(2)
            continue

        data = response.json()

        if data.get("done"):
            return data

        # Still processing
        print(f"  Processing... (attempt {attempt + 1}/{max_attempts})")
        time.sleep(2)

    print("  ERROR: Operation timed out")
    return None

def extract_asset_id(operation_result: dict) -> str:
    """Extract the asset ID from a completed operation."""
    if not operation_result:
        return None

    # The response structure varies - try different paths
    response = operation_result.get("response", {})

    # Try to get assetId directly
    if "assetId" in response:
        return response["assetId"]

    # Try path field (format: "assets/123456")
    path = response.get("path", "")
    if path.startswith("assets/"):
        return path.split("/")[1]

    # Check for error
    if "error" in operation_result:
        print(f"  ERROR: {operation_result['error']}")

    return None

def main():
    print("=" * 60)
    print("ROBLOX ASSET UPLOADER")
    print("=" * 60)
    print()

    # Load API key
    api_key = load_api_key()
    print(f"[OK] API key loaded from {API_KEY_FILE}")

    # Get user ID
    user_id = get_user_id_from_key(api_key)
    print(f"[OK] User ID: {user_id}")

    # Find FBX files
    if not MESHES_DIR.exists():
        print(f"ERROR: Meshes directory not found: {MESHES_DIR}")
        sys.exit(1)

    fbx_files = list(MESHES_DIR.glob("*.fbx"))
    print(f"[OK] Found {len(fbx_files)} FBX files in {MESHES_DIR}")
    print()

    if not fbx_files:
        print("No FBX files to upload.")
        return

    # Load existing asset IDs (to avoid re-uploading)
    existing_ids = {}
    if OUTPUT_FILE.exists():
        existing_ids = json.loads(OUTPUT_FILE.read_text())
        print(f"[OK] Loaded {len(existing_ids)} existing asset IDs")

    # Upload each FBX
    asset_ids = existing_ids.copy()
    uploaded_count = 0

    for fbx_path in fbx_files:
        # Use filename without extension as display name
        display_name = fbx_path.stem

        # Skip if already uploaded
        if display_name in asset_ids:
            print(f"[SKIP] {display_name} (already uploaded: {asset_ids[display_name]})")
            continue

        print(f"[UPLOAD] {display_name}")

        # Upload
        operation = upload_fbx(api_key, user_id, fbx_path, display_name)
        if not operation:
            continue

        # Get operation path for polling
        operation_path = operation.get("path")
        if not operation_path:
            print(f"  Warning: No operation path in response")
            continue

        # Poll for completion
        result = poll_operation(api_key, operation_path)

        # Extract asset ID
        asset_id = extract_asset_id(result)
        if asset_id:
            asset_ids[display_name] = asset_id
            print(f"  [OK] Asset ID: {asset_id}")
            uploaded_count += 1
        else:
            print(f"  [FAIL] Could not get asset ID")

    # Save asset IDs
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(asset_ids, indent=2))
    print()
    print(f"[OK] Saved {len(asset_ids)} asset IDs to {OUTPUT_FILE}")
    print(f"[OK] Uploaded {uploaded_count} new assets")
    print()
    print("Next step: Run 'lune run tools/create-rbxm-from-assets.luau' to generate .rbxm files")

if __name__ == "__main__":
    main()
