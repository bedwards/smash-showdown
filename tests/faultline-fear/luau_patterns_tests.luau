--!strict
--[[
	Luau Pattern Tests

	Validates that code doesn't use patterns that don't exist in Luau,
	such as .NET methods or other language-specific constructs.
]]

local fs = require("@lune/fs")

local function scanDirectory(path: string): { string }
	local files = {}
	local entries = fs.readDir(path)

	for _, entry in entries do
		local fullPath = path .. "/" .. entry
		if fs.isDir(fullPath) then
			for _, file in scanDirectory(fullPath) do
				table.insert(files, file)
			end
		elseif entry:match("%.luau$") then
			table.insert(files, fullPath)
		end
	end

	return files
end

local function findBadPatterns(content: string, filename: string): { string }
	local errors = {}

	-- .NET methods that don't exist in Luau
	local dotnetPatterns = {
		":GetHashCode%(",
		":ToString%(",  -- Luau uses tostring()
		":Equals%(",
		":GetType%(",
		"%.Length[^%w]",  -- Should be #table or string.len()
	}

	for _, pattern in dotnetPatterns do
		if string.find(content, pattern) then
			table.insert(errors, filename .. ": Uses .NET pattern '" .. pattern .. "' - not valid in Luau")
		end
	end

	return errors
end

local tests = {}

function tests.no_dotnet_methods_in_server()
	local allErrors = {}
	local files = scanDirectory("src/faultline-fear/server")

	for _, file in files do
		local content = fs.readFile(file)
		for _, err in findBadPatterns(content, file) do
			table.insert(allErrors, err)
		end
	end

	assert(#allErrors == 0, "Found .NET patterns in server code:\n" .. table.concat(allErrors, "\n"))
end

function tests.no_dotnet_methods_in_client()
	local allErrors = {}
	local files = scanDirectory("src/faultline-fear/client")

	for _, file in files do
		local content = fs.readFile(file)
		for _, err in findBadPatterns(content, file) do
			table.insert(allErrors, err)
		end
	end

	assert(#allErrors == 0, "Found .NET patterns in client code:\n" .. table.concat(allErrors, "\n"))
end

function tests.no_dotnet_methods_in_shared()
	local allErrors = {}
	local files = scanDirectory("src/faultline-fear/shared")

	for _, file in files do
		local content = fs.readFile(file)
		for _, err in findBadPatterns(content, file) do
			table.insert(allErrors, err)
		end
	end

	assert(#allErrors == 0, "Found .NET patterns in shared code:\n" .. table.concat(allErrors, "\n"))
end

return tests
