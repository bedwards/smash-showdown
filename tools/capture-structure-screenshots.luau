--[[
    Capture Screenshots of All Structures from Multiple Angles

    Run with: ./tools/run-studio-test.sh tools/capture-structure-screenshots.luau

    This script:
    1. Loads each structure from cloud via InsertService
    2. Places it in workspace
    3. Positions camera at multiple angles
    4. Captures screenshots via HTTP to local server
]]

local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Screenshot server URL
local SCREENSHOT_SERVER = "http://localhost:28081"

-- Structure cloud asset IDs
local STRUCTURES = {
    { name = "RadioTower", assetId = 74640268702619 },
    { name = "Bridge", assetId = 80713308347988 },
    { name = "Lighthouse", assetId = 125802590150635 },
    { name = "AbandonedHouse", assetId = 113272128221522 },
    { name = "FerrisWheel", assetId = 124487756821368 },
    { name = "WaterTower", assetId = 139399916244302 },
}

-- Camera angles relative to structure center
local CAMERA_ANGLES = {
    { name = "front", offset = Vector3.new(0, 5, 30), lookOffset = Vector3.new(0, 5, 0) },
    { name = "side", offset = Vector3.new(30, 5, 0), lookOffset = Vector3.new(0, 5, 0) },
    { name = "top", offset = Vector3.new(0, 40, 10), lookOffset = Vector3.new(0, 0, 0) },
    { name = "close", offset = Vector3.new(0, 3, 12), lookOffset = Vector3.new(0, 3, 0) },
    { name = "far", offset = Vector3.new(20, 15, 50), lookOffset = Vector3.new(0, 8, 0) },
}

print("╔════════════════════════════════════════════════╗")
print("║     STRUCTURE SCREENSHOT CAPTURE               ║")
print("╚════════════════════════════════════════════════╝")

-- Check if screenshot server is available
local serverAvailable = false
local success, result = pcall(function()
    return HttpService:GetAsync(SCREENSHOT_SERVER .. "/health")
end)

if success then
    serverAvailable = true
    print("[OK] Screenshot server is running")
else
    print("[WARN] Screenshot server not available - will output structure info only")
    print("       Start server with: cd tools/roblox-screenshot && node .")
end

-- Create a folder for spawned structures
local structuresFolder = Instance.new("Folder")
structuresFolder.Name = "TestStructures"
structuresFolder.Parent = Workspace

local camera = Workspace.CurrentCamera

-- Track results
local structureResults = {}

for _, structureDef in ipairs(STRUCTURES) do
    print("")
    print(string.format("=== Loading: %s (ID: %d) ===", structureDef.name, structureDef.assetId))

    -- Try to load from cloud
    local loadSuccess, loadResult = pcall(function()
        return InsertService:LoadAsset(structureDef.assetId)
    end)

    if not loadSuccess then
        print(string.format("  [ERROR] Failed to load: %s", tostring(loadResult)))
        table.insert(structureResults, {
            name = structureDef.name,
            status = "FAILED",
            error = tostring(loadResult),
        })
        continue
    end

    -- Get the model from container
    local container = loadResult
    local children = container:GetChildren()

    if #children == 0 then
        print("  [ERROR] Empty container returned")
        container:Destroy()
        table.insert(structureResults, {
            name = structureDef.name,
            status = "EMPTY",
        })
        continue
    end

    local model = children[1]
    model.Name = structureDef.name
    model.Parent = structuresFolder

    -- Analyze the structure
    local partCount = 0
    local meshPartCount = 0
    local hasColor = false
    local colors = {}

    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            partCount = partCount + 1
            if descendant:IsA("MeshPart") then
                meshPartCount = meshPartCount + 1
            end

            -- Check color
            local color = descendant.BrickColor.Name
            if color ~= "Medium stone grey" and color ~= "Dark stone grey" then
                hasColor = true
            end
            colors[color] = (colors[color] or 0) + 1
        end
    end

    print(string.format("  Parts: %d (MeshParts: %d)", partCount, meshPartCount))
    print(string.format("  Has color: %s", hasColor and "YES" or "NO (gray)"))

    -- Print color breakdown
    print("  Colors found:")
    for color, count in pairs(colors) do
        print(string.format("    - %s: %d parts", color, count))
    end

    -- Get bounding box
    local cf, size = model:GetBoundingBox()
    print(string.format("  Size: %.1f x %.1f x %.1f studs", size.X, size.Y, size.Z))

    -- Position for viewing
    local viewPosition = Vector3.new(0, size.Y / 2, 0)
    model:PivotTo(CFrame.new(viewPosition))

    -- Take screenshots from each angle
    if serverAvailable then
        for _, angle in ipairs(CAMERA_ANGLES) do
            -- Position camera
            local camPos = viewPosition + angle.offset
            local lookAt = viewPosition + angle.lookOffset
            camera.CFrame = CFrame.lookAt(camPos, lookAt)

            -- Wait for render
            RunService.RenderStepped:Wait()
            RunService.RenderStepped:Wait()
            task.wait(0.1)

            -- Request screenshot
            local screenshotName = string.format("structure_%s_%s", structureDef.name, angle.name)
            local screenshotSuccess, screenshotResult = pcall(function()
                return HttpService:PostAsync(
                    SCREENSHOT_SERVER .. "/screenshot",
                    HttpService:JSONEncode({
                        filename = screenshotName,
                        folder = "structures",
                    }),
                    Enum.HttpContentType.ApplicationJson
                )
            end)

            if screenshotSuccess then
                print(string.format("  [SCREENSHOT] %s.png", screenshotName))
            else
                print(string.format("  [SCREENSHOT FAIL] %s: %s", angle.name, tostring(screenshotResult)))
            end
        end
    end

    -- Store result
    table.insert(structureResults, {
        name = structureDef.name,
        status = "OK",
        partCount = partCount,
        meshPartCount = meshPartCount,
        hasColor = hasColor,
        colors = colors,
        size = size,
    })

    -- Move model out of the way for next structure
    model:PivotTo(CFrame.new(100, 0, 0))

    container:Destroy()
end

-- Summary
print("")
print("╔════════════════════════════════════════════════╗")
print("║     STRUCTURE ANALYSIS SUMMARY                 ║")
print("╚════════════════════════════════════════════════╝")

local eyePoppingCount = 0
local grayCount = 0

for _, result in ipairs(structureResults) do
    if result.status == "OK" then
        local status = result.hasColor and "EYE-POPPING" or "GRAY/DULL"
        if result.hasColor then
            eyePoppingCount = eyePoppingCount + 1
        else
            grayCount = grayCount + 1
        end
        print(string.format("  %s: %s (%d parts)", result.name, status, result.partCount))
    else
        print(string.format("  %s: %s", result.name, result.status))
        grayCount = grayCount + 1
    end
end

print("")
if grayCount > 0 then
    print(string.format("WARNING: %d structures are GRAY/DULL!", grayCount))
    print("The FBX models may not have proper materials/colors applied.")
else
    print("ALL STRUCTURES HAVE COLOR!")
end

if serverAvailable then
    print("")
    print("Screenshots saved to: tools/roblox-screenshot/screenshots/structures/")
end

print("")
print("=== Done ===")
