--!strict
--[[
	Luau Pattern Tests

	Validates that code doesn't use patterns that don't exist in Luau,
	such as .NET methods or other language-specific constructs.
	Also catches ambiguous syntax patterns that cause runtime errors.
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

	-- Ambiguous syntax: :Play()(element - looks like function call continuation
	-- This causes "Ambiguous syntax: this looks like an argument list for a function call"
	if string.find(content, ":Play%(%)%s*%(") then
		table.insert(errors, filename .. ": Has ambiguous syntax ':Play()(' - add semicolon before parenthesis")
	end

	-- Region3:FillRegion without ExpandToGrid - causes grid alignment errors
	-- Pattern: FillRegion(Region3.new(...), without :ExpandToGrid
	if string.find(content, "FillRegion%(Region3%.new") then
		table.insert(errors, filename .. ": FillRegion with inline Region3.new - use :ExpandToGrid(voxelSize) first")
	end

	-- REGRESSION: Direct .Touched access on non-BasePart (Models don't have Touched)
	-- Bug: StoryBeatProcessor tried collectible.Touched where collectible was a Model
	-- Pattern: parameter.Touched:Connect without checking if it's a BasePart first
	-- Look for function parameters that get .Touched directly without type guard
	local lines = content:split("\n")
	for i, line in lines do
		-- Check for direct .Touched access
		if string.find(line, "%.Touched:Connect") then
			-- Look back a few lines for the variable source
			local varMatch = string.match(line, "(%w+)%.Touched:Connect")
			if varMatch then
				-- Check if this looks like it could be a Model (function parameter, loop variable)
				-- Safe patterns: FindFirstChildWhichIsA("BasePart"), :IsA("BasePart"), explicit BasePart type
				local context = ""
				for j = math.max(1, i - 10), i do
					context = context .. (lines[j] or "") .. "\n"
				end

				-- Check if there's a type guard for this variable
				local hasSafePattern =
					string.find(context, varMatch .. ":IsA%(") or
					string.find(context, "FindFirstChildWhichIsA%(\"BasePart\"%)") or
					string.find(context, varMatch .. "%s*::%s*BasePart") or
					string.find(context, "local " .. varMatch .. "%s*=%s*[%w_]+:FindFirstChildWhichIsA") or
					-- Type annotation in function parameter: (varName: BasePart)
					string.find(context, varMatch .. ":%s*BasePart") or
					-- touchPart pattern (common safe variable name)
					varMatch == "touchPart"

				if not hasSafePattern then
					-- Check if it's a function parameter (most dangerous)
					local funcPattern = "function%s*[%w_:%.]*%s*%(" .. varMatch
					if string.find(context, funcPattern) or string.find(context, "local%s+" .. varMatch .. "%s*=%s*[%w_]+%s*$") then
						table.insert(errors, filename .. ":" .. i .. ": .Touched on '" .. varMatch .. "' without BasePart check - Models don't have Touched event")
					end
				end
			end
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
