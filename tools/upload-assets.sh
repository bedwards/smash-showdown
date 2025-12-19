#!/bin/bash
# Upload FBX assets to Roblox Cloud using Open Cloud API
# Stores asset IDs in assets/cloud-asset-ids.json

set -e

API_KEY=$(cat .secrets/roblox-api-key)
CREATOR_ID="5514421781"  # User ID from the API key
OUTPUT_FILE="assets/cloud-asset-ids.json"

# Initialize output file
echo "{" > "$OUTPUT_FILE"
echo '  "structures": {' >> "$OUTPUT_FILE"

FIRST=true

upload_asset() {
    local name=$1
    local file=$2
    local display_name=$3

    echo "Uploading $name from $file..."

    # Create the request
    response=$(curl -s -X POST \
        "https://apis.roblox.com/assets/v1/assets" \
        -H "x-api-key: $API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F "request={\"assetType\":\"Model\",\"displayName\":\"$display_name\",\"description\":\"Faultline Fear structure: $display_name\",\"creationContext\":{\"creator\":{\"userId\":\"$CREATOR_ID\"}}};type=application/json" \
        -F "fileContent=@$file;type=model/fbx")

    echo "Response: $response"

    # Extract operation ID for polling
    operation_id=$(echo "$response" | grep -o '"operationId":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$operation_id" ]; then
        echo "Operation ID: $operation_id"

        # Poll for completion
        for i in {1..30}; do
            sleep 2
            status_response=$(curl -s -X GET \
                "https://apis.roblox.com/assets/v1/operations/$operation_id" \
                -H "x-api-key: $API_KEY")

            echo "Status check $i: $status_response"

            # Check if done
            if echo "$status_response" | grep -q '"done":true'; then
                asset_id=$(echo "$status_response" | grep -o '"assetId":"[^"]*"' | cut -d'"' -f4)
                if [ -n "$asset_id" ]; then
                    echo "SUCCESS: $name uploaded with ID: $asset_id"

                    if [ "$FIRST" = true ]; then
                        FIRST=false
                    else
                        echo "," >> "$OUTPUT_FILE"
                    fi
                    echo "    \"$name\": \"$asset_id\"" >> "$OUTPUT_FILE"
                    return 0
                fi
            fi

            # Check for error
            if echo "$status_response" | grep -q '"error"'; then
                echo "ERROR uploading $name"
                return 1
            fi
        done
        echo "TIMEOUT waiting for $name"
        return 1
    else
        echo "ERROR: No operation ID returned for $name"
        echo "$response"
        return 1
    fi
}

# Upload each structure
upload_asset "FerrisWheel" "assets/models/structures/ferris_wheel.fbx" "FerrisWheel"
upload_asset "RadioTower" "assets/models/structures/radio_tower.fbx" "RadioTower"
upload_asset "WaterTower" "assets/models/structures/water_tower.fbx" "WaterTower"
upload_asset "Lighthouse" "assets/models/structures/lighthouse.fbx" "Lighthouse"
upload_asset "AbandonedHouse" "assets/models/structures/abandoned_house.fbx" "AbandonedHouse"
upload_asset "Bridge" "assets/models/structures/bridge.fbx" "Bridge"

# Close JSON
echo "" >> "$OUTPUT_FILE"
echo "  }" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo ""
echo "Asset IDs saved to $OUTPUT_FILE"
cat "$OUTPUT_FILE"
