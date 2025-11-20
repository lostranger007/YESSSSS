-- StarterPlayer > StarterPlayerScripts > BuildingSystem (LocalScript)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Wait for remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceBlockEvent = RemoteEvents:WaitForChild("PlaceBlock")
local DeleteBlockEvent = RemoteEvents:WaitForChild("DeleteBlock")

-- Building configuration
local GRID_SIZE = 6
local BUILD_RANGE = 30

-- Building state
local buildMode = false
local deleteMode = false
local currentBlockType = "DirtFloor"
local currentRotation = 0
local ghostBlock = nil
local canPlace = false

-- Block types with their properties and costs
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

-- Snap position to grid
local function snapToGrid(position)
	return Vector3.new(
		math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE,
		math.floor(position.Y / GRID_SIZE + 0.5) * GRID_SIZE,
		math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
	)
end

-- Snap walls to grid edges
local function snapWallToGrid(position, rotation)
	local snappedPos
	if rotation == 0 or rotation == 180 then
		-- Wall aligned along Z-axis, snap to edge of Z grid
		snappedPos = Vector3.new(
			math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE,
			position.Y,
			math.floor(position.Z / GRID_SIZE) * GRID_SIZE
		)
	else
		-- Wall aligned along X-axis, snap to edge of X grid  
		snappedPos = Vector3.new(
			math.floor(position.X / GRID_SIZE) * GRID_SIZE,
			position.Y,
			math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
		)
	end
	return snappedPos
end

-- Check if player can afford block
local function canAfford(blockType)
	local blockData = BLOCK_TYPES[blockType]
	if not blockData then return false end

	-- Get inventory from player (server creates this)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return false end

	-- Check each resource requirement
	for resource, amount in pairs(blockData.Cost) do
		local resourceValue = inventory:FindFirstChild(resource)
		if resourceValue and resourceValue:IsA("IntValue") then
			if resourceValue.Value < amount then
				return false
			end
		else
			return false
		end
	end

	return true
end

-- Check if placement is valid
local function isValidPlacement(position, size, rotation)
	-- Check if within range
	local character = player.Character
	if not character then return false end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end

	local distance = (humanoidRootPart.Position - position).Magnitude
	if distance > BUILD_RANGE then return false end

	-- Check for overlapping blocks using GetPartBoundsInBox (newer method)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	-- Only check for collisions with PlayerBuilds folder
	local playerBuildsFolder = workspace:FindFirstChild("PlayerBuilds")
	if playerBuildsFolder then
		overlapParams.FilterDescendantsInstances = {playerBuildsFolder}

		-- Create CFrame for the position with rotation
		local cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)

		-- Check for overlapping parts
		local overlappingParts = workspace:GetPartBoundsInBox(cframe, size, overlapParams)

		if #overlappingParts > 0 then
			return false
		end
	end

	return true
end

-- Create ghost block preview
local function createGhostBlock()
	if ghostBlock then
		ghostBlock:Destroy()
	end

	local blockData = BLOCK_TYPES[currentBlockType]
	if not blockData then
		warn("Invalid block type:", currentBlockType)
		return nil
	end

	local ghost = Instance.new("Part")
	ghost.Name = "GhostBlock"
	ghost.Size = blockData.Size
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.Transparency = 0.7
	ghost.Material = blockData.Material
	ghost.Color = blockData.Color
	ghost.Parent = workspace

	-- Add outline using SelectionBox
	local outline = Instance.new("SelectionBox")
	outline.Adornee = ghost
	outline.LineThickness = 0.05
	outline.Color3 = Color3.fromRGB(0, 255, 0)
	outline.Parent = ghost

	-- Add light effect for torches
	if blockData.IsLight then
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 20
		light.Color = Color3.fromRGB(255, 200, 100)
		light.Parent = ghost
	end

	ghostBlock = ghost
	return ghost
end

-- Update ghost block position and rotation
local function updateGhostBlock()
	if not buildMode or not ghostBlock then return end

	local targetPos = mouse.Hit.Position
	local blockData = BLOCK_TYPES[currentBlockType]
	if not blockData then return end

	local snappedPos

	-- Different snapping for walls vs other blocks
	if currentBlockType:find("Wall") or currentBlockType:find("Door") or currentBlockType:find("Ladder") or currentBlockType:find("Fence") or currentBlockType:find("Window") or currentBlockType:find("Shelf") then
		-- Walls snap to grid edges
		snappedPos = snapWallToGrid(targetPos, currentRotation)
		-- Elevate walls so their bottom is at ground level
		snappedPos = snappedPos + Vector3.new(0, blockData.Size.Y / 2, 0)
	else
		-- Floors and other blocks snap to grid centers
		snappedPos = snapToGrid(targetPos)
	end

	-- Apply rotation
	local rotationCFrame = CFrame.Angles(0, math.rad(currentRotation), 0)
	ghostBlock.CFrame = CFrame.new(snappedPos) * rotationCFrame

	-- Check if placement is valid
	local hasResources = canAfford(currentBlockType)
	local validPlacement = isValidPlacement(snappedPos, blockData.Size, currentRotation)
	canPlace = hasResources and validPlacement

	-- Debug output (remove later if needed)
	if not hasResources then
		print("Not enough resources for " .. currentBlockType)
	end
	if not validPlacement then
		print("Invalid placement location")
	end

	-- Update outline color
	local outline = ghostBlock:FindFirstChildOfClass("SelectionBox")
	if outline then
		if canPlace then
			outline.Color3 = Color3.fromRGB(0, 255, 0) -- Green
		else
			outline.Color3 = Color3.fromRGB(255, 0, 0) -- Red
		end
	end
