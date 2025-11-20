-- ServerScriptService > BuildingServerHandler (Script)
-- Add this as a NEW script in ServerScriptService, don't replace the main server script

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create PlayerBuilds folder
local PlayerBuildsFolder = Instance.new("Folder")
PlayerBuildsFolder.Name = "PlayerBuilds"
PlayerBuildsFolder.Parent = workspace

-- Wait for RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceBlockEvent = RemoteEvents:FindFirstChild("PlaceBlock")
local DeleteBlockEvent = RemoteEvents:FindFirstChild("DeleteBlock")

-- Create events if they don't exist
if not PlaceBlockEvent then
	PlaceBlockEvent = Instance.new("RemoteEvent")
	PlaceBlockEvent.Name = "PlaceBlock"
	PlaceBlockEvent.Parent = RemoteEvents
end

if not DeleteBlockEvent then
	DeleteBlockEvent = Instance.new("RemoteEvent")
	DeleteBlockEvent.Name = "DeleteBlock"
	DeleteBlockEvent.Parent = RemoteEvents
end

-- Block types (same as client)
local BLOCK_TYPES = {
	DirtFloor = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(139, 90, 43),
		Cost = {Dirt = 2},
		Material = Enum.Material.Ground,
		CanRotate = false
	},
	StoneFloor = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(163, 162, 165),
		Cost = {Stone = 3},
		Material = Enum.Material.Slate,
		CanRotate = false
	},
	DirtWall = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(120, 80, 40),
		Cost = {Dirt = 3},
		Material = Enum.Material.Ground,
		CanRotate = true
	},
	StoneWall = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(140, 140, 145),
		Cost = {Stone = 4},
		Material = Enum.Material.Slate,
		CanRotate = true
	},
	DirtDoor = {
		Size = Vector3.new(4, 6, 0.5),
		Color = Color3.fromRGB(101, 67, 33),
		Cost = {Dirt = 4},
		Material = Enum.Material.Ground,
		CanRotate = true,
		IsDoor = true
	},
	Ladder = {
		Size = Vector3.new(2, 6, 0.5),
		Color = Color3.fromRGB(139, 90, 43),
		Cost = {Dirt = 2},
		Material = Enum.Material.WoodPlanks,
		CanRotate = true,
		IsLadder = true
	},
	DirtPillar = {
		Size = Vector3.new(1.5, 6, 1.5),
		Color = Color3.fromRGB(101, 67, 33),
		Cost = {Dirt = 2},
		Material = Enum.Material.Ground,
		CanRotate = false
	},
	StonePillar = {
		Size = Vector3.new(1.5, 6, 1.5),
		Color = Color3.fromRGB(120, 120, 125),
		Cost = {Stone = 3},
		Material = Enum.Material.Slate,
		CanRotate = false
	},
	DirtRoof = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(90, 60, 30),
		Cost = {Dirt = 2},
		Material = Enum.Material.Ground,
		CanRotate = false
	},
	Torch = {
		Size = Vector3.new(0.5, 2, 0.5),
		Color = Color3.fromRGB(255, 200, 100),
		Cost = {Dirt = 1},
		Material = Enum.Material.Neon,
		CanRotate = false,
		IsLight = true
	},
	CraftingStation = {
		Size = Vector3.new(3, 3, 3),
		Color = Color3.fromRGB(101, 67, 33),
		Cost = {Dirt = 5, Stone = 5},
		Material = Enum.Material.Wood,
		CanRotate = false,
		IsInteractable = true
	},
	-- NEW: More floor types
	StoneFloorPolished = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(200, 200, 205),
		Cost = {Stone = 4},
		Material = Enum.Material.Marble,
		CanRotate = false
	},
	IronFloor = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(180, 180, 185),
		Cost = {IronOre = 3},
		Material = Enum.Material.Metal,
		CanRotate = false
	},
	WoodPlankFloor = {
		Size = Vector3.new(6, 0.5, 6),
		Color = Color3.fromRGB(160, 110, 70),
		Cost = {Dirt = 3},
		Material = Enum.Material.WoodPlanks,
		CanRotate = false
	},
	-- NEW: More wall types
	StoneWallBrick = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(150, 140, 140),
		Cost = {Stone = 5},
		Material = Enum.Material.Brick,
		CanRotate = true
	},
	IronWall = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(170, 170, 175),
		Cost = {IronOre = 4},
		Material = Enum.Material.Metal,
		CanRotate = true
	},
	GlassWall = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(200, 220, 255),
		Cost = {Stone = 6},
		Material = Enum.Material.Glass,
		CanRotate = true
	},
	WoodPlankWall = {
		Size = Vector3.new(6, 6, 0.5),
		Color = Color3.fromRGB(140, 100, 60),
		Cost = {Dirt = 4},
		Material = Enum.Material.WoodPlanks,
		CanRotate = true
	},
	-- NEW: Furniture
	WoodTable = {
		Size = Vector3.new(4, 3, 2),
		Color = Color3.fromRGB(120, 80, 50),
		Cost = {Dirt = 6},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	WoodChair = {
		Size = Vector3.new(2, 3, 2),
		Color = Color3.fromRGB(110, 70, 40),
		Cost = {Dirt = 4},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	StorageChest = {
		Size = Vector3.new(3, 2, 2),
		Color = Color3.fromRGB(101, 67, 33),
		Cost = {Dirt = 8},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	Bed = {
		Size = Vector3.new(4, 2, 6),
		Color = Color3.fromRGB(200, 50, 50),
		Cost = {Dirt = 10},
		Material = Enum.Material.Fabric,
		CanRotate = true
	},
	-- NEW: Decorations
	Lantern = {
		Size = Vector3.new(1, 3, 1),
		Color = Color3.fromRGB(255, 220, 150),
		Cost = {IronOre = 2, Dirt = 1},
		Material = Enum.Material.Neon,
		CanRotate = false,
		IsLight = true
	},
	Banner = {
		Size = Vector3.new(0.2, 4, 2),
		Color = Color3.fromRGB(150, 50, 50),
		Cost = {Dirt = 3},
		Material = Enum.Material.Fabric,
		CanRotate = true
	},
	Carpet = {
		Size = Vector3.new(4, 0.2, 6),
		Color = Color3.fromRGB(180, 50, 50),
		Cost = {Dirt = 5},
		Material = Enum.Material.Fabric,
		CanRotate = true
	},
	SmallCrate = {
		Size = Vector3.new(2, 2, 2),
		Color = Color3.fromRGB(130, 90, 60),
		Cost = {Dirt = 3},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	LargeCrate = {
		Size = Vector3.new(3, 3, 3),
		Color = Color3.fromRGB(120, 80, 50),
		Cost = {Dirt = 6, Stone = 2},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	Barrel = {
		Size = Vector3.new(2, 3, 2),
		Color = Color3.fromRGB(100, 70, 40),
		Cost = {Dirt = 4},
		Material = Enum.Material.Wood,
		CanRotate = false
	},
	IronFence = {
		Size = Vector3.new(6, 3, 0.3),
		Color = Color3.fromRGB(160, 160, 165),
		Cost = {IronOre = 3},
		Material = Enum.Material.Metal,
		CanRotate = true
	},
	WoodSign = {
		Size = Vector3.new(3, 2, 0.3),
		Color = Color3.fromRGB(140, 100, 60),
		Cost = {Dirt = 2},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	Bookshelf = {
		Size = Vector3.new(4, 6, 1),
		Color = Color3.fromRGB(100, 60, 30),
		Cost = {Dirt = 8},
		Material = Enum.Material.Wood,
		CanRotate = true
	},
	WindowFrame = {
		Size = Vector3.new(4, 4, 0.5),
		Color = Color3.fromRGB(180, 200, 220),
		Cost = {Stone = 4},
		Material = Enum.Material.Glass,
		CanRotate = true
	}
}

-- Add "Dirt" resource to materials if not present (remove Wood function)
local function ensureDirtResource(player)
	local inventory = player:FindFirstChild("Inventory")
	if inventory and not inventory:FindFirstChild("Dirt") then
		-- Dirt already exists from mining, but make sure it's there
	end
end

-- Check if player can afford
local function canAfford(player, blockType)
	local blockData = BLOCK_TYPES[blockType]
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return false end

	for resource, amount in pairs(blockData.Cost) do
		local resourceValue = inventory:FindFirstChild(resource)
		if not resourceValue or resourceValue.Value < amount then
			return false
		end
	end

	return true
end

-- Deduct resources
local function deductResources(player, blockType)
	local blockData = BLOCK_TYPES[blockType]
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	for resource, amount in pairs(blockData.Cost) do
		local resourceValue = inventory:FindFirstChild(resource)
		if resourceValue then
			resourceValue.Value = resourceValue.Value - amount
		end
	end
end

-- Refund resources
local function refundResources(player, blockType)
	local blockData = BLOCK_TYPES[blockType]
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	for resource, amount in pairs(blockData.Cost) do
		local resourceValue = inventory:FindFirstChild(resource)
		if resourceValue then
			resourceValue.Value = resourceValue.Value + amount
		end
	end
end

-- Handle block placement
PlaceBlockEvent.OnServerEvent:Connect(function(player, blockType, position, rotation)
	print(player.Name .. " requested to place " .. blockType .. " at " .. tostring(position))

	if not BLOCK_TYPES[blockType] then
		warn("Invalid block type: " .. tostring(blockType))
		return
	end

	if not canAfford(player, blockType) then
		warn(player.Name .. " cannot afford " .. blockType)
		-- Debug: show current inventory
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			print("Current inventory:")
			for _, resource in ipairs(inventory:GetChildren()) do
				if resource:IsA("IntValue") then
					print("  " .. resource.Name .. ": " .. resource.Value)
				end
			end
		else
			warn("No inventory found!")
		end
		return
	end

	print("Placing " .. blockType .. " for " .. player.Name)

	local blockData = BLOCK_TYPES[blockType]

	-- Create block
	local block = Instance.new("Part")
	block.Name = blockType
	block.Size = blockData.Size
	block.Position = position
	block.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	block.Anchored = true
	block.Color = blockData.Color
	block.Material = blockData.Material
	block.Parent = PlayerBuildsFolder

	-- Store block type
	local blockTypeValue = Instance.new("StringValue")
	blockTypeValue.Name = "BlockType"
	blockTypeValue.Value = blockType
	blockTypeValue.Parent = block

	-- Add special properties
	if blockData.IsDoor then
		-- Make door clickable
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = block

		local isOpen = false
		clickDetector.MouseClick:Connect(function(playerWhoClicked)
			isOpen = not isOpen
			if isOpen then
				block.Transparency = 0.7
				block.CanCollide = false
			else
				block.Transparency = 0
				block.CanCollide = true
			end
		end)
	end

	if blockData.IsLadder then
		-- Add ladder climbing (using TrussPart for climbable)
		block.CanCollide = false

		-- Create invisible truss for climbing
		local truss = Instance.new("TrussPart")
		truss.Size = blockData.Size
		truss.CFrame = block.CFrame
		truss.Transparency = 1
		truss.Parent = block
	end

	if blockData.IsLight then
		-- Add point light
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 20
		light.Color = Color3.fromRGB(255, 200, 100)
		light.Parent = block
	end

	if blockData.IsInteractable then
		-- Add click detector for crafting station
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 10
		clickDetector.Parent = block

		clickDetector.MouseClick:Connect(function(playerWhoClicked)
			-- Open crafting GUI
			local OpenCraftingEvent = RemoteEvents:FindFirstChild("OpenCrafting")
			if OpenCraftingEvent then
				OpenCraftingEvent:FireClient(playerWhoClicked)
			end
		end)

		-- Add label
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Size = UDim2.new(0, 100, 0, 40)
		billboardGui.StudsOffset = Vector3.new(0, 3, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.Parent = block

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "?? Crafting"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 18
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.5
		label.Parent = billboardGui
	end

	-- Deduct resources
	deductResources(player, blockType)

	-- Update client inventory display
	local UpdateInventoryEvent = RemoteEvents:FindFirstChild("UpdateInventory")
	if UpdateInventoryEvent then
		UpdateInventoryEvent:FireClient(player)
	end

	print(player.Name .. " placed " .. blockType .. " at " .. tostring(position))
end)

-- Handle block deletion
DeleteBlockEvent.OnServerEvent:Connect(function(player, block)
	if not block or block.Parent ~= PlayerBuildsFolder then return end

	local blockTypeValue = block:FindFirstChild("BlockType")
	if blockTypeValue then
		-- Refund resources
		refundResources(player, blockTypeValue.Value)
	end

	block:Destroy()
	print(player.Name .. " deleted a block")
end)

-- Setup players (no need to add resources, they get them from mining)
Players.PlayerAdded:Connect(function(player)
	-- Resources are already added by main server script
end)

print("Building server handler loaded!")