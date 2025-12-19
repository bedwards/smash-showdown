--[[
    Insert Uploaded Structures into ServerStorage.AssetTemplates

    Run with: ./tools/run-studio-test.sh tools/insert-uploaded-structures.luau

    This script uses InsertService to load the uploaded structure models
    from Roblox cloud and place them in ServerStorage.AssetTemplates.
]]

local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

-- Uploaded structure asset IDs (from Open Cloud API upload)
local STRUCTURE_ASSETS = {
    { name = "Structures_RadioTower", assetId = 74640268702619 },
    { name = "Structures_Bridge", assetId = 80713308347988 },
    { name = "Structures_Lighthouse", assetId = 125802590150635 },
    { name = "Structures_AbandonedHouse", assetId = 113272128221522 },
    { name = "Structures_FerrisWheel", assetId = 124487756821368 },
    { name = "Structures_WaterTower", assetId = 139399916244302 },
}

print("=== Inserting Uploaded Structures ===")

-- Ensure AssetTemplates folder exists
local templatesFolder = ServerStorage:FindFirstChild("AssetTemplates")
if not templatesFolder then
    templatesFolder = Instance.new("Folder")
    templatesFolder.Name = "AssetTemplates"
    templatesFolder.Parent = ServerStorage
    print("[OK] Created ServerStorage.AssetTemplates")
end

-- Insert each structure
local successCount = 0
local failCount = 0

for _, asset in ipairs(STRUCTURE_ASSETS) do
    print(string.format("Loading: %s (assetId: %d)...", asset.name, asset.assetId))

    -- Check if already exists
    local existing = templatesFolder:FindFirstChild(asset.name)
    if existing then
        print(string.format("  [SKIP] %s already exists", asset.name))
        successCount += 1
        continue
    end

    -- Try to load the asset
    local success, result = pcall(function()
        return InsertService:LoadAsset(asset.assetId)
    end)

    if success and result then
        -- LoadAsset returns a Model containing the asset
        local children = result:GetChildren()
        if #children > 0 then
            local model = children[1]
            model.Name = asset.name
            model.Parent = templatesFolder
            print(string.format("  [OK] Inserted %s", asset.name))
            successCount += 1
        else
            print(string.format("  [ERROR] %s - Empty container returned", asset.name))
            failCount += 1
        end
        result:Destroy() -- Clean up the container
    else
        print(string.format("  [ERROR] %s - %s", asset.name, tostring(result)))
        failCount += 1
    end

    -- Rate limiting
    task.wait(0.5)
end

print("")
print("=== Insert Complete ===")
print(string.format("Success: %d, Failed: %d", successCount, failCount))
print(string.format("AssetTemplates now has %d items", #templatesFolder:GetChildren()))

-- Verify structure is correct
print("")
print("=== Verifying Structures ===")
for _, asset in ipairs(STRUCTURE_ASSETS) do
    local model = templatesFolder:FindFirstChild(asset.name)
    if model then
        local partCount = 0
        for _, child in model:GetDescendants() do
            if child:IsA("BasePart") then
                partCount += 1
            end
        end
        print(string.format("  %s: %d parts", asset.name, partCount))
    else
        print(string.format("  %s: NOT FOUND", asset.name))
    end
end

print("=== Done ===")
