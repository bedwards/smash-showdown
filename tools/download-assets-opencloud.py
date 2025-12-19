#!/usr/bin/env python3
"""
Download asset content from Roblox using Open Cloud API.

This downloads the raw asset content and saves it locally.
"""

import os
import sys
import requests

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
SECRETS_PATH = os.path.join(PROJECT_ROOT, ".secrets", "roblox-api-key")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "faultline-fear", "rbxm")

# Asset IDs from the upload
STRUCTURE_ASSETS = [
    {"name": "Structures_RadioTower", "assetId": "74640268702619"},
    {"name": "Structures_Bridge", "assetId": "80713308347988"},
    {"name": "Structures_Lighthouse", "assetId": "125802590150635"},
    {"name": "Structures_AbandonedHouse", "assetId": "113272128221522"},
    {"name": "Structures_FerrisWheel", "assetId": "124487756821368"},
    {"name": "Structures_WaterTower", "assetId": "139399916244302"},
]


def load_api_key() -> str:
    """Load API key from secrets file."""
    if not os.path.exists(SECRETS_PATH):
        print(f"ERROR: API key not found at {SECRETS_PATH}")
        sys.exit(1)

    with open(SECRETS_PATH, "r") as f:
        key = f.read().strip()

    return key


def download_asset(asset_id: str, api_key: str) -> bytes:
    """Download asset content using Open Cloud API."""
    # Try the asset delivery API first
    url = f"https://apis.roblox.com/assets/v1/assets/{asset_id}"

    headers = {
        "x-api-key": api_key,
    }

    response = requests.get(url, headers=headers)
    print(f"  Asset info status: {response.status_code}")

    if response.status_code == 200:
        asset_info = response.json()
        print(f"  Asset info: {asset_info}")

        # Check if there's a download URL in the response
        if "downloadUrl" in asset_info:
            content_response = requests.get(asset_info["downloadUrl"])
            if content_response.status_code == 200:
                return content_response.content

    # Try the asset delivery endpoint (legacy)
    delivery_url = f"https://assetdelivery.roblox.com/v1/asset/?id={asset_id}"
    response = requests.get(delivery_url)
    print(f"  Delivery status: {response.status_code}")

    if response.status_code == 200:
        return response.content

    # Try with auth header
    response = requests.get(delivery_url, headers={"x-api-key": api_key})
    print(f"  Delivery with auth status: {response.status_code}")

    if response.status_code == 200:
        return response.content

    return None


def main():
    print("=== Downloading Structure Assets via Open Cloud ===")

    api_key = load_api_key()
    print(f"API key loaded (length: {len(api_key)})")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    success_count = 0
    fail_count = 0

    for asset in STRUCTURE_ASSETS:
        print(f"\nDownloading: {asset['name']} (assetId: {asset['assetId']})...")

        try:
            content = download_asset(asset["assetId"], api_key)

            if content:
                output_path = os.path.join(OUTPUT_DIR, f"{asset['name']}.rbxm")
                with open(output_path, "wb") as f:
                    f.write(content)
                print(f"  [OK] Saved to {output_path}")
                print(f"  Size: {len(content)} bytes")
                success_count += 1
            else:
                print(f"  [ERROR] No content returned")
                fail_count += 1

        except Exception as e:
            print(f"  [ERROR] {e}")
            fail_count += 1

    print(f"\n=== Download Complete ===")
    print(f"Success: {success_count}, Failed: {fail_count}")


if __name__ == "__main__":
    main()
