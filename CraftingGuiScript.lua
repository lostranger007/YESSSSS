-- StarterGui > CraftingGui > CraftingGuiScript (LocalScript)
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Wait for events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CraftItemEvent = RemoteEvents:WaitForChild("CraftItem")

-- GUI References
local screenGui = script.Parent
local craftingFrame = screenGui:WaitForChild("CraftingFrame")
local recipesScrollFrame = craftingFrame:WaitForChild("RecipesList")
local closeButton = craftingFrame:WaitForChild("CloseButton")
local titleLabel = craftingFrame:WaitForChild("Title")

-- Start hidden
craftingFrame.Visible = false

-- Load recipes from ReplicatedStorage
local function loadRecipes()
	local recipesFolder = ReplicatedStorage:WaitForChild("CraftingRecipes", 10)
	if not recipesFolder then
		warn("CraftingRecipes folder not found!")
		return {}
	end

	local recipes = {}
	for _, recipeValue in ipairs(recipesFolder:GetChildren()) do
		local success, recipeData = pcall(function()
			return HttpService:JSONDecode(recipeValue.Value)
		end)

		if success then
			recipeData.Key = recipeValue.Name
			table.insert(recipes, recipeData)
		end
	end

	-- Sort by order
	table.sort(recipes, function(a, b)
		return (a.Order or 999) < (b.Order or 999)
	end)

	return recipes
end

-- Check if player can afford recipe
local function canAffordRecipe(recipe)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return false end

	for material, amount in pairs(recipe.Materials) do
		local resource = inventory:FindFirstChild(material)
		if not resource or resource.Value < amount then
			return false
		end
	end

	return true
end

-- Create recipe button
local function createRecipeButton(recipe, yPosition)
	local button = Instance.new("TextButton")
	button.Name = recipe.Key
	button.Size = UDim2.new(1, -10, 0, 80)
	button.Position = UDim2.new(0, 5, 0, yPosition)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 2
	button.BorderColor3 = Color3.fromRGB(100, 100, 100)
	button.AutoButtonColor = false
	button.Parent = recipesScrollFrame

	-- Recipe name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.7, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = recipe.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.7, 0, 0.25, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = recipe.Description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = button

	-- Materials required
	local materialsText = "Requires: "
	local first = true
	for material, amount in pairs(recipe.Materials) do
		if not first then
			materialsText = materialsText .. ", "
		end
		materialsText = materialsText .. amount .. " " .. material
		first = false
	end

	local materialsLabel = Instance.new("TextLabel")
	materialsLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
	materialsLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
	materialsLabel.BackgroundTransparency = 1
	materialsLabel.Text = materialsText
	materialsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	materialsLabel.TextSize = 13
	materialsLabel.Font = Enum.Font.Gotham
	materialsLabel.TextXAlignment = Enum.TextXAlignment.Left
	materialsLabel.Parent = button

	-- Craft button
	local craftButton = Instance.new("TextButton")
	craftButton.Size = UDim2.new(0.2, 0, 0.6, 0)
	craftButton.Position = UDim2.new(0.75, 0, 0.2, 0)
	craftButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	craftButton.Text = "CRAFT"
	craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftButton.TextSize = 16
	craftButton.Font = Enum.Font.GothamBold
	craftButton.Parent = button

	-- Update button state based on affordability
	local function updateButton()
		if canAffordRecipe(recipe) then
			craftButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			craftButton.Text = "CRAFT"
			materialsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			craftButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			craftButton.Text = "NEED MORE"
			materialsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end

	updateButton()

	-- Craft button click
	craftButton.MouseButton1Click:Connect(function()
		if canAffordRecipe(recipe) then
			CraftItemEvent:FireServer(recipe.Key)
			task.wait(0.1)
			updateButton()
		end
	end)

	-- Update when inventory changes
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, resource in ipairs(inventory:GetChildren()) do
			if resource:IsA("IntValue") then
				resource.Changed:Connect(updateButton)
			end
		end
	end

	return button
end

-- Populate recipes
local function populateRecipes()
	-- Clear existing
	for _, child in ipairs(recipesScrollFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local recipes = loadRecipes()
	local yPos = 0

	for _, recipe in ipairs(recipes) do
		createRecipeButton(recipe, yPos)
		yPos = yPos + 85
	end

	recipesScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Open crafting menu
function openCraftingMenu()
	craftingFrame.Visible = true
	populateRecipes()
end

-- Close crafting menu
function closeCraftingMenu()
	craftingFrame.Visible = false
end

closeButton.MouseButton1Click:Connect(closeCraftingMenu)

-- Expose globally for crafting station to call
_G.OpenCraftingMenu = openCraftingMenu

print("Crafting GUI loaded!")