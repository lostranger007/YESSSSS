-- ReplicatedStorage > WoodenPickaxe > PickaxeScript (LocalScript)
local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local StartMiningEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StartMining")
local StopMiningEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StopMining")

local currentBlock = nil
local isMining = false
local miningConnection = nil
local healthBarGui = nil
local highlightBox = nil
local highlightConnection = nil

-- Create highlight box for hovering
local function createHighlightBox()
	if highlightBox then
		highlightBox:Destroy()
	end

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Name = "HighlightBox"
	selectionBox.LineThickness = 0.05
	selectionBox.Color3 = Color3.fromRGB(255, 255, 0) -- Yellow outline
	selectionBox.SurfaceColor3 = Color3.fromRGB(255, 255, 0)
	selectionBox.SurfaceTransparency = 0.9
	selectionBox.Parent = workspace

	highlightBox = selectionBox
	return selectionBox
end

-- Update highlight to follow mouse
local function updateHighlight()
	if not highlightBox then return end

	local target = mouse.Target

	-- Only highlight terrain blocks, not player builds
	if target and target.Parent and target.Parent.Name == "Terrain" then
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local distance = (humanoidRootPart.Position - target.Position).Magnitude
				if distance <= 20 then
					highlightBox.Adornee = target
				else
					highlightBox.Adornee = nil
				end
			end
		end
	else
		highlightBox.Adornee = nil
	end
end

-- Create health bar GUI
local function createHealthBar(block)
	if healthBarGui then
		healthBarGui:Destroy()
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HealthBar"
	billboardGui.Adornee = block
	billboardGui.Size = UDim2.new(4, 0, 0.5, 0)
	billboardGui.StudsOffset = Vector3.new(0, 4, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = block

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 2
	frame.Parent = billboardGui

	local healthBar = Instance.new("Frame")
	healthBar.Name = "Bar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = frame

	healthBarGui = billboardGui
	return billboardGui
end

-- Update health bar
local function updateHealthBar(block)
	if not healthBarGui or healthBarGui.Parent ~= block then return end

	local health = block:FindFirstChild("Health")
	local maxHealth = block:FindFirstChild("MaxHealth")

	if health and maxHealth then
		local healthPercent = health.Value / maxHealth.Value
		local bar = healthBarGui.Frame.Bar
		bar.Size = UDim2.new(healthPercent, 0, 1, 0)

		-- Color based on health
		if healthPercent > 0.6 then
			bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		elseif healthPercent > 0.3 then
			bar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
		else
			bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
	end
end

-- Start mining
local function startMining(block)
	if isMining then return end
	if not block or not block:FindFirstChild("Health") then return end

	currentBlock = block
	isMining = true

	-- Create health bar
	createHealthBar(block)

	-- Send to server
	StartMiningEvent:FireServer(block, tool)

	-- Update health bar while mining
	miningConnection = RunService.Heartbeat:Connect(function()
		if currentBlock and currentBlock.Parent then
			updateHealthBar(currentBlock)
		else
			-- Block is destroyed, stop mining and require mouse release
			stopMining()
		end
	end)
end

-- Stop mining
function stopMining()
	if not isMining then return end

	isMining = false
	currentBlock = nil

	if miningConnection then
		miningConnection:Disconnect()
		miningConnection = nil
	end

	if healthBarGui then
		healthBarGui:Destroy()
		healthBarGui = nil
	end

	StopMiningEvent:FireServer()
end

-- Mouse button state
local isMouseDown = false
local hasMinedThisClick = false
local isEquipped = false

-- Mouse button down - start mining
mouse.Button1Down:Connect(function()
	if not isEquipped then return end -- Can't mine if pickaxe not equipped
	if isMining then return end -- Already mining, ignore

	isMouseDown = true
	hasMinedThisClick = false

	local target = mouse.Target

	-- Only mine terrain blocks, NOT player builds
	if target and target.Parent and target.Parent.Name == "Terrain" then
		-- Check if block is within range
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local distance = (humanoidRootPart.Position - target.Position).Magnitude
				if distance <= 20 then -- Mining range
					startMining(target)
					hasMinedThisClick = true
				end
			end
		end
	end
end)

-- Mouse button up - allow mining again
mouse.Button1Up:Connect(function()
	if not isEquipped then return end -- Only handle if equipped

	isMouseDown = false
	hasMinedThisClick = false
	stopMining()
end)

-- Tool equipped - start highlighting
tool.Equipped:Connect(function()
	isEquipped = true
	createHighlightBox()

	-- Update highlight every frame
	highlightConnection = RunService.RenderStepped:Connect(updateHighlight)
end)

-- Tool unequipped - stop everything
tool.Unequipped:Connect(function()
	isEquipped = false
	stopMining()

	if highlightConnection then
		highlightConnection:Disconnect()
		highlightConnection = nil
	end

	if highlightBox then
		highlightBox:Destroy()
		highlightBox = nil
	end
end)