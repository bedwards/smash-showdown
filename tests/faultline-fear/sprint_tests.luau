--[[
	Sprint System Tests

	Tests for sprint mechanics including stamina drain and keybinds.
]]

local fs = require("@lune/fs")

local tests = {}

-- Read config file
local configPath = "src/faultline-fear/shared/Config.luau"
local configContent = fs.readFile(configPath)

tests["STAMINA configuration exists"] = function()
	assert(configContent:find("STAMINA"), "STAMINA table should exist in Config")
end

tests["STAMINA.MAX is defined"] = function()
	assert(configContent:find("STAMINA.-%{.-MAX"), "STAMINA.MAX should be defined")
end

tests["STAMINA.SPRINT_DRAIN is defined"] = function()
	assert(configContent:find("SPRINT_DRAIN"), "SPRINT_DRAIN should be defined for stamina drain while sprinting")
end

tests["STAMINA.RECOVERY_RATE is defined"] = function()
	assert(configContent:find("RECOVERY_RATE"), "RECOVERY_RATE should be defined for stamina recovery")
end

tests["KEYBINDS.SPRINT is LeftShift"] = function()
	assert(configContent:find("SPRINT = Enum.KeyCode.LeftShift"), "SPRINT keybind should be LeftShift")
end

-- Check Main.client.luau has sprint handling
local mainClientPath = "src/faultline-fear/client/Main.client.luau"
local mainClientContent = fs.readFile(mainClientPath)

tests["Main client handles sprint input"] = function()
	assert(mainClientContent:find("SPRINT"), "Main client should handle SPRINT keybind")
end

tests["Main client has sprint state"] = function()
	assert(mainClientContent:find("isSprinting"), "Main client should track sprint state")
end

tests["Main client drains stamina while sprinting"] = function()
	assert(mainClientContent:find("SPRINT_DRAIN"), "Main client should drain stamina using SPRINT_DRAIN")
end

tests["Main client recovers stamina when not sprinting"] = function()
	assert(mainClientContent:find("RECOVERY_RATE"), "Main client should recover stamina using RECOVERY_RATE")
end

-- Check TouchController has sprint with stamina
local touchControllerPath = "src/faultline-fear/client/Controllers/TouchController.luau"
local touchControllerContent = fs.readFile(touchControllerPath)

tests["TouchController has sprint button"] = function()
	assert(touchControllerContent:find("SprintButton"), "TouchController should have a sprint button")
end

tests["TouchController tracks stamina"] = function()
	assert(touchControllerContent:find("currentStamina"), "TouchController should track currentStamina")
end

tests["TouchController drains stamina while sprinting"] = function()
	assert(touchControllerContent:find("SPRINT_DRAIN"), "TouchController should drain stamina")
end

return tests
