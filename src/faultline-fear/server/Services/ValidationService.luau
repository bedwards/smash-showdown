--!strict
--[[
	Faultline Fear: Validation Service

	Runs silent verification checks when the game loads.
	Reports any issues to the console and can display on-screen warnings.

	Checks:
	- All required services initialized
	- Heightmap generated correctly
	- Remote events exist
	- Workspace folders created
	- Config values valid
	- No critical errors

	Called automatically after all services initialize.
	Results logged to console and optionally shown to players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Config = Shared.Config
local Heightmap = Shared.Heightmap

local ValidationService = {}

-- Validation results
type ValidationResult = {
	name: string,
	passed: boolean,
	message: string,
	severity: "info" | "warning" | "error" | "critical",
}

local results: { ValidationResult } = {}
local hasRun: boolean = false

-- ==========================================
-- VALIDATION CHECKS
-- ==========================================

local function addResult(
	name: string,
	passed: boolean,
	message: string,
	severity: "info" | "warning" | "error" | "critical"
)
	table.insert(results, {
		name = name,
		passed = passed,
		message = message,
		severity = severity,
	})
end

local function checkHeightmap(): boolean
	local generated = Heightmap:IsGenerated()
	if not generated then
		addResult("Heightmap", false, "Heightmap not generated - terrain queries will fail", "critical")
		return false
	end

	-- Sample a few points
	local testPoints = {
		{ 0, 0 },
		{ 100, 100 },
		{ -500, 500 },
		{ 1000, 1500 },
	}

	local validPoints = 0
	for _, point in ipairs(testPoints) do
		local height = Heightmap:GetHeight(point[1], point[2])
		if height and height > -1000 and height < 1000 then
			validPoints += 1
		end
	end

	if validPoints < #testPoints then
		addResult(
			"Heightmap",
			false,
			string.format("Heightmap returning invalid heights (%d/%d valid)", validPoints, #testPoints),
			"error"
		)
		return false
	end

	addResult("Heightmap", true, "Heightmap generated and returning valid heights", "info")
	return true
end

local function checkRemotes(): boolean
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		addResult("Remotes", false, "Remotes folder not found in ReplicatedStorage", "critical")
		return false
	end

	local requiredRemotes = {
		"HungerUpdate",
		"EarthquakeEvent",
		"TimeUpdate",
		"ObjectiveUpdate",
		"StoryEvent",
		"DialogueEvent",
		"HeightmapReady",
	}

	local missing = {}
	for _, remoteName in ipairs(requiredRemotes) do
		if not remotes:FindFirstChild(remoteName) then
			table.insert(missing, remoteName)
		end
	end

	if #missing > 0 then
		addResult("Remotes", false, "Missing remotes: " .. table.concat(missing, ", "), "error")
		return false
	end

	local count = #remotes:GetChildren()
	addResult("Remotes", true, string.format("%d remote events registered", count), "info")
	return true
end

local function checkWorkspaceFolders(): boolean
	local expectedFolders = {
		"Terrain", -- May not exist if using Roblox terrain
		"Caves",
		"LiminalZones",
		"Signs",
		"Structures",
		"NPCs",
	}

	local found = 0
	local missing = {}

	for _, folderName in ipairs(expectedFolders) do
		if Workspace:FindFirstChild(folderName) then
			found += 1
		else
			table.insert(missing, folderName)
		end
	end

	-- Some folders are optional (created by services that may not have run yet)
	if found < 3 then
		addResult("Workspace", false, "Few service folders found. Missing: " .. table.concat(missing, ", "), "warning")
		return false
	end

	addResult("Workspace", true, string.format("%d/%d workspace folders created", found, #expectedFolders), "info")
	return true
end

local function checkConfig(): boolean
	-- Verify critical config values
	local issues = {}

	if not Config.WORLD_SIZE or Config.WORLD_SIZE < 100 then
		table.insert(issues, "WORLD_SIZE invalid")
	end

	if not Config.TERRAIN_SEED then
		table.insert(issues, "TERRAIN_SEED missing")
	end

	if not Config.ZONES then
		table.insert(issues, "ZONES missing")
	end

	if not Config.DAY_NIGHT then
		table.insert(issues, "DAY_NIGHT missing")
	end

	if #issues > 0 then
		addResult("Config", false, "Config issues: " .. table.concat(issues, ", "), "error")
		return false
	end

	addResult("Config", true, "Config values valid", "info")
	return true
end

local function checkSharedModules(): boolean
	local modules = {
		"Config",
		"Heightmap",
		"AssetManifest",
		"InputService",
		"StoryData",
	}

	local loaded = 0
	local failed = {}

	for _, moduleName in ipairs(modules) do
		local success = pcall(function()
			local _ = Shared[moduleName]
		end)
		if success and Shared[moduleName] then
			loaded += 1
		else
			table.insert(failed, moduleName)
		end
	end

	if #failed > 0 then
		addResult("SharedModules", false, "Failed to load: " .. table.concat(failed, ", "), "critical")
		return false
	end

	addResult("SharedModules", true, string.format("All %d shared modules loaded", loaded), "info")
	return true
end

local function checkPlayerSpawn(): boolean
	-- Check if there's a spawn location
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	if not spawn then
		addResult("Spawn", false, "No SpawnLocation found - players may spawn at invalid position", "warning")
		return false
	end

	addResult("Spawn", true, "SpawnLocation configured", "info")
	return true
end

-- ==========================================
-- REPORT GENERATION
-- ==========================================

local function generateReport(): string
	local lines = {
		"",
		"╔════════════════════════════════════════════════╗",
		"║       FAULTLINE FEAR VALIDATION REPORT         ║",
		"╚════════════════════════════════════════════════╝",
		"",
	}

	local passed = 0
	local warnings = 0
	local errors = 0
	local critical = 0

	for _, result in ipairs(results) do
		local icon = result.passed and "✓" or "✗"
		local severityTag = string.upper(result.severity)

		if result.passed then
			passed += 1
		elseif result.severity == "warning" then
			warnings += 1
		elseif result.severity == "error" then
			errors += 1
		elseif result.severity == "critical" then
			critical += 1
		end

		table.insert(lines, string.format("[%s] [%s] %s", icon, severityTag, result.name))
		table.insert(lines, string.format("    %s", result.message))
	end

	table.insert(lines, "")
	table.insert(
		lines,
		"────────────────────────────────────────────────"
	)
	table.insert(
		lines,
		string.format("Summary: %d passed, %d warnings, %d errors, %d critical", passed, warnings, errors, critical)
	)

	if critical > 0 then
		table.insert(lines, "")
		table.insert(lines, "⚠️  CRITICAL ISSUES DETECTED - Game may not function correctly!")
	elseif errors > 0 then
		table.insert(lines, "")
		table.insert(lines, "⚠️  Errors detected - Some features may not work")
	elseif warnings > 0 then
		table.insert(lines, "")
		table.insert(lines, "ℹ️  Warnings detected - Review recommended")
	else
		table.insert(lines, "")
		table.insert(lines, "✅ All validation checks passed!")
	end

	table.insert(
		lines,
		"────────────────────────────────────────────────"
	)
	table.insert(lines, "")

	return table.concat(lines, "\n")
end

-- ==========================================
-- PUBLIC API
-- ==========================================

function ValidationService:RunValidation(): { ValidationResult }
	if hasRun then
		return results
	end

	print("[ValidationService] Running validation checks...")

	results = {}

	-- Run all checks
	checkSharedModules()
	checkConfig()
	checkHeightmap()
	checkRemotes()
	checkWorkspaceFolders()
	checkPlayerSpawn()

	hasRun = true

	-- Print report
	print(generateReport())

	return results
end

function ValidationService:GetResults(): { ValidationResult }
	return results
end

function ValidationService:HasCriticalErrors(): boolean
	for _, result in ipairs(results) do
		if not result.passed and result.severity == "critical" then
			return true
		end
	end
	return false
end

function ValidationService:HasErrors(): boolean
	for _, result in ipairs(results) do
		if not result.passed and (result.severity == "error" or result.severity == "critical") then
			return true
		end
	end
	return false
end

function ValidationService:ShowValidationToPlayer(player: Player)
	-- Only show if there are errors
	if not self:HasErrors() then
		return
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	-- Create warning UI
	local gui = Instance.new("ScreenGui")
	gui.Name = "ValidationWarning"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.8, 0, 0, 150)
	frame.Position = UDim2.new(0.1, 0, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 100, 100)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Text = "⚠️ VALIDATION ERRORS DETECTED"
	title.Parent = frame

	local errorCount = 0
	for _, result in ipairs(results) do
		if not result.passed then
			errorCount += 1
		end
	end

	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -20, 1, -60)
	message.Position = UDim2.new(0, 10, 0, 35)
	message.BackgroundTransparency = 1
	message.TextColor3 = Color3.fromRGB(255, 200, 200)
	message.Font = Enum.Font.Gotham
	message.TextSize = 14
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top

	local errorMessages = {}
	for _, result in ipairs(results) do
		if not result.passed then
			table.insert(errorMessages, string.format("• %s: %s", result.name, result.message))
		end
	end
	message.Text = table.concat(errorMessages, "\n")
	message.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 100, 0, 25)
	closeBtn.Position = UDim2.new(1, -110, 1, -30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Text = "Dismiss"
	closeBtn.Parent = frame

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	gui.Parent = playerGui

	-- Auto-dismiss after 30 seconds
	task.delay(30, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

function ValidationService:Initialize()
	-- Run validation after a brief delay to let services initialize
	task.delay(1, function()
		self:RunValidation()

		-- Show to all current players if errors
		if self:HasErrors() then
			for _, player in Players:GetPlayers() do
				self:ShowValidationToPlayer(player)
			end
		end
	end)

	-- Show to new players
	Players.PlayerAdded:Connect(function(player)
		if self:HasErrors() then
			player.CharacterAdded:Once(function()
				task.wait(2)
				self:ShowValidationToPlayer(player)
			end)
		end
	end)

	print("[ValidationService] Initialized - validation will run shortly")
end

return ValidationService
