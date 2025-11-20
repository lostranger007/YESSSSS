-- StarterGui > LoadingScreen > LoadingScript (LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("Loading screen script started!")

-- Wait for remote event
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEventsFolder then
	warn("RemoteEvents folder not found in ReplicatedStorage!")
	return
end

local LoadingProgressEvent = RemoteEventsFolder:WaitForChild("LoadingProgress", 10)
if not LoadingProgressEvent then
	warn("LoadingProgress event not found!")
	return
end

print("Found LoadingProgress event!")

-- GUI References
local screenGui = script.Parent
local loadingFrame = screenGui:WaitForChild("LoadingFrame")
local progressBar = loadingFrame:WaitForChild("ProgressBar"):WaitForChild("Progress")
local progressText = loadingFrame:WaitForChild("ProgressText")
local titleText = loadingFrame:WaitForChild("TitleText")
local statusText = loadingFrame:WaitForChild("StatusText")

print("GUI elements found!")

-- Show loading screen
loadingFrame.Visible = true

-- Update progress
LoadingProgressEvent.OnClientEvent:Connect(function(progress)
	print("Received progress update:", progress)

	-- Update progress bar
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(progressBar, tweenInfo, {
		Size = UDim2.new(progress / 100, 0, 1, 0)
	})
	tween:Play()

	-- Update text
	progressText.Text = string.format("%.1f%%", progress)

	-- Update status
	if progress < 25 then
		statusText.Text = "Generating dirt layers..."
	elseif progress < 50 then
		statusText.Text = "Carving stone caverns..."
	elseif progress < 75 then
		statusText.Text = "Placing rare ores..."
	elseif progress < 95 then
		statusText.Text = "Adding deep materials..."
	else
		statusText.Text = "Finalizing world..."
	end

	-- When complete, fade out
	if progress >= 100 then
		task.wait(0.5)
		statusText.Text = "World ready! Dive in!"
		task.wait(1)

		-- Fade out animation
		local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local fadeTween = TweenService:Create(loadingFrame, fadeInfo, {
			BackgroundTransparency = 1
		})

		-- Fade all text elements
		TweenService:Create(titleText, fadeInfo, {TextTransparency = 1}):Play()
		TweenService:Create(statusText, fadeInfo, {TextTransparency = 1}):Play()
		TweenService:Create(progressText, fadeInfo, {TextTransparency = 1}):Play()
		TweenService:Create(progressBar, fadeInfo, {BackgroundTransparency = 1}):Play()
		TweenService:Create(progressBar.Parent, fadeInfo, {BackgroundTransparency = 1}):Play()

		fadeTween:Play()
		fadeTween.Completed:Wait()

		-- Remove loading screen
		screenGui:Destroy()
	end
end)

-- Timeout safety (in case server doesn't send updates)
task.delay(60, function()
	if loadingFrame.Visible then
		statusText.Text = "Loading timeout - rejoin if stuck"
		statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end)