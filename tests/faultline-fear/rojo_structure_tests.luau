--!strict
--[[
	Rojo Structure Tests

	Validates that scripts use correct Rojo paths.
	In Rojo, sibling folders are accessed via script.Parent, not script.
]]

local fs = require("@lune/fs")

local function readFile(path: string): string
	return fs.readFile(path)
end

local function findBadPatterns(content: string, filename: string): { string }
	local errors = {}

	-- Check for script.Services. (should be script.Parent.Services.)
	if string.find(content, "script%.Services%.") then
		table.insert(errors, filename .. ": Uses 'script.Services.' - should be 'script.Parent.Services.'")
	end

	-- Check for script.Controllers. (should be script.Parent.Controllers.)
	if string.find(content, "script%.Controllers%.") then
		table.insert(errors, filename .. ": Uses 'script.Controllers.' - should be 'script.Parent.Controllers.'")
	end

	return errors
end

local tests = {}

function tests.server_main_uses_correct_paths()
	local content = readFile("src/faultline-fear/server/Main.server.luau")
	local errors = findBadPatterns(content, "Main.server.luau")

	assert(#errors == 0, "Server Main has incorrect Rojo paths:\n" .. table.concat(errors, "\n"))
end

function tests.client_main_uses_correct_paths()
	local content = readFile("src/faultline-fear/client/Main.client.luau")
	local errors = findBadPatterns(content, "Main.client.luau")

	assert(#errors == 0, "Client Main has incorrect Rojo paths:\n" .. table.concat(errors, "\n"))
end

function tests.no_hardcoded_script_children()
	-- Scan all server and client scripts for incorrect patterns
	local allErrors = {}

	local serverMain = readFile("src/faultline-fear/server/Main.server.luau")
	for _, err in findBadPatterns(serverMain, "server/Main.server.luau") do
		table.insert(allErrors, err)
	end

	local clientMain = readFile("src/faultline-fear/client/Main.client.luau")
	for _, err in findBadPatterns(clientMain, "client/Main.client.luau") do
		table.insert(allErrors, err)
	end

	assert(#allErrors == 0, "Found incorrect Rojo path patterns:\n" .. table.concat(allErrors, "\n"))
end

return tests
