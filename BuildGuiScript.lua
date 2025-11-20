-- BuildGuiScript.lua
-- Place this in StarterGui > BuildGui as a LocalScript

local player = game.Players.LocalPlayer
local screenGui = script.Parent

-- Block types matching BuildingSystem (no spaces, exact keys)
local blockTypes = {
	"DirtFloor", "StoneFloor", "DirtWall", "StoneWall",
	"DirtDoor", "Ladder", "DirtPillar", "StonePillar",
	"DirtRoof", "Torch", "CraftingStation"
}

-- Display names for the buttons (with spaces for readability)
local blockDisplayNames = {
	DirtFloor = "Dirt Floor",
	StoneFloor = "Stone Floor",
	DirtWall = "Dirt Wall",
	StoneWall = "Stone Wall",
	DirtDoor = "Dirt Door",
	Ladder = "Ladder",
	DirtPillar = "Dirt Pillar",
	StonePillar = "Stone Pillar",
	DirtRoof = "Dirt Roof",
	Torch = "Torch",
	CraftingStation = "Crafting Station"
}

-- Create toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "BuildToggle"
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0.01, 0, 0.07, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleButton.BorderSizePixel = 2
toggleButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
toggleButton.Text = "?? BUILD MENU"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 18
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

-- Create delete button
local deleteButton = Instance.new("TextButton")
deleteButton.Name = "DeleteToggle"
deleteButton.Size = UDim2.new(0, 150, 0, 40)
deleteButton.Position = UDim2.new(0.01, 0, 0.13, 0)
deleteButton.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
deleteButton.BorderSizePixel = 2
deleteButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
deleteButton.Text = "??? DELETE MODE"
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.TextSize = 18
deleteButton.Font = Enum.Font.GothamBold
deleteButton.Parent = screenGui

-- Create main panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 200, 0, 500)
mainPanel.Position = UDim2.new(0.01, 0, 0.2, 0)
mainPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainPanel.BorderSizePixel = 2
mainPanel.BorderColor3 = Color3.fromRGB(200, 200, 200)
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- Create title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.BorderSizePixel = 0
title.Text = "BUILD MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = mainPanel

-- Create instructions
local instructions = Instance.new("TextLabel")
instructions.Name = "Instructions"
instructions.Size = UDim2.new(1, -10, 0, 80)
instructions.Position = UDim2.new(0, 5, 0, 45)
instructions.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
instructions.BorderSizePixel = 1
instructions.BorderColor3 = Color3.fromRGB(100, 100, 100)
instructions.Text = "CONTROLS:\nLeft Click: Place Block\nR: Rotate Block\nESC: Close Menu"
instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
instructions.TextSize = 14
instructions.Font = Enum.Font.Gotham
instructions.TextWrapped = true
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.Parent = mainPanel

-- Create scrolling frame for blocks
local blockSelectorFrame = Instance.new("ScrollingFrame")
blockSelectorFrame.Name = "BlockSelector"
blockSelectorFrame.Size = UDim2.new(1, -10, 1, -135)
blockSelectorFrame.Position = UDim2.new(0, 5, 0, 130)
blockSelectorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
blockSelectorFrame.BorderSizePixel = 1
blockSelectorFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
blockSelectorFrame.ScrollBarThickness = 8
blockSelectorFrame.Parent = mainPanel

-- Track current selected button
local currentSelectedButton = nil

-- Create block buttons
for i, blockType in ipairs(blockTypes) do
	local button = Instance.new("TextButton")
	button.Name = blockType .. "Button"
	button.Size = UDim2.new(1, -10, 0, 50)
	button.Position = UDim2.new(0, 5, 0, (i-1) * 55)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.BorderSizePixel = 2
	button.BorderColor3 = Color3.fromRGB(100, 100, 100)
	button.Text = blockDisplayNames[blockType] or blockType
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.Font = Enum.Font.Gotham
	button.Parent = blockSelectorFrame

	button.MouseButton1Click:Connect(function()
		-- Deselect previous
		if currentSelectedButton then
			currentSelectedButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
			currentSelectedButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end

		-- Select new
		button.BorderColor3 = Color3.fromRGB(0, 200, 255)
		button.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		currentSelectedButton = button

		-- Change block type (use the actual key, not the display name)
		_G.ChangeBlockType(blockType)
	end)
end

-- Set first block as selected by default
local firstButton = blockSelectorFrame:FindFirstChild(blockTypes[1] .. "Button")
if firstButton then
	firstButton.BorderColor3 = Color3.fromRGB(0, 200, 255)
	firstButton.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
	currentSelectedButton = firstButton
end

-- Update canvas size
blockSelectorFrame.CanvasSize = UDim2.new(0, 0, 0, #blockTypes * 55)

-- Toggle functionality
toggleButton.MouseButton1Click:Connect(function()
	mainPanel.Visible = not mainPanel.Visible
	if mainPanel.Visible then
		toggleButton.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
		_G.SetBuildMode(true)
		_G.SetDeleteMode(false)
		deleteButton.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		_G.SetBuildMode(false)
	end
end)

-- Delete mode toggle
deleteButton.MouseButton1Click:Connect(function()
	local isDeleteMode = _G.GetDeleteMode and _G.GetDeleteMode() or false
	_G.SetDeleteMode(not isDeleteMode)

	if not isDeleteMode then
		deleteButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		_G.SetBuildMode(false)
		mainPanel.Visible = false
		toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		deleteButton.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
	end
end)

-- Close menu with ESC
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
		if mainPanel.Visible then
			mainPanel.Visible = false
			toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			_G.SetBuildMode(false)
		end
	end
end)