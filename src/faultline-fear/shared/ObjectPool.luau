--!strict
--[[
	Faultline Fear: Object Pooling System

	Efficient object reuse to reduce garbage collection:
	- Pre-allocate objects at startup
	- Return objects to pool instead of destroying
	- Automatic expansion when pool runs empty
	- Category-based pooling (particles, NPCs, collectibles)

	Usage:
		local pool = ObjectPool.new("Collectible", createCollectible, 50)
		local item = pool:Get()
		-- use item...
		pool:Return(item)
]]

export type ObjectFactory<T> = () -> T
export type ObjectResetter<T> = (obj: T) -> ()

export type ObjectPool<T> = {
	name: string,
	available: { T },
	inUse: { [T]: boolean },
	factory: ObjectFactory<T>,
	resetter: ObjectResetter<T>?,
	maxSize: number,
	expandSize: number,

	Get: (self: ObjectPool<T>) -> T?,
	Return: (self: ObjectPool<T>, obj: T) -> boolean,
	Prewarm: (self: ObjectPool<T>, count: number) -> (),
	GetStats: (self: ObjectPool<T>) -> { available: number, inUse: number, total: number },
	Clear: (self: ObjectPool<T>) -> (),
}

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-- ==========================================
-- POOL CREATION
-- ==========================================

--[[
	Create a new object pool.

	@param name - Name for debugging
	@param factory - Function that creates new objects
	@param initialSize - Number of objects to pre-create
	@param maxSize - Maximum pool size (0 = unlimited)
	@param resetter - Optional function to reset objects when returned
]]
function ObjectPool.new<T>(
	name: string,
	factory: ObjectFactory<T>,
	initialSize: number?,
	maxSize: number?,
	resetter: ObjectResetter<T>?
): ObjectPool<T>
	local self = setmetatable({}, ObjectPool) :: any

	self.name = name
	self.factory = factory
	self.resetter = resetter
	self.maxSize = maxSize or 0
	self.expandSize = math.max(10, (initialSize or 20) // 4)
	self.available = {}
	self.inUse = {}

	-- Pre-warm the pool
	local size = initialSize or 20
	for _ = 1, size do
		local obj = factory()
		table.insert(self.available, obj)
	end

	print(string.format("[ObjectPool:%s] Created with %d objects", name, size))

	return self :: ObjectPool<T>
end

-- ==========================================
-- POOL OPERATIONS
-- ==========================================

--[[
	Get an object from the pool.
	Returns nil if pool is at max capacity and empty.
]]
function ObjectPool:Get()
	-- Try to get from available pool
	if #self.available > 0 then
		local obj = table.remove(self.available)
		self.inUse[obj] = true
		return obj
	end

	-- Pool empty - try to expand
	local currentTotal = 0
	for _ in pairs(self.inUse) do
		currentTotal += 1
	end
	currentTotal += #self.available

	if self.maxSize > 0 and currentTotal >= self.maxSize then
		warn(string.format("[ObjectPool:%s] At max capacity (%d)", self.name, self.maxSize))
		return nil
	end

	-- Create new object
	local obj = self.factory()
	self.inUse[obj] = true

	-- Expand pool for next time (create additional objects)
	local expandCount = math.min(self.expandSize, self.maxSize > 0 and (self.maxSize - currentTotal - 1) or self.expandSize)
	if expandCount > 0 then
		task.defer(function()
			for _ = 1, expandCount do
				local newObj = self.factory()
				table.insert(self.available, newObj)
			end
			print(string.format("[ObjectPool:%s] Expanded by %d objects", self.name, expandCount))
		end)
	end

	return obj
end

--[[
	Return an object to the pool.
	Returns false if object wasn't from this pool.
]]
function ObjectPool:Return(obj: any): boolean
	if not self.inUse[obj] then
		warn(string.format("[ObjectPool:%s] Attempted to return object not from this pool", self.name))
		return false
	end

	-- Reset the object if resetter provided
	if self.resetter then
		self.resetter(obj)
	end

	self.inUse[obj] = nil
	table.insert(self.available, obj)
	return true
end

--[[
	Pre-warm the pool with additional objects.
]]
function ObjectPool:Prewarm(count: number)
	local currentTotal = #self.available
	for _ in pairs(self.inUse) do
		currentTotal += 1
	end

	local toCreate = count
	if self.maxSize > 0 then
		toCreate = math.min(count, self.maxSize - currentTotal)
	end

	for _ = 1, toCreate do
		local obj = self.factory()
		table.insert(self.available, obj)
	end

	print(string.format("[ObjectPool:%s] Prewarmed with %d additional objects", self.name, toCreate))
end

--[[
	Get pool statistics.
]]
function ObjectPool:GetStats(): { available: number, inUse: number, total: number }
	local inUseCount = 0
	for _ in pairs(self.inUse) do
		inUseCount += 1
	end

	return {
		available = #self.available,
		inUse = inUseCount,
		total = #self.available + inUseCount,
	}
end

--[[
	Clear all objects from the pool.
	Objects in use are NOT destroyed - they become orphaned.
]]
function ObjectPool:Clear()
	-- Destroy available objects if they're Instances
	for _, obj in ipairs(self.available) do
		if typeof(obj) == "Instance" then
			(obj :: Instance):Destroy()
		end
	end

	self.available = {}
	-- Note: inUse objects are NOT cleared - they're still referenced elsewhere

	print(string.format("[ObjectPool:%s] Cleared", self.name))
end

-- ==========================================
-- GLOBAL POOLS
-- ==========================================

local GlobalPools: { [string]: ObjectPool<any> } = {}

--[[
	Get or create a global pool by name.
]]
function ObjectPool.GetPool<T>(name: string): ObjectPool<T>?
	return GlobalPools[name] :: ObjectPool<T>?
end

--[[
	Register a pool globally for shared access.
]]
function ObjectPool.RegisterPool<T>(name: string, pool: ObjectPool<T>)
	if GlobalPools[name] then
		warn(string.format("[ObjectPool] Pool '%s' already registered, replacing", name))
	end
	GlobalPools[name] = pool :: any
end

--[[
	Get stats for all global pools.
]]
function ObjectPool.GetAllStats(): { [string]: { available: number, inUse: number, total: number } }
	local stats = {}
	for name, pool in pairs(GlobalPools) do
		stats[name] = pool:GetStats()
	end
	return stats
end

return ObjectPool
