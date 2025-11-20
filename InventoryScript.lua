-- StarterGui > InventoryGui > InventoryScript (LocalScript)
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for remote events
local UpdateInventoryEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateInventory")

-- GUI References
local screenGui = script.Parent
local inventoryFrame = screenGui:WaitForChild("InventoryFrame")
local itemsList = inventoryFrame:WaitForChild("ItemsList")
local titleLabel = inventoryFrame:WaitForChild("Title")

-- Start collapsed
local isOpen = true
inventoryFrame.Visible = false

-- Create toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "InventoryToggle"
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0.01, 0, 0.02, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleButton.BorderSizePixel = 2
toggleButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
toggleButton.Text = "?? INVENTORY"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 18
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

-- Toggle function
toggleButton.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	inventoryFrame.Visible = isOpen

	if isOpen then
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		toggleButton.Text = "?? INVENTORY ?"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		toggleButton.Text = "?? INVENTORY"
	end
end)

-- Resource colors for visual feedback
local RESOURCE_COLORS = {
	Dirt = Color3.fromRGB(139, 90, 43),
	Stone = Color3.fromRGB(163, 162, 165),
	IronOre = Color3.fromRGB(226, 155, 64),
	DeepStone = Color3.fromRGB(99, 95, 98),
	GoldOre = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(0, 191, 255)
}

-- Create or update inventory display
local function updateInventory()
	-- Clear current items
	for _, child in ipairs(itemsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	local yPosition = 0

	-- Display each resource
	for _, resource in ipairs(inventory:GetChildren()) do
		if resource:IsA("IntValue") then
			local itemFrame = Instance.new("Frame")
			itemFrame.Name = resource.Name
			itemFrame.Size = UDim2.new(1, -10, 0, 40)
			itemFrame.Position = UDim2.new(0, 5, 0, yPosition)
			itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			itemFrame.BorderSizePixel = 0
			itemFrame.Parent = itemsList

			-- Resource color indicator
			local colorBox = Instance.new("Frame")
			colorBox.Size = UDim2.new(0, 30, 0, 30)
			colorBox.Position = UDim2.new(0, 5, 0.5, -15)
			colorBox.BackgroundColor3 = RESOURCE_COLORS[resource.Name] or Color3.fromRGB(255, 255, 255)
			colorBox.BorderSizePixel = 2
			colorBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
			colorBox.Parent = itemFrame

			-- Resource name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, -45, 1, 0)
			nameLabel.Position = UDim2.new(0, 40, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = resource.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 18
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Parent = itemFrame

			-- Resource amount
			local amountLabel = Instance.new("TextLabel")
			amountLabel.Size = UDim2.new(0.3, 0, 1, 0)
			amountLabel.Position = UDim2.new(0.7, 0, 0, 0)
			amountLabel.BackgroundTransparency = 1
			amountLabel.Text = tostring(resource.Value)
			amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			amountLabel.TextSize = 20
			amountLabel.TextXAlignment = Enum.TextXAlignment.Right
			amountLabel.Font = Enum.Font.GothamBold
			amountLabel.Parent = itemFrame

			-- Update amount when value changes
			resource.Changed:Connect(function()
				amountLabel.Text = tostring(resource.Value)

				-- Pulse animation on change
				amountLabel.TextSize = 24
				task.wait(0.1)
				amountLabel.TextSize = 20
			end)

			yPosition = yPosition + 45
		end
	end

	-- Update canvas size
	itemsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
end

-- Initial update
task.wait(1) -- Wait for inventory to be created
updateInventory()

-- Update when server tells us to
UpdateInventoryEvent.OnClientEvent:Connect(updateInventory)

-- Update periodically as backup
while true do
	task.wait(2)
	updateInventory()
end