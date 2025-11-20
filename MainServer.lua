-- ServerScriptService > MainServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create remote events folder FIRST (before anything else)
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

local StartMiningEvent = Instance.new("RemoteEvent")
StartMiningEvent.Name = "StartMining"
StartMiningEvent.Parent = RemoteEvents

local StopMiningEvent = Instance.new("RemoteEvent")
StopMiningEvent.Name = "StopMining"
StopMiningEvent.Parent = RemoteEvents

local UpdateInventoryEvent = Instance.new("RemoteEvent")
UpdateInventoryEvent.Name = "UpdateInventory"
UpdateInventoryEvent.Parent = RemoteEvents

local LoadingProgressEvent = Instance.new("RemoteEvent")
LoadingProgressEvent.Name = "LoadingProgress"
LoadingProgressEvent.Parent = RemoteEvents

-- Configuration
local BLOCK_SIZE = 6
local WORLD_WIDTH = 40 -- blocks wide (40x40 = 1600 per layer)
local WORLD_DEPTH = 100 -- blocks deep (1600 * 100 = 160,000 total blocks)
local SPAWN_HEIGHT = 20 -- studs above ground

-- Generation flag
local terrainGenerated = false

-- Material types with properties
local MATERIALS = {
	Dirt = {
		Depth = {0, 15},
		Color = Color3.fromRGB(139, 90, 43),
		Health = 100,
		DropAmount = 1,
		MinTime = 0.5
	},
	Stone = {
		Depth = {15, 40},
		Color = Color3.fromRGB(163, 162, 165),
		Health = 200,
		DropAmount = 1,
		MinTime = 1.0
	},
	IronOre = {
		Depth = {25, 60},
		Color = Color3.fromRGB(226, 155, 64),
		Health = 300,
		DropAmount = 2,
		MinTime = 1.5,
		Rarity = 0.15 -- 15% chance in range
	},
	DeepStone = {
		Depth = {40, 70},
		Color = Color3.fromRGB(99, 95, 98),
		Health = 400,
		DropAmount = 2,
		MinTime = 2.0
	},
	GoldOre = {
		Depth = {50, 80},
		Color = Color3.fromRGB(255, 215, 0),
		Health = 500,
		DropAmount = 3,
		MinTime = 2.5,
		Rarity = 0.1 -- 10% chance in range
	},
	Diamond = {
		Depth = {80, 100}, -- Deep at bottom of world
		Color = Color3.fromRGB(0, 191, 255),
		Health = 800,
		DropAmount = 5,
		MinTime = 3.0,
		Rarity = 0.05 -- 5% chance in range
	}
}

-- Create folders for organization
local TerrainFolder = Instance.new("Folder")
TerrainFolder.Name = "Terrain"
TerrainFolder.Parent = workspace

-- Create spawn location directly on terrain
local function createSpawn()
	local spawn = Instance.new("SpawnLocation")
	spawn.Position = Vector3.new((WORLD_WIDTH * BLOCK_SIZE) / 2, BLOCK_SIZE + 5, (WORLD_WIDTH * BLOCK_SIZE) / 2)
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.BrickColor = BrickColor.new("Bright green")
	spawn.Parent = workspace
end

-- Determine material type based on depth
local function getMaterialAtDepth(depth, x, z)
	-- Check for rare ores first
	if depth >= MATERIALS.Diamond.Depth[1] and depth <= MATERIALS.Diamond.Depth[2] then
		if math.random() < MATERIALS.Diamond.Rarity then
			return "Diamond"
		end
	end

	if depth >= MATERIALS.GoldOre.Depth[1] and depth <= MATERIALS.GoldOre.Depth[2] then
		if math.random() < MATERIALS.GoldOre.Rarity then
			return "GoldOre"
		end
	end

	if depth >= MATERIALS.IronOre.Depth[1] and depth <= MATERIALS.IronOre.Depth[2] then
		if math.random() < MATERIALS.IronOre.Rarity then
			return "IronOre"
		end
	end

	-- Base materials by depth
	if depth <= MATERIALS.Dirt.Depth[2] then
		return "Dirt"
	elseif depth <= MATERIALS.Stone.Depth[2] then
		return "Stone"
	else
		return "DeepStone"
	end
