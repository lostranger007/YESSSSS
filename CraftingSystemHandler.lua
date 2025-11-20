-- ServerScriptService > CraftingSystemHandler (Script)
-- Add this as a NEW script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Create crafting events
local OpenCraftingEvent = Instance.new("RemoteEvent")
OpenCraftingEvent.Name = "OpenCrafting"
OpenCraftingEvent.Parent = RemoteEvents

local CraftItemEvent = Instance.new("RemoteEvent")
CraftItemEvent.Name = "CraftItem"
CraftItemEvent.Parent = RemoteEvents

-- Crafting recipes
local RECIPES = {
	-- Pickaxes
	StonePickaxe = {
		Name = "Stone Pickaxe",
		Description = "Mines 2x faster",
		Materials = {Stone = 5, Dirt = 2},
		Category = "Tools",
		Order = 1
	},
	IronPickaxe = {
		Name = "Iron Pickaxe",
		Description = "Mines 3x faster",
		Materials = {IronOre = 5, Stone = 3},
		Category = "Tools",
		Order = 2
	},
	GoldPickaxe = {
		Name = "Gold Pickaxe",
		Description = "Mines 4x faster",
		Materials = {GoldOre = 5, IronOre = 3},
		Category = "Tools",
		Order = 3
	},
	DiamondPickaxe = {
		Name = "Diamond Pickaxe",
		Description = "Mines 5x faster!",
		Materials = {Diamond = 3, GoldOre = 5},
		Category = "Tools",
		Order = 4
	},

	-- Building Blocks
	IronFloor = {
		Name = "Iron Floor",
		Description = "Strong metal flooring",
		Materials = {IronOre = 3},
		Category = "Blocks",
		Order = 5
	},
	IronWall = {
		Name = "Iron Wall",
		Description = "Reinforced metal wall",
		Materials = {IronOre = 4},
		Category = "Blocks",
		Order = 6
	},
	GlassWall = {
		Name = "Glass Wall",
		Description = "Transparent wall",
		Materials = {Stone = 5, Dirt = 2},
		Category = "Blocks",
		Order = 7
	},

	-- Utility
	CraftingStation = {
		Name = "Crafting Station",
		Description = "Craft items and tools",
		Materials = {Dirt = 5, Stone = 5},
		Category = "Utility",
		Order = 8
	},
	Chest = {
		Name = "Storage Chest",
		Description = "Store extra items",
		Materials = {Dirt = 8},
		Category = "Utility",
		Order = 9
	},
	Lantern = {
		Name = "Lantern",
		Description = "Bright standing light",
		Materials = {IronOre = 2, Dirt = 1},
		Category = "Utility",
		Order = 10
	}
}

-- Check if player can afford recipe
local function canAfford(player, recipeKey)
	local recipe = RECIPES[recipeKey]
	if not recipe then return false end

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

-- Deduct materials
local function deductMaterials(player, recipeKey)
	local recipe = RECIPES[recipeKey]
	if not recipe then return end

	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	for material, amount in pairs(recipe.Materials) do
		local resource = inventory:FindFirstChild(material)
		if resource then
			resource.Value = resource.Value - amount
		end
	end
end

-- Give crafted item to player
local function giveItem(player, recipeKey)
	if recipeKey:find("Pickaxe") then
		-- Give pickaxe tool
		local tool = ReplicatedStorage:FindFirstChild(recipeKey)
		if tool then
			local toolClone = tool:Clone()
			toolClone.Parent = player.Backpack
			return true
		end
	elseif recipeKey == "CraftingStation" or recipeKey == "Chest" or recipeKey == "Lantern" then
		-- Add to inventory as placeable item
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemValue = inventory:FindFirstChild(recipeKey)
			if itemValue then
				itemValue.Value = itemValue.Value + 1
			else
				local newValue = Instance.new("IntValue")
				newValue.Name = recipeKey
				newValue.Value = 1
				newValue.Parent = inventory
			end
			return true
		end
	elseif recipeKey:find("Floor") or recipeKey:find("Wall") then
		-- Add building blocks to inventory
		local inventory = player:FindFirstChild("Inventory")
		if inventory then
			local itemValue = inventory:FindFirstChild(recipeKey)
			if itemValue then
				itemValue.Value = itemValue.Value + 1
			else
				local newValue = Instance.new("IntValue")
				newValue.Name = recipeKey
				newValue.Value = 1
				newValue.Parent = inventory
			end
			return true
		end
	end
	return false
end

-- Handle crafting request
CraftItemEvent.OnServerEvent:Connect(function(player, recipeKey)
	if not RECIPES[recipeKey] then 
		warn("Invalid recipe:", recipeKey)
		return 
	end

	if not canAfford(player, recipeKey) then
		warn(player.Name, "cannot afford", recipeKey)
		return
	end

	-- Deduct materials
	deductMaterials(player, recipeKey)

	-- Give item
	local success = giveItem(player, recipeKey)

	if success then
		print(player.Name, "crafted", recipeKey)

		-- Update inventory
		local UpdateInventoryEvent = RemoteEvents:FindFirstChild("UpdateInventory")
		if UpdateInventoryEvent then
			UpdateInventoryEvent:FireClient(player)
		end
	else
		warn("Failed to give item", recipeKey, "to", player.Name)
	end
end)

-- Send recipes to client when they open crafting
OpenCraftingEvent.OnServerEvent:Connect(function(player)
	-- Recipes are stored in ReplicatedStorage for client access
end)

-- Store recipes in ReplicatedStorage for client
local RecipesFolder = Instance.new("Folder")
RecipesFolder.Name = "CraftingRecipes"
RecipesFolder.Parent = ReplicatedStorage

for recipeKey, recipe in pairs(RECIPES) do
	local recipeValue = Instance.new("StringValue")
	recipeValue.Name = recipeKey
	recipeValue.Value = game:GetService("HttpService"):JSONEncode(recipe)
	recipeValue.Parent = RecipesFolder
end

print("Crafting System Handler loaded!")
print("Total recipes:", #RecipesFolder:GetChildren())