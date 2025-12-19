--[[
    Download uploaded structure assets from Roblox and save as .rbxm files.

    Run with: remodel run tools/download-structures.lua

    Note: May require authentication for private assets.
    Use: remodel run --auth YOUR_COOKIE tools/download-structures.lua
]]

local STRUCTURE_ASSETS = {
    { name = "Structures_RadioTower", assetId = "74640268702619" },
    { name = "Structures_Bridge", assetId = "80713308347988" },
    { name = "Structures_Lighthouse", assetId = "125802590150635" },
    { name = "Structures_AbandonedHouse", assetId = "113272128221522" },
    { name = "Structures_FerrisWheel", assetId = "124487756821368" },
    { name = "Structures_WaterTower", assetId = "139399916244302" },
}

local OUTPUT_DIR = "assets/faultline-fear/rbxm"

print("=== Downloading Structure Assets ===")
print("Output directory: " .. OUTPUT_DIR)
print("")

local successCount = 0
local failCount = 0

for _, asset in ipairs(STRUCTURE_ASSETS) do
    print(string.format("Downloading: %s (assetId: %s)...", asset.name, asset.assetId))

    local ok, result = pcall(function()
        local instances = remodel.readModelAsset(asset.assetId)

        if #instances == 0 then
            error("No instances returned")
        end

        -- Get the first instance (the model container)
        local model = instances[1]

        -- Save as .rbxm
        local outputPath = OUTPUT_DIR .. "/" .. asset.name .. ".rbxm"
        remodel.writeModelFile(outputPath, model)

        return model
    end)

    if ok then
        print(string.format("  [OK] Saved to %s/%s.rbxm", OUTPUT_DIR, asset.name))
        successCount = successCount + 1
    else
        print(string.format("  [ERROR] %s", tostring(result)))
        failCount = failCount + 1
    end
end

print("")
print("=== Download Complete ===")
print(string.format("Success: %d, Failed: %d", successCount, failCount))