end

-- Generate underground terrain in chunks to avoid lag
local function generateTerrain()
	print("Starting terrain generation...")

	local blocksPerBatch = 2000 -- Generate 2000 blocks between yields (faster!)
	local totalBlocks = WORLD_WIDTH * WORLD_WIDTH * WORLD_DEPTH
	local blocksGenerated = 0
	local lastHeartbeat = tick()

	for x = 0, WORLD_WIDTH - 1 do
		for z = 0, WORLD_WIDTH - 1 do
			for y = 0, WORLD_DEPTH - 1 do
				local materialType = getMaterialAtDepth(y, x, z)
				local materialData = MATERIALS[materialType]

				-- Create block more efficiently
				local block = Instance.new("Part")
				block.Name = materialType
				block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
				block.Position = Vector3.new(
					x * BLOCK_SIZE + BLOCK_SIZE/2,
					-y * BLOCK_SIZE - BLOCK_SIZE/2,
					z * BLOCK_SIZE + BLOCK_SIZE/2
				)
				block.Anchored = true
				block.Color = materialData.Color
				block.Material = Enum.Material.Slate
				block.TopSurface = Enum.SurfaceType.Smooth
				block.BottomSurface = Enum.SurfaceType.Smooth

				-- Store block data (create all values before parenting for better performance)
				local healthValue = Instance.new("IntValue")
				healthValue.Name = "Health"
				healthValue.Value = materialData.Health

				local maxHealthValue = Instance.new("IntValue")
				maxHealthValue.Name = "MaxHealth"
				maxHealthValue.Value = materialData.Health

				local materialTypeValue = Instance.new("StringValue")
				materialTypeValue.Name = "MaterialType"
				materialTypeValue.Value = materialType

				local xValue = Instance.new("IntValue")
				xValue.Name = "GridX"
				xValue.Value = x

				local yValue = Instance.new("IntValue")
				yValue.Name = "GridY"
				yValue.Value = y

				local zValue = Instance.new("IntValue")
				zValue.Name = "GridZ"
				zValue.Value = z

				-- Parent all at once
				healthValue.Parent = block
				maxHealthValue.Parent = block
				materialTypeValue.Parent = block
				xValue.Parent = block
				yValue.Parent = block
				zValue.Parent = block

				block.Parent = TerrainFolder

				blocksGenerated = blocksGenerated + 1

				-- Yield every batch to prevent lag, or if too much time passed
				if blocksGenerated % blocksPerBatch == 0 or (tick() - lastHeartbeat) > 0.5 then
					local progress = (blocksGenerated / totalBlocks) * 100
					print("Sending progress update:", progress .. "%")
					LoadingProgressEvent:FireAllClients(progress)
					task.wait() -- Yield to prevent freezing
					lastHeartbeat = tick()
				end
			end
		end
	end

	-- Send 100% completion
	print("Sending 100% completion!")
	LoadingProgressEvent:FireAllClients(100)
	terrainGenerated = true
	print("Terrain generation complete!")
end

-- Mining system
local MiningPlayers = {}

local function setupPlayerMining(player)
	MiningPlayers[player.UserId] = {
		CurrentBlock = nil,
		MiningStartTime = 0,
		Tool = nil
	}
end

local function cleanupPlayerMining(player)
	MiningPlayers[player.UserId] = nil
end

