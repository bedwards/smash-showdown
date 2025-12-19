--!strict
--[[
	Shared Exports Tests

	Regression tests to verify shared modules export expected entities.
	Prevents breakage like: "attempt to index nil with 'StructureEntity'"
]]

local fs = require("@lune/fs")

local function readFile(path: string): string
	return fs.readFile(path)
end

local function fileContains(path: string, pattern: string): boolean
	local content = readFile(path)
	return string.find(content, pattern, 1, true) ~= nil
end

local function fileContainsPattern(path: string, pattern: string): boolean
	local content = readFile(path)
	return string.find(content, pattern) ~= nil
end

local tests = {}

-- ==========================================
-- TerrainCore exports
-- ==========================================

function tests.TerrainCore_exports_Config()
	assert(
		fileContains("src/shared/TerrainCore/init.luau", "TerrainCore.Config = require(script.TerrainConfig)"),
		"TerrainCore must export Config"
	)
end

function tests.TerrainCore_exports_Heightmap()
	assert(
		fileContains("src/shared/TerrainCore/init.luau", "TerrainCore.Heightmap = require(script.Heightmap)"),
		"TerrainCore must export Heightmap"
	)
end

function tests.TerrainCore_exports_PlacementUtils()
	assert(
		fileContains("src/shared/TerrainCore/init.luau", "TerrainCore.PlacementUtils = require(script.PlacementUtils)"),
		"TerrainCore must export PlacementUtils"
	)
end

function tests.TerrainCore_exports_StructureEntity()
	assert(
		fileContains("src/shared/TerrainCore/init.luau", "TerrainCore.StructureEntity = require(script.StructureEntity)"),
		"TerrainCore must export StructureEntity"
	)
end

-- ==========================================
-- Fault-Lite Shared exports
-- ==========================================

function tests.FaultLite_Shared_exports_TerrainCore()
	assert(
		fileContains("src/fault-lite/shared/init.luau", "Shared.TerrainCore = TerrainCore"),
		"Fault-Lite Shared must export TerrainCore for Shared.TerrainCore.StructureEntity access"
	)
end

function tests.FaultLite_Shared_exports_TerrainConfig()
	assert(
		fileContains("src/fault-lite/shared/init.luau", "Shared.TerrainConfig = TerrainCore.Config"),
		"Fault-Lite Shared must export TerrainConfig"
	)
end

function tests.FaultLite_Shared_exports_Heightmap()
	assert(
		fileContains("src/fault-lite/shared/init.luau", "Shared.Heightmap = TerrainCore.Heightmap"),
		"Fault-Lite Shared must export Heightmap"
	)
end

-- ==========================================
-- StructureEntity module structure
-- ==========================================

function tests.StructureEntity_has_new_constructor()
	assert(
		fileContainsPattern("src/shared/TerrainCore/StructureEntity.luau", "function StructureEntity%.new"),
		"StructureEntity must have new() constructor"
	)
end

function tests.StructureEntity_has_spawn_method()
	assert(
		fileContainsPattern("src/shared/TerrainCore/StructureEntity.luau", "function StructureEntity:spawn"),
		"StructureEntity must have spawn() method"
	)
end

function tests.StructureEntity_has_isValidAsset_method()
	assert(
		fileContainsPattern("src/shared/TerrainCore/StructureEntity.luau", "function StructureEntity%.isValidAsset"),
		"StructureEntity must have isValidAsset() method"
	)
end

function tests.StructureEntity_has_getAvailableAssets_method()
	assert(
		fileContainsPattern("src/shared/TerrainCore/StructureEntity.luau", "function StructureEntity%.getAvailableAssets"),
		"StructureEntity must have getAvailableAssets() method"
	)
end

-- ==========================================
-- TerrainConfig structure requirements
-- ==========================================

function tests.TerrainConfig_has_STRUCTURES_table()
	assert(
		fileContainsPattern("src/shared/TerrainCore/TerrainConfig.luau", "STRUCTURES%s*="),
		"TerrainConfig must have STRUCTURES table"
	)
end

function tests.TerrainConfig_has_EARTHQUAKE_table()
	assert(
		fileContainsPattern("src/shared/TerrainCore/TerrainConfig.luau", "EARTHQUAKE%s*="),
		"TerrainConfig must have EARTHQUAKE table"
	)
end

function tests.TerrainConfig_has_GetStructureConfig_function()
	assert(
		fileContainsPattern("src/shared/TerrainCore/TerrainConfig.luau", "function TerrainConfig%.GetStructureConfig"),
		"TerrainConfig must have GetStructureConfig() function"
	)
end

-- ==========================================
-- Cross-reference: Consumers use shared entities
-- ==========================================

function tests.FaultLite_Main_uses_StructureEntity()
	assert(
		fileContainsPattern("src/fault-lite/server/Main.server.luau", "StructureEntity%.new"),
		"Fault-Lite Main must use StructureEntity.new()"
	)
end

function tests.FaultlineFear_StructureSpawner_uses_StructureEntity()
	assert(
		fileContainsPattern("src/faultline-fear/server/Services/StructureSpawner.luau", "StructureEntity%.new"),
		"Faultline Fear StructureSpawner must use StructureEntity.new()"
	)
end

-- ==========================================
-- Regression tests for specific bugs
-- ==========================================

function tests.StructureEntity_unparents_before_destroying_container()
	-- Bug: Model was destroyed along with InsertService container
	-- Fix: Must set model.Parent = nil before result:Destroy()
	local content = readFile("src/shared/TerrainCore/StructureEntity.luau")

	-- Find the section where we extract from container and destroy it
	local hasUnparent = string.find(content, "model%.Parent = nil") ~= nil
	local hasDestroy = string.find(content, "result:Destroy%(%)") ~= nil

	assert(hasUnparent, "StructureEntity must unparent model before destroying container")
	assert(hasDestroy, "StructureEntity must destroy the InsertService container")

	-- Verify unparent comes BEFORE destroy
	local unparentPos = string.find(content, "model%.Parent = nil")
	local destroyPos = string.find(content, "result:Destroy%(%)")
	assert(
		unparentPos and destroyPos and unparentPos < destroyPos,
		"StructureEntity must unparent model BEFORE destroying container (fixes locked Parent bug)"
	)
end

return tests