end

-- Place block
local function placeBlock()
	if not buildMode then
		print("Cannot place: Build mode not enabled")
		return
	end
	if not canPlace then
		print("Cannot place: Validation failed")
		return
	end
	if not ghostBlock then
		print("Cannot place: No ghost block")
		return
	end

	local position = ghostBlock.Position
	local rotation = currentRotation

	print("Attempting to place " .. currentBlockType .. " at " .. tostring(position))

	-- Send to server
	PlaceBlockEvent:FireServer(currentBlockType, position, rotation)
end

-- Delete block
local function deleteBlock()
	if not deleteMode then return end

	local target = mouse.Target
	if target and target.Parent and target.Parent.Name == "PlayerBuilds" then
		-- Check if within range
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local distance = (humanoidRootPart.Position - target.Position).Magnitude
				if distance <= BUILD_RANGE then
					DeleteBlockEvent:FireServer(target)
				end
			end
		end
	end
end

-- Toggle build mode
function toggleBuildMode()
	buildMode = not buildMode
	deleteMode = false -- Turn off delete mode

	if buildMode then
		createGhostBlock()
		print("Build mode ENABLED")
	else
		if ghostBlock then
			ghostBlock:Destroy()
			ghostBlock = nil
		end
		print("Build mode DISABLED")
	end

	-- Update GUI
	local buildGui = player.PlayerGui:FindFirstChild("BuildGui")
	if buildGui then
		local buildButton = buildGui:FindFirstChild("BuildButton")
		local deleteButton = buildGui:FindFirstChild("DeleteButton")
		if buildButton then
			buildButton.Text = buildMode and "BUILD MODE: ON" or "BUILD MODE: OFF"
			buildButton.BackgroundColor3 = buildMode and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
		end
		if deleteButton then
			deleteButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end
	end
end

-- Toggle delete mode
function toggleDeleteMode()
	deleteMode = not deleteMode
	buildMode = false -- Turn off build mode

	if not deleteMode and ghostBlock then
		ghostBlock:Destroy()
		ghostBlock = nil
	end

	print(deleteMode and "Delete mode ENABLED" or "Delete mode DISABLED")

	-- Update GUI
	local buildGui = player.PlayerGui:FindFirstChild("BuildGui")
	if buildGui then
		local buildButton = buildGui:FindFirstChild("BuildButton")
		local deleteButton = buildGui:FindFirstChild("DeleteButton")
		if buildButton then
			buildButton.Text = "BUILD MODE: OFF"
			buildButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end
		if deleteButton then
			deleteButton.Text = deleteMode and "DELETE MODE: ON" or "DELETE MODE: OFF"
			deleteButton.BackgroundColor3 = deleteMode and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(100, 100, 100)
		end
	end
end

-- Change block type
function changeBlockType(blockType)
	if BLOCK_TYPES[blockType] then
		currentBlockType = blockType
		if buildMode then
			createGhostBlock()
		end
		print("Selected block type:", blockType)
	else
		warn("Invalid block type:", blockType)
	end
end

-- NEW: Set build mode directly (for GUI)
local function setBuildMode(enabled)
	buildMode = enabled
	if enabled then
		deleteMode = false
		createGhostBlock()
		print("Build mode SET to ENABLED")
	else
		if ghostBlock then
			ghostBlock:Destroy()
			ghostBlock = nil
		end
		print("Build mode SET to DISABLED")
	end
end

-- NEW: Set delete mode directly (for GUI)
local function setDeleteMode(enabled)
	deleteMode = enabled
	if enabled then
		buildMode = false
		if ghostBlock then
			ghostBlock:Destroy()
			ghostBlock = nil
		end
		print("Delete mode SET to ENABLED")
	else
		print("Delete mode SET to DISABLED")
	end
end

-- NEW: Get delete mode state (for GUI)
local function getDeleteMode()
	return deleteMode
end

-- Rotate block
local function rotateBlock()
	if buildMode and BLOCK_TYPES[currentBlockType] and BLOCK_TYPES[currentBlockType].CanRotate then
		currentRotation = (currentRotation + 90) % 360
		print("Rotation:", currentRotation)
	end
end

-- Mouse click
mouse.Button1Down:Connect(function()
	if buildMode then
		placeBlock()
	elseif deleteMode then
		deleteBlock()
	end
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		rotateBlock()
	end
end)

-- Update ghost block every frame
RunService.RenderStepped:Connect(function()
	if buildMode and ghostBlock then
		updateGhostBlock()
	end
end)

-- Expose functions globally for GUI buttons
_G.ToggleBuildMode = toggleBuildMode
_G.ToggleDeleteMode = toggleDeleteMode
_G.ChangeBlockType = changeBlockType
_G.SetBuildMode = setBuildMode  -- NEW
_G.SetDeleteMode = setDeleteMode  -- NEW
_G.GetDeleteMode = getDeleteMode  -- NEW

print("Building system loaded!")