-- Handle mining start
StartMiningEvent.OnServerEvent:Connect(function(player, block, tool)
	if not block or not block:IsDescendantOf(TerrainFolder) then return end
	if not tool or not tool:FindFirstChild("MiningPower") then return end

	local playerData = MiningPlayers[player.UserId]
	if not playerData then return end

	-- Check if already mining this block
	if playerData.CurrentBlock == block then return end

	playerData.CurrentBlock = block
	playerData.MiningStartTime = tick()
	playerData.Tool = tool

	local materialType = block:FindFirstChild("MaterialType")
	if not materialType then return end

	local materialData = MATERIALS[materialType.Value]
	local miningPower = tool.MiningPower.Value

	-- Damage per second = miningPower * 100
	local damagePerSecond = miningPower * 100

	-- Continuously damage block while mining
	task.spawn(function()
		while playerData.CurrentBlock == block and block.Parent do
			local health = block:FindFirstChild("Health")
			if not health then break end

			-- Deal damage based on time elapsed
			local deltaTime = 0.1 -- Update every 0.1 seconds
			local damage = damagePerSecond * deltaTime

			health.Value = math.max(0, health.Value - damage)

			-- Check if block is destroyed
			if health.Value <= 0 then
				-- Mark block as mined in save system
				local gridX = block:FindFirstChild("GridX")
				local gridY = block:FindFirstChild("GridY")
				local gridZ = block:FindFirstChild("GridZ")

				if gridX and gridY and gridZ and _G.MarkBlockMined then
					_G.MarkBlockMined(gridX.Value, gridY.Value, gridZ.Value)
				end

				-- Give resources
				local inventory = player:FindFirstChild("Inventory")
				if inventory then
					local resourceValue = inventory:FindFirstChild(materialType.Value)
					if resourceValue then
						resourceValue.Value = resourceValue.Value + materialData.DropAmount
					end
				end

				-- Update client inventory
				UpdateInventoryEvent:FireClient(player)

				-- Destroy block
				block:Destroy()

				-- Clear mining state
				playerData.CurrentBlock = nil
				break
			end

			task.wait(deltaTime)
		end
	end)
end)

-- Handle mining stop
StopMiningEvent.OnServerEvent:Connect(function(player)
	local playerData = MiningPlayers[player.UserId]
	if playerData then
		playerData.CurrentBlock = nil
		playerData.MiningStartTime = 0
	end
end)

-- Setup player inventory
local function setupPlayerInventory(player)
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- Create value objects for each resource
	for materialType, _ in pairs(MATERIALS) do
		local value = Instance.new("IntValue")
		value.Name = materialType
		value.Value = 0
		value.Parent = inventory
	end

	-- Starting resources
	inventory.Dirt.Value = 10
	inventory.Stone.Value = 5
end

