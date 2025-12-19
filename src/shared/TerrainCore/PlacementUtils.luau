--!strict
--[[
	TerrainCore: Placement Utilities

	Shared placement logic for positioning structures on terrain.
	Used by both Faultline Fear and Fault-Lite to ensure consistent placement.

	IMPORTANT: This is the SINGLE SOURCE OF TRUTH for structure placement.
	Both games MUST use these functions - no duplicate placement logic!

	Exports:
		PlacementUtils.placeOnGround(model, x, z, heightmap) -> CFrame, number
		PlacementUtils.getDropPosition(model, x, z, heightmap, dropHeight) -> CFrame
		PlacementUtils.getModelBottomOffset(model) -> number
		PlacementUtils.anchorModel(model, anchored)
		PlacementUtils.cloneForDrop(model) -> Model
]]

local PlacementUtils = {}

export type PlacementResult = {
	cframe: CFrame,
	terrainHeight: number,
	modelHeight: number,
}

--[[
	Gets the vertical offset from model origin to bottom of model.
	This is how far below the model's pivot the lowest point is.
]]
function PlacementUtils.getModelBottomOffset(model: Model): number
	local minY = math.huge
	local pivotY = model:GetPivot().Position.Y

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partBottom = part.Position.Y - part.Size.Y / 2
			minY = math.min(minY, partBottom)
		end
	end

	if minY == math.huge then
		return 0
	end

	-- Offset = how far below pivot the bottom is
	return pivotY - minY
end

--[[
	Gets the total height of the model's bounding box.
]]
function PlacementUtils.getModelHeight(model: Model): number
	local minY = math.huge
	local maxY = -math.huge

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partBottom = part.Position.Y - part.Size.Y / 2
			local partTop = part.Position.Y + part.Size.Y / 2
			minY = math.min(minY, partBottom)
			maxY = math.max(maxY, partTop)
		end
	end

	if minY == math.huge then
		return 0
	end

	return maxY - minY
end

--[[
	Sets all parts in a model to anchored or unanchored.
]]
function PlacementUtils.anchorModel(model: Model, anchored: boolean)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = anchored
		end
	end
end

--[[
	Ensures model has a PrimaryPart set.
	Returns the PrimaryPart.
]]
function PlacementUtils.ensurePrimaryPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			model.PrimaryPart = part
			return part
		end
	end

	return nil
end

--[[
	Calculates the CFrame to place a model perfectly on the ground.
	The model's bottom will be exactly at terrain height.

	@param model The model to place
	@param x World X coordinate
	@param z World Z coordinate
	@param heightmap The heightmap module (must have :GetHeight method)
	@return PlacementResult with cframe, terrainHeight, and modelHeight
]]
function PlacementUtils.getGroundPlacement(model: Model, x: number, z: number, heightmap: any): PlacementResult
	local terrainHeight = heightmap:GetHeight(x, z)
	local bottomOffset = PlacementUtils.getModelBottomOffset(model)
	local modelHeight = PlacementUtils.getModelHeight(model)

	-- Place pivot so that bottom of model sits on terrain
	local finalY = terrainHeight + bottomOffset

	return {
		cframe = CFrame.new(x, finalY, z),
		terrainHeight = terrainHeight,
		modelHeight = modelHeight,
	}
end

--[[
	Calculates the CFrame to drop a model from above.
	Used for physics drop testing.

	@param model The model to drop
	@param x World X coordinate
	@param z World Z coordinate
	@param heightmap The heightmap module
	@param dropHeight How far above terrain to start (default 20 studs)
	@return CFrame for the drop position
]]
function PlacementUtils.getDropPlacement(model: Model, x: number, z: number, heightmap: any, dropHeight: number?): PlacementResult
	local terrainHeight = heightmap:GetHeight(x, z)
	local bottomOffset = PlacementUtils.getModelBottomOffset(model)
	local modelHeight = PlacementUtils.getModelHeight(model)
	local height = dropHeight or 20

	-- Place so bottom is `height` studs above terrain
	local finalY = terrainHeight + bottomOffset + height

	return {
		cframe = CFrame.new(x, finalY, z),
		terrainHeight = terrainHeight,
		modelHeight = modelHeight,
	}
end

--[[
	Places a model perfectly on the ground (anchored).
	Modifies the model in place.

	@param model The model to place
	@param x World X coordinate
	@param z World Z coordinate
	@param heightmap The heightmap module
]]
function PlacementUtils.placeOnGround(model: Model, x: number, z: number, heightmap: any)
	PlacementUtils.ensurePrimaryPart(model)
	PlacementUtils.anchorModel(model, true)

	local result = PlacementUtils.getGroundPlacement(model, x, z, heightmap)
	model:PivotTo(result.cframe)

	return result
end

--[[
	Places a model for dropping (unanchored, above ground).
	Modifies the model in place.

	@param model The model to place
	@param x World X coordinate
	@param z World Z coordinate
	@param heightmap The heightmap module
	@param dropHeight How far above terrain to start
]]
function PlacementUtils.placeForDrop(model: Model, x: number, z: number, heightmap: any, dropHeight: number?)
	PlacementUtils.ensurePrimaryPart(model)
	PlacementUtils.anchorModel(model, false)

	local result = PlacementUtils.getDropPlacement(model, x, z, heightmap, dropHeight)
	model:PivotTo(result.cframe)

	return result
end

--[[
	Clones a model for physics drop testing.
	Returns a deep clone with appropriate naming.
]]
function PlacementUtils.cloneForDrop(model: Model): Model
	local clone = model:Clone()
	clone.Name = model.Name .. "_Drop"
	return clone
end

return PlacementUtils
