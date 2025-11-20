-- StarterPlayer > StarterPlayerScripts > CraftingClient (LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenCraftingEvent = RemoteEvents:WaitForChild("OpenCrafting")

-- Wait for global function
repeat task.wait() until _G.OpenCraftingMenu

-- Handle open crafting event
OpenCraftingEvent.OnClientEvent:Connect(function()
	_G.OpenCraftingMenu()
end)

print("Crafting Client loaded!")