-- Player management
Players.PlayerAdded:Connect(function(player)
	setupPlayerMining(player)
	setupPlayerInventory(player)

	player.CharacterAdded:Connect(function(character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		-- CRITICAL: Wait for terrain to be fully generated
		if not terrainGenerated then
			print(player.Name, "waiting for terrain generation...")

			-- Put player high in the sky and anchor them
			humanoidRootPart.CFrame = CFrame.new(
				(WORLD_WIDTH * BLOCK_SIZE) / 2,
				1000, -- Very high up
				(WORLD_WIDTH * BLOCK_SIZE) / 2
			)
			humanoidRootPart.Anchored = true

			-- Wait for terrain to finish
			repeat
				task.wait(1)
			until terrainGenerated

			print(player.Name, "terrain ready, spawning player...")

			-- Move player to proper spawn and unanchor
			humanoidRootPart.CFrame = CFrame.new(
				(WORLD_WIDTH * BLOCK_SIZE) / 2,
				BLOCK_SIZE + 5,
				(WORLD_WIDTH * BLOCK_SIZE) / 2
			)
			humanoidRootPart.Anchored = false
		else
			-- Terrain already generated, spawn normally
			humanoidRootPart.CFrame = CFrame.new(
				(WORLD_WIDTH * BLOCK_SIZE) / 2,
				BLOCK_SIZE + 5,
				(WORLD_WIDTH * BLOCK_SIZE) / 2
			)
		end

		-- Give starting tool
		task.wait(1)
		local tool = ReplicatedStorage:FindFirstChild("WoodenPickaxe")
		if tool then
			local toolClone = tool:Clone()
			toolClone.Parent = player.Backpack
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	cleanupPlayerMining(player)
end)

-- Generate world
createSpawn()

-- Wait for data persistence functions to load
print("Waiting for data persistence system...")
local maxWait = 10
local waited = 0
while (not _G.HasTerrainBeenGenerated or not _G.MarkTerrainGenerated or not _G.LoadMinedBlocks) and waited < maxWait do
	task.wait(0.5)
	waited = waited + 0.5
end

local useDataPersistence = _G.HasTerrainBeenGenerated ~= nil

if not useDataPersistence then
	warn("Data persistence system not found! Game will work but won't save.")
	warn("Make sure DataPersistenceHandler script is in ServerScriptService!")
	generateTerrain()
else
	print("Data persistence system loaded!")

	-- Check if terrain already exists
	local terrainExists = false
	local success, result = pcall(function()
		return _G.HasTerrainBeenGenerated()
	end)

	if not success then
		warn("DataStore error, generating fresh terrain:", result)
		terrainExists = false
	else
		terrainExists = result
	end

	if terrainExists then
		print("Terrain already generated, loading existing world...")

		-- Mark as generated so players don't wait
		terrainGenerated = true

		-- Load which blocks were mined
		local minedBlocks = _G.LoadMinedBlocks()

		-- Generate terrain but skip mined blocks
		print("Regenerating terrain with mined blocks removed...")
		local blocksPerBatch = 2000 -- Increased batch size for faster loading
		local totalBlocks = WORLD_WIDTH * WORLD_WIDTH * WORLD_DEPTH
		local blocksGenerated = 0

		for x = 0, WORLD_WIDTH - 1 do
			for z = 0, WORLD_WIDTH - 1 do
				for y = 0, WORLD_DEPTH - 1 do
					-- Check if this block was mined
					if not _G.IsBlockMined(x, y, z) then
						local materialType = getMaterialAtDepth(y, x, z)
						local materialData = MATERIALS[materialType]

						-- Create block more efficiently
						local block = Instance.new("Part")
						block.Name = materialType
						block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
						block.Position = Vector3.new(
							x * BLOCK_SIZE + BLOCK_SIZE/2,
							-y * BLOCK_SIZE - BLOCK_SIZE/2,
							z * BLOCK_SIZE + BLOCK_SIZE/2
						)
						block.Anchored = true
						block.Color = materialData.Color
						block.Material = Enum.Material.Slate
						block.TopSurface = Enum.SurfaceType.Smooth
						block.BottomSurface = Enum.SurfaceType.Smooth

						-- Create all values before parenting
						local healthValue = Instance.new("IntValue")
						healthValue.Name = "Health"
						healthValue.Value = materialData.Health

						local maxHealthValue = Instance.new("IntValue")
						maxHealthValue.Name = "MaxHealth"
						maxHealthValue.Value = materialData.Health

						local materialTypeValue = Instance.new("StringValue")
						materialTypeValue.Name = "MaterialType"
						materialTypeValue.Value = materialType

						local xValue = Instance.new("IntValue")
						xValue.Name = "GridX"
						xValue.Value = x

						local yValue = Instance.new("IntValue")
						yValue.Name = "GridY"
						yValue.Value = y

						local zValue = Instance.new("IntValue")
						zValue.Name = "GridZ"
						zValue.Value = z

						-- Parent all at once
						healthValue.Parent = block
						maxHealthValue.Parent = block
						materialTypeValue.Parent = block
						xValue.Parent = block
						yValue.Parent = block
						zValue.Parent = block

						block.Parent = TerrainFolder
					end

					blocksGenerated = blocksGenerated + 1

					if blocksGenerated % blocksPerBatch == 0 then
						local progress = (blocksGenerated / totalBlocks) * 100
						LoadingProgressEvent:FireAllClients(progress)
						task.wait()
					end
				end
			end
		end

		LoadingProgressEvent:FireAllClients(100)
		print("Existing world loaded!")

		-- Restore all placed blocks
		task.wait(1)
		if _G.RestorePlacedBlocks then
			_G.RestorePlacedBlocks()
		end
	else
		-- First time generation
		print("First time generation - creating new world...")
		generateTerrain()

		if useDataPersistence then
			pcall(function()
				_G.MarkTerrainGenerated()
			end)
		end
	end
end

print("Underground Game Server loaded!")