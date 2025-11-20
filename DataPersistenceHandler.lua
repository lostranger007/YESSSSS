-- ServerScriptService > DataPersistenceHandler (Script)
-- Add this as a NEW script in ServerScriptService

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_V1")
local TerrainDataStore = DataStoreService:GetDataStore("TerrainData_V1")
local BuildingDataStore = DataStoreService:GetDataStore("BuildingData_V1") -- NEW: Server-wide buildings

local AUTOSAVE_INTERVAL = 300 -- Save every 5 minutes (reduced frequency to avoid rate limits)

-- Terrain tracking
local MinedBlocks = {} -- Track which blocks have been mined {x, y, z}

-- Check if terrain has been generated before
local function hasTerrainBeenGenerated()
	local success, data = pcall(function()
		return TerrainDataStore:GetAsync("TerrainGenerated")
	end)

	if not success then
		warn("DataStore error checking terrain generation:", data)
		return false -- Assume not generated if error
	end

	if success and data then
		return true
	end
	return false
end

-- Mark terrain as generated
local function markTerrainGenerated()
	local success, err = pcall(function()
		TerrainDataStore:SetAsync("TerrainGenerated", true)
	end)

	if not success then
		warn("Failed to mark terrain as generated:", err)
	end
end

-- Save mined blocks
local function saveMinedBlocks()
	local success, err = pcall(function()
		TerrainDataStore:SetAsync("MinedBlocks", MinedBlocks)
	end)

	if success then
		print("Saved mined blocks data")
	else
		warn("Failed to save mined blocks:", err)
	end
end

-- Load mined blocks
local function loadMinedBlocks()
	local success, data = pcall(function()
		return TerrainDataStore:GetAsync("MinedBlocks")
	end)

	if not success then
		warn("Failed to load mined blocks:", data)
		return {}
	end

	if success and data then
		MinedBlocks = data
		print("Loaded", #data, "mined blocks")
		return MinedBlocks
	end
	return {}
end

-- Check if a block position was mined
local function isBlockMined(x, y, z)
	local key = string.format("%d_%d_%d", x, y, z)
	return MinedBlocks[key] == true
end

-- Save all placed blocks (server-wide)
local function saveAllPlacedBlocks()
	local success, errorMessage = pcall(function()
		local placedBlocks = {}

		local playerBuilds = workspace:FindFirstChild("PlayerBuilds")
		if playerBuilds then
			for _, block in ipairs(playerBuilds:GetChildren()) do
				if block:IsA("BasePart") then
					local blockTypeValue = block:FindFirstChild("BlockType")
					if blockTypeValue then
						table.insert(placedBlocks, {
							BlockType = blockTypeValue.Value,
							Position = {block.Position.X, block.Position.Y, block.Position.Z},
							Rotation = block.Orientation.Y
						})
					end
				end
			end
		end

		BuildingDataStore:SetAsync("AllPlacedBlocks", placedBlocks)
	end)

	if success then
		print("Saved all placed blocks")
	else
		warn("Failed to save placed blocks:", errorMessage)
	end
end

-- Load all placed blocks (server-wide)
local function loadAllPlacedBlocks()
	local success, data = pcall(function()
		return BuildingDataStore:GetAsync("AllPlacedBlocks")
	end)

	if success and data then
		print("Loaded", #data, "placed blocks from server")
		return data
	end
	return nil
end

-- Mark a block as mined
local function markBlockMined(x, y, z)
	local key = string.format("%d_%d_%d", x, y, z)
	MinedBlocks[key] = true
end

-- Get player data key
local function getPlayerKey(player)
	return "Player_" .. player.UserId
end

-- Default player data
local function getDefaultData()
	return {
		Inventory = {
			Dirt = 10,
			Stone = 5,
			IronOre = 0,
			DeepStone = 0,
			GoldOre = 0,
			Diamond = 0
		}
	}
end

-- Save player data
local function savePlayerData(player)
	local success, errorMessage = pcall(function()
		local data = {
			Inventory = {}
		}

		-- Save inventory
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			for _, resource in ipairs(inventory:GetChildren()) do
				if resource:IsA("IntValue") then
					data.Inventory[resource.Name] = resource.Value
				end
			end
		end

		PlayerDataStore:SetAsync(getPlayerKey(player), data)
	end)

	if success then
		print("Saved data for " .. player.Name)
	else
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(errorMessage))
	end
end

-- Load player data
local function loadPlayerData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(getPlayerKey(player))
	end)

	if success and data then
		print("Loaded data for " .. player.Name)
		return data
	else
		print("No saved data for " .. player.Name .. ", using defaults")
		return getDefaultData()
	end
end

-- Apply loaded data to player
local function applyPlayerData(player, data)
	-- Apply inventory
	local inventory = player:FindFirstChild("Inventory")
	if inventory and data.Inventory then
		for resourceName, amount in pairs(data.Inventory) do
			local resource = inventory:FindFirstChild(resourceName)
			if resource then
				resource.Value = amount
			end
		end
	end

	-- Update inventory GUI
	local UpdateInventoryEvent = game.ReplicatedStorage:FindFirstChild("RemoteEvents"):FindFirstChild("UpdateInventory")
	if UpdateInventoryEvent then
		UpdateInventoryEvent:FireClient(player)
	end
end

