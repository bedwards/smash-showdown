--[[
	Cloud Asset Loading Tests

	Tests for cloud asset ID definitions and fallback loading in AssetManifest.
]]

local fs = require("@lune/fs")

local tests = {}

-- Read AssetManifest
local manifestPath = "src/faultline-fear/shared/AssetManifest.luau"
local manifestContent = fs.readFile(manifestPath)

tests["AssetManifest has cloudAssetId in type definition"] = function()
	assert(manifestContent:find("cloudAssetId: number%?"), "AssetEntry type should include optional cloudAssetId")
end

tests["FerrisWheel has cloudAssetId"] = function()
	local section = manifestContent:match("FerrisWheel = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "FerrisWheel should have a cloudAssetId")
end

tests["RadioTower has cloudAssetId"] = function()
	local section = manifestContent:match("RadioTower = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "RadioTower should have a cloudAssetId")
end

tests["AbandonedHouse has cloudAssetId"] = function()
	local section = manifestContent:match("AbandonedHouse = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "AbandonedHouse should have a cloudAssetId")
end

tests["Bridge has cloudAssetId"] = function()
	local section = manifestContent:match("Bridge = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "Bridge should have a cloudAssetId")
end

tests["WaterTower has cloudAssetId"] = function()
	local section = manifestContent:match("WaterTower = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "WaterTower should have a cloudAssetId")
end

tests["Lighthouse has cloudAssetId"] = function()
	local section = manifestContent:match("Lighthouse = %{(.-)%}")
	assert(section and section:find("cloudAssetId = %d+"), "Lighthouse should have a cloudAssetId")
end

tests["AssetManifest requires InsertService"] = function()
	assert(manifestContent:find('InsertService'), "AssetManifest should require InsertService for cloud loading")
end

tests["loadFromCloud function exists"] = function()
	assert(manifestContent:find("loadFromCloud"), "loadFromCloud function should exist for cloud asset loading")
end

tests["loadFromCloud uses InsertService:LoadAsset"] = function()
	assert(manifestContent:find("InsertService:LoadAsset"), "loadFromCloud should use InsertService:LoadAsset")
end

tests["cloudAssetCache exists for caching"] = function()
	assert(manifestContent:find("cloudAssetCache"), "cloudAssetCache should exist to cache loaded cloud assets")
end

tests["isTemplateEmpty function exists"] = function()
	assert(manifestContent:find("isTemplateEmpty"), "isTemplateEmpty should check for empty templates")
end

tests["GetAsset tries cloud loading as fallback"] = function()
	-- GetAsset should check cloudAssetId when local template not found
	-- Just check that the function references cloudAssetId and loadFromCloud
	assert(manifestContent:find("entry.cloudAssetId"), "GetAsset should check entry.cloudAssetId for fallback loading")
	assert(manifestContent:find("loadFromCloud%(entry.cloudAssetId, fullName, entry.name%)"), "GetAsset should call loadFromCloud with cloudAssetId, fullName, and entry.name")
end

tests["AssetManifest requires AssetColors"] = function()
	assert(manifestContent:find("AssetColors = require"), "AssetManifest should require AssetColors module")
end

tests["loadFromCloud applies colors"] = function()
	assert(manifestContent:find("AssetColors:ApplyColors%(model, assetName%)"), "loadFromCloud should call AssetColors:ApplyColors")
end

return tests
