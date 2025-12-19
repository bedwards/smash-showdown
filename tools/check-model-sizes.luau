--!strict
--[[
    Experiment: Check actual model sizes in Roblox

    This script checks the bounding box sizes of all structures
    loaded from cloud assets to see what dimensions Roblox actually imported.
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

print("=" .. string.rep("=", 59))
print("MODEL SIZE EXPERIMENT")
print("=" .. string.rep("=", 59))

-- Wait for structures folder (game needs to load first)
print("Waiting for Structures folder...")
local structuresFolder = Workspace:WaitForChild("Structures", 60)
if not structuresFolder then
    print("ERROR: Structures folder not found after 60 seconds")
    return
end

-- Wait a bit more for all structures to spawn
task.wait(5)
print("Structures folder found, analyzing...")

print("\nStructures found in Workspace.Structures:")
print("-" .. string.rep("-", 59))

local results = {}

for _, model in structuresFolder:GetChildren() do
    if model:IsA("Model") then
        local name = model.Name

        -- Calculate bounding box
        local minBound = Vector3.new(math.huge, math.huge, math.huge)
        local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
        local partCount = 0

        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                partCount += 1
                local pos = part.Position
                local size = part.Size

                -- Expand bounds
                minBound = Vector3.new(
                    math.min(minBound.X, pos.X - size.X/2),
                    math.min(minBound.Y, pos.Y - size.Y/2),
                    math.min(minBound.Z, pos.Z - size.Z/2)
                )
                maxBound = Vector3.new(
                    math.max(maxBound.X, pos.X + size.X/2),
                    math.max(maxBound.Y, pos.Y + size.Y/2),
                    math.max(maxBound.Z, pos.Z + size.Z/2)
                )
            end
        end

        local boundingSize = maxBound - minBound

        -- Also check PrimaryPart size
        local primarySize = Vector3.new(0, 0, 0)
        if model.PrimaryPart then
            primarySize = model.PrimaryPart.Size
        end

        table.insert(results, {
            name = name,
            partCount = partCount,
            boundingSize = boundingSize,
            primarySize = primarySize,
            position = model:GetPivot().Position,
        })

        print(string.format("\n%s:", name))
        print(string.format("  Parts: %d", partCount))
        print(string.format("  Bounding box: %.1f x %.1f x %.1f studs",
            boundingSize.X, boundingSize.Y, boundingSize.Z))
        print(string.format("  PrimaryPart size: %.1f x %.1f x %.1f",
            primarySize.X, primarySize.Y, primarySize.Z))
        print(string.format("  Position: (%.0f, %.0f, %.0f)",
            model:GetPivot().Position.X,
            model:GetPivot().Position.Y,
            model:GetPivot().Position.Z))
    end
end

-- Summary
print("\n" .. "=" .. string.rep("=", 59))
print("SUMMARY")
print("=" .. string.rep("=", 59))

-- Expected sizes from create_structures.py (in Blender units, times scale)
local expectedSizes = {
    WaterTower_Main = 35, -- "~35 studs tall"
    RadioTower_Main = 60, -- "~60 studs tall"
    FerrisWheel_Main = 45, -- "~40-45 studs tall"
    Lighthouse_Main = 30, -- "~30 studs tall"
    Bridge_Main = 80, -- "~80 studs long"
}

print("\nExpected vs Actual heights/lengths:")
for _, r in ipairs(results) do
    local expected = expectedSizes[r.name]
    if expected then
        local actual = math.max(r.boundingSize.X, r.boundingSize.Y, r.boundingSize.Z)
        local ratio = actual / expected
        print(string.format("  %s: expected ~%d, actual %.1f (%.2fx)",
            r.name, expected, actual, ratio))
    end
end

-- Check if models are tiny
local tinyModels = {}
for _, r in ipairs(results) do
    local maxDim = math.max(r.boundingSize.X, r.boundingSize.Y, r.boundingSize.Z)
    if maxDim < 5 then
        table.insert(tinyModels, r.name .. " (" .. string.format("%.2f", maxDim) .. " studs)")
    end
end

if #tinyModels > 0 then
    print("\nWARNING: These models are TINY (< 5 studs):")
    for _, name in ipairs(tinyModels) do
        print("  - " .. name)
    end
    print("\nThis confirms Roblox is NOT respecting FBX scale!")
end

print("\n" .. "=" .. string.rep("=", 59))