-- Restore placed blocks
local function restorePlacedBlocks()
	local data = loadAllPlacedBlocks()
	if not data then return end

	local playerBuilds = workspace:FindFirstChild("PlayerBuilds")
	if not playerBuilds then
		playerBuilds = Instance.new("Folder")
		playerBuilds.Name = "PlayerBuilds"
		playerBuilds.Parent = workspace
	end

	-- Block types reference (same as building system)
	local BLOCK_TYPES = {
		DirtFloor = {Size = Vector3.new(6, 0.5, 6), Color = Color3.fromRGB(139, 90, 43), Material = Enum.Material.Ground},
		StoneFloor = {Size = Vector3.new(6, 0.5, 6), Color = Color3.fromRGB(163, 162, 165), Material = Enum.Material.Slate},
		DirtWall = {Size = Vector3.new(6, 6, 0.5), Color = Color3.fromRGB(120, 80, 40), Material = Enum.Material.Ground},
		StoneWall = {Size = Vector3.new(6, 6, 0.5), Color = Color3.fromRGB(140, 140, 145), Material = Enum.Material.Slate},
		DirtDoor = {Size = Vector3.new(4, 6, 0.5), Color = Color3.fromRGB(101, 67, 33), Material = Enum.Material.Ground, IsDoor = true},
		Ladder = {Size = Vector3.new(2, 6, 0.5), Color = Color3.fromRGB(139, 90, 43), Material = Enum.Material.WoodPlanks, IsLadder = true},
		DirtPillar = {Size = Vector3.new(1.5, 6, 1.5), Color = Color3.fromRGB(101, 67, 33), Material = Enum.Material.Ground},
		StonePillar = {Size = Vector3.new(1.5, 6, 1.5), Color = Color3.fromRGB(120, 120, 125), Material = Enum.Material.Slate},
		DirtRoof = {Size = Vector3.new(6, 0.5, 6), Color = Color3.fromRGB(90, 60, 30), Material = Enum.Material.Ground},
		Torch = {Size = Vector3.new(0.5, 2, 0.5), Color = Color3.fromRGB(255, 200, 100), Material = Enum.Material.Neon, IsLight = true}
	}

	for _, blockData in ipairs(data) do
		local blockType = blockData.BlockType
		local blockInfo = BLOCK_TYPES[blockType]

		if blockInfo then
			local block = Instance.new("Part")
			block.Name = blockType
			block.Size = blockInfo.Size
			block.Position = Vector3.new(blockData.Position[1], blockData.Position[2], blockData.Position[3])
			block.CFrame = CFrame.new(block.Position) * CFrame.Angles(0, math.rad(blockData.Rotation), 0)
			block.Anchored = true
			block.Color = blockInfo.Color
			block.Material = blockInfo.Material
			block.Parent = playerBuilds

			-- Store block type
			local blockTypeValue = Instance.new("StringValue")
			blockTypeValue.Name = "BlockType"
			blockTypeValue.Value = blockType
			blockTypeValue.Parent = block

			-- Add special features
			if blockInfo.IsDoor then
				local clickDetector = Instance.new("ClickDetector")
				clickDetector.MaxActivationDistance = 10
				clickDetector.Parent = block

				local isOpen = false
				clickDetector.MouseClick:Connect(function()
					isOpen = not isOpen
					block.Transparency = isOpen and 0.7 or 0
					block.CanCollide = not isOpen
				end)
			end

			if blockInfo.IsLadder then
				block.CanCollide = false
				local truss = Instance.new("TrussPart")
				truss.Size = blockInfo.Size
				truss.CFrame = block.CFrame
				truss.Transparency = 1
				truss.Parent = block
			end

			if blockInfo.IsLight then
				local light = Instance.new("PointLight")
				light.Brightness = 2
				light.Range = 20
				light.Color = Color3.fromRGB(255, 200, 100)
				light.Parent = block
			end
		end
	end

	print("Restored", #data, "placed blocks")
end

-- Expose functions for main server script
_G.HasTerrainBeenGenerated = hasTerrainBeenGenerated
_G.MarkTerrainGenerated = markTerrainGenerated
_G.LoadMinedBlocks = loadMinedBlocks
_G.IsBlockMined = isBlockMined
_G.MarkBlockMined = markBlockMined
_G.SaveMinedBlocks = saveMinedBlocks
_G.RestorePlacedBlocks = restorePlacedBlocks
_G.SaveAllPlacedBlocks = saveAllPlacedBlocks

-- Player joined
Players.PlayerAdded:Connect(function(player)
	-- Wait for character
	player.CharacterAdded:Connect(function(character)
		task.wait(2) -- Wait for inventory to be created

		-- Load and apply player data
		local data = loadPlayerData(player)
		applyPlayerData(player, data)
	end)
end)

-- Player leaving - save their data
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

-- Autosave all players periodically
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)

		-- Save all player data
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end

		-- Save mined blocks
		saveMinedBlocks()

		-- Save all placed blocks
		saveAllPlacedBlocks()

		print("Autosave completed")
	end
end)

-- Save on server shutdown
game:BindToClose(function()
	print("Server shutting down, saving all data...")

	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end

	saveMinedBlocks()
	saveAllPlacedBlocks()

	task.wait(3) -- Give time for saves to complete
end)

print("Data Persistence Handler loaded!")