--[[
https://endregion.vercel.app/
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function createInstance(className, properties)
	local inst = Instance.new(className)
	if properties then
		for prop, value in pairs(properties) do
			inst[prop] = value
		end
	end
	return inst
end

local EndRegionUI = {}
EndRegionUI.CategoryButtons = {}
EndRegionUI.CategoryFrames = {}
EndRegionUI.HighlightEnabled = false
EndRegionUI.FlyEnabled = false

function EndRegionUI:showNotification(message, duration)
	duration = duration or 2
	local success, err = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "EndRegion",
			Text = message,
			Duration = duration,
			button1 = "OK"
		})
	end)
	if not success then
		print("[EndRegion] Notification error: " .. tostring(err))
	else
		print("[EndRegion Notification] " .. message)
	end
end

function EndRegionUI:initUI()
	local screenGui = createInstance("ScreenGui", {Name = "EndRegionUI", ResetOnSpawn = false})
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 500, 0, 400),
		BorderSizePixel = 0,
	})
	mainFrame.Parent = screenGui
	mainFrame.Active = true
	mainFrame.Draggable = true
	createInstance("UICorner", {CornerRadius = UDim.new(0, 8)}).Parent = mainFrame
	
	local aspect = createInstance("UIAspectRatioConstraint", {
		AspectRatio = 500 / 400,
		AspectType = Enum.AspectType.ScaleWithParentSize,
		DominantAxis = Enum.DominantAxis.Width,
	})
	aspect.Parent = mainFrame
	
	-- Title frame with gradient and stroke
	local titleFrame = createInstance("Frame", {
		Name = "TitleFrame",
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(0, 350, 0, 50),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	titleFrame.Parent = mainFrame
	createInstance("UICorner", {CornerRadius = UDim.new(0, 6)}).Parent = titleFrame
	local titleGradient = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20)),
		}),
		Rotation = 45,
	})
	titleGradient.Parent = titleFrame
	local titleStroke = createInstance("UIStroke", {
		Color = Color3.fromRGB(80, 80, 100),
		Thickness = 2,
	})
	titleStroke.Parent = titleFrame
	local titleLabel = createInstance("TextLabel", {
		Name = "TitleLabel",
		Text = "EndRegion",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextColor3 = Color3.new(1, 1, 1),
	})
	titleLabel.Parent = titleFrame
	
	-- Close Button on Title (hides UI)
	local closeButton = createInstance("TextButton", {
		Name = "CloseButton",
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
		Size = UDim2.new(0, 30, 0, 30),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -5, 0, 5),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = closeButton
	closeButton.Parent = titleFrame
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		openButton.Visible = true
		print("[EndRegion] UI closed.")
	end)
	
	-- Open Button now appears at top center when hidden
	local openButton = createInstance("TextButton", {
		Name = "OpenButton",
		Text = "Open EndRegion",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		Size = UDim2.new(0, 200, 0, 40),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		Visible = true,
	})
	openButton.ZIndex = 10
	createInstance("UICorner", {CornerRadius = UDim.new(0, 6)}).Parent = openButton
	openButton.Parent = screenGui
	openButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		openButton.Visible = false
		print("[EndRegion] UI opened.")
	end)
	
	-- Categories Panel (left)
	local categoriesPanel = createInstance("Frame", {
		Name = "CategoriesPanel",
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		Position = UDim2.new(0, 0, 0, 70),
		Size = UDim2.new(0, 150, 1, -70),
		BorderSizePixel = 0,
	})
	categoriesPanel.Parent = mainFrame
	createInstance("UICorner", {CornerRadius = UDim.new(0, 6)}).Parent = categoriesPanel
	
	-- Content Area (for category UIs)
	local contentArea = createInstance("Frame", {
		Name = "ContentArea",
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Position = UDim2.new(0, 150, 0, 70),
		Size = UDim2.new(1, -150, 1, -70),
		BorderSizePixel = 0,
	})
	contentArea.Parent = mainFrame
	createInstance("UICorner", {CornerRadius = UDim.new(0, 6)}).Parent = contentArea
	
	-- Divider between panels
	local divider = createInstance("Frame", {
		Name = "Divider",
		BackgroundColor3 = Color3.fromRGB(80, 80, 80),
		Position = UDim2.new(0, 150, 0, 70),
		Size = UDim2.new(0, 2, 1, -70),
		BorderSizePixel = 0,
	})
	divider.Parent = mainFrame
	
	-- Create category frames (start off-screen right)
	local categoriesList = {"Home", "Settings", "Player Mods"}
	for _, cat in ipairs(categoriesList) do
		local catFrame = createInstance("Frame", {
			Name = cat .. "Frame",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(1, 0, 0, 0),
		})
		catFrame.Parent = contentArea
		EndRegionUI.CategoryFrames[cat] = catFrame
		catFrame.Visible = false
	end
	-- Immediately show Home category
	EndRegionUI.CategoryFrames["Home"].Position = UDim2.new(0, 0, 0, 0)
	EndRegionUI.CategoryFrames["Home"].Visible = true
	
	-- Build UIs for each category
	EndRegionUI:setupHomeCategory(EndRegionUI.CategoryFrames["Home"])
	EndRegionUI:setupSettingsCategory(EndRegionUI.CategoryFrames["Settings"], mainFrame)
	EndRegionUI:setupPlayerModsCategory(EndRegionUI.CategoryFrames["Player Mods"])
	
	-- Navigation Buttons (left panel)
	local buttonHeight = 36
	local buttonPadding = 10
	for index, catName in ipairs(categoriesList) do
		local catButton = createInstance("TextButton", {
			Name = catName .. "Button",
			Text = catName,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			BackgroundColor3 = Color3.fromRGB(55, 55, 55),
			Size = UDim2.new(1, -2 * buttonPadding, 0, buttonHeight),
			Position = UDim2.new(0, buttonPadding, 0, (index - 1) * (buttonHeight + buttonPadding) + buttonPadding),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1, 1, 1),
		})
		createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = catButton
		catButton.Parent = categoriesPanel
		EndRegionUI.CategoryButtons[catName] = catButton
		catButton.MouseEnter:Connect(function()
			TweenService:Create(catButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(75, 75, 75)}):Play()
		end)
		catButton.MouseLeave:Connect(function()
			TweenService:Create(catButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
		end)
		catButton.MouseButton1Click:Connect(function()
			EndRegionUI:switchCategory(catName)
		end)
	end
	
	-- Setup listeners for ESP (highlight) for future characters
	EndRegionUI:SetupHighlightListeners()
	EndRegionUI:showNotification("UI loaded successfully", 3)
end

-- Slide in the active category in 0.2 sec
function EndRegionUI:switchCategory(activeCategory)
	for cat, frame in pairs(EndRegionUI.CategoryFrames) do
		if cat == activeCategory then
			frame.Visible = true
			frame.Position = UDim2.new(1, 0, 0, 0)
			TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		else
			frame.Visible = false
		end
	end
end

function EndRegionUI:setupHomeCategory(homeFrame)
	local profileCard = createInstance("Frame", {
		Name = "ProfileCard",
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Size = UDim2.new(0, 300, 0, 150),
		Position = UDim2.new(0, 20, 0, 20),
		BorderSizePixel = 0,
	})
	profileCard.Parent = homeFrame
	createInstance("UICorner", {CornerRadius = UDim.new(0, 6)}).Parent = profileCard
	local cardGradient = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
		}),
		Rotation = 90,
	})
	cardGradient.Parent = profileCard
	
	local profilePic = createInstance("ImageLabel", {
		Name = "ProfilePic",
		Size = UDim2.new(0, 80, 0, 80),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BorderSizePixel = 0,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
	})
	profilePic.Parent = profileCard
	createInstance("UICorner", {CornerRadius = UDim.new(1, 0)}).Parent = profilePic
	local picStroke = createInstance("UIStroke", {Color = Color3.fromRGB(80, 80, 80), Thickness = 2})
	picStroke.Parent = profilePic
	
	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if success and thumbnail then
		profilePic.Image = thumbnail
	else
		print("[EndRegion] Failed to fetch profile picture for UserId " .. tostring(LocalPlayer.UserId))
	end
	
	local usernameLabel = createInstance("TextLabel", {
		Name = "Username",
		Text = LocalPlayer.Name,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 100, 0, 10),
		Size = UDim2.new(0, 180, 0, 30),
		TextColor3 = Color3.new(1, 1, 1),
	})
	usernameLabel.Parent = profileCard
	
	local displayNameLabel = createInstance("TextLabel", {
		Name = "DisplayName",
		Text = LocalPlayer.DisplayName or "N/A",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 100, 0, 45),
		Size = UDim2.new(0, 180, 0, 25),
		TextColor3 = Color3.fromRGB(200, 200, 200),
	})
	displayNameLabel.Parent = profileCard
	
	local userIDLabel = createInstance("TextLabel", {
		Name = "UserID",
		Text = "ID: " .. tostring(LocalPlayer.UserId),
		Font = Enum.Font.Gotham,
		TextScaled = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 100, 0, 75),
		Size = UDim2.new(0, 180, 0, 25),
		TextColor3 = Color3.fromRGB(150, 150, 150),
	})
	userIDLabel.Parent = profileCard
	
	local accountAge = LocalPlayer.AccountAge or 0
	if accountAge == 0 then
		print("[EndRegion] Account age returned as 0 days; revalidating data.")
	end
	local accountAgeLabel = createInstance("TextLabel", {
		Name = "AccountAge",
		Text = "Account Age: " .. tostring(accountAge) .. " days",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 100, 0, 105),
		Size = UDim2.new(0, 180, 0, 25),
		TextColor3 = Color3.fromRGB(150, 150, 150),
	})
	accountAgeLabel.Parent = profileCard
	
	local copyButton = createInstance("TextButton", {
		Name = "CopyButton",
		Text = "Copy Website URL",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(0, 170, 255),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 200, 0, 40),
		Position = UDim2.new(0, 20, 1, -60),
		BorderSizePixel = 0,
	})
	copyButton.Parent = homeFrame
	createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = copyButton
	local copyDebounce = false
	copyButton.MouseButton1Click:Connect(function()
		if copyDebounce then return end
		copyDebounce = true
		local success, errMsg = pcall(function() setclipboard("https://endregion.vercel.app/") end)
		if success then
			EndRegionUI:showNotification("Website URL copied successfully", 2)
		else
			print("[EndRegion] Failed to copy website URL: " .. tostring(errMsg))
		end
		task.wait(0.5)
		copyDebounce = false
	end)
end

function EndRegionUI:setupPlayerModsCategory(modsFrame)
	local scrollingFrame = createInstance("ScrollingFrame", {
		Name = "StatsScroller",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 8,
		ScrollingEnabled = true,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
	scrollingFrame.Parent = modsFrame
	local layout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	layout.Parent = scrollingFrame
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
	
	local stats = {
		{name = "Speed",      min = 10,  max = 300},
		{name = "Jump Power", min = 10,  max = 300},
		{name = "Gravity",    min = 10,  max = 300},
		{name = "Walk Speed", min = 10,  max = 300},
		{name = "Stamina",    min = 1,   max = 1000},
	}
	
	for index, stat in ipairs(stats) do
		local container = createInstance("Frame", {
			Name = stat.name .. "Container",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -40, 0, 48),
			LayoutOrder = index,
		})
		container.Parent = scrollingFrame
		local statButton = createInstance("TextButton", {
			Name = stat.name .. "Button",
			Text = stat.name,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			BackgroundColor3 = Color3.fromRGB(55, 55, 55),
			Size = UDim2.new(0, 140, 1, 0),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1, 1, 1),
		})
		createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = statButton
		statButton.Parent = container
		local inputBox = createInstance("TextBox", {
			Name = stat.name .. "Input",
			Text = "",
			PlaceholderText = "Enter (" .. stat.min .. "-" .. stat.max .. ")",
			Font = Enum.Font.Gotham,
			TextScaled = true,
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			Size = UDim2.new(0, 140, 1, 0),
			Position = UDim2.new(0, 150, 0, 0),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1, 1, 1),
		})
		createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = inputBox
		inputBox.Parent = container
		local debounce = false
		statButton.MouseButton1Click:Connect(function()
			if debounce then return end
			debounce = true
			local valid, num = EndRegionUI:validateInput(inputBox.Text, stat.min, stat.max)
			if valid then
				EndRegionUI:showNotification(stat.name .. " set to " .. tostring(num), 2)
			end
			task.wait(0.2)
			debounce = false
		end)
		inputBox.FocusLost:Connect(function()
			local valid, num = EndRegionUI:validateInput(inputBox.Text, stat.min, stat.max)
			if valid then
				inputBox.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
				EndRegionUI:showNotification(stat.name .. " set to " .. tostring(num), 2)
			else
				inputBox.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
				inputBox.Text = ""
				print("[EndRegion] Invalid input for " .. stat.name)
			end
		end)
	end
	
	-- ESP toggle container
	local toggleESPContainer = createInstance("Frame", {
		Name = "ToggleESPContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 48),
		LayoutOrder = #stats + 1,
	})
	toggleESPContainer.Parent = scrollingFrame
	local toggleESPButton = createInstance("TextButton", {
		Name = "ToggleESPButton",
		Text = "Toggle ESP",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		Size = UDim2.new(0, 140, 1, 0),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = toggleESPButton
	toggleESPButton.Parent = toggleESPContainer
	-- Add status label for ESP (right-aligned)
	local espStatusLabel = createInstance("TextLabel", {
		Name = "ESPStatusLabel",
		Text = "ESP: false",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(1, -100, 0, 0),
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	espStatusLabel.Parent = toggleESPContainer
	toggleESPButton.MouseButton1Click:Connect(function()
		EndRegionUI:ToggleHighlights()
		espStatusLabel.Text = "ESP: " .. tostring(EndRegionUI.HighlightEnabled)
	end)
	
	-- Mobile Fly toggle container
	local mobileFlyContainer = createInstance("Frame", {
		Name = "MobileFlyContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 48),
		LayoutOrder = #stats + 2,
	})
	mobileFlyContainer.Parent = scrollingFrame
	local mobileFlyButton = createInstance("TextButton", {
		Name = "MobileFlyButton",
		Text = "Mobile Fly",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		Size = UDim2.new(0, 140, 1, 0),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	createInstance("UICorner", {CornerRadius = UDim.new(0, 4)}).Parent = mobileFlyButton
	mobileFlyButton.Parent = mobileFlyContainer
	-- Fly status label, right-aligned
	local flyStatusLabel = createInstance("TextLabel", {
		Name = "FlyStatusLabel",
		Text = "Fly: false",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(1, -100, 0, 0),
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	flyStatusLabel.Parent = mobileFlyContainer
	EndRegionUI.FlyStatusLabel = flyStatusLabel
	
	mobileFlyButton.MouseButton1Click:Connect(function()
		EndRegionUI:ToggleFly()
	end)
end

function EndRegionUI:setupSettingsCategory(settingsFrame, mainFrame)
	local yOffset = 20
	local resizeLabel = createInstance("TextLabel", {
		Name = "ResizeLabel",
		Text = "UI Dimensions (min:500x400, max:1920x1080):",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, yOffset),
		Size = UDim2.new(0, 300, 0, 30),
		TextColor3 = Color3.new(1, 1, 1),
	})
	resizeLabel.Parent = settingsFrame
	yOffset = yOffset + 40
	local widthInput = createInstance("TextBox", {
		Name = "WidthInput",
		Text = "500",
		PlaceholderText = "Width",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(0, 20, 0, yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	widthInput.Parent = settingsFrame
	local heightInput = createInstance("TextBox", {
		Name = "HeightInput",
		Text = "400",
		PlaceholderText = "Height",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(0, 130, 0, yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	heightInput.Parent = settingsFrame
	yOffset = yOffset + 50
	local resizeButton = createInstance("TextButton", {
		Name = "ResizeButton",
		Text = "Resize UI",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(0, 170, 255),
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 120, 0, 30),
		Position = UDim2.new(0, 20, 0, yOffset),
		BorderSizePixel = 0,
	})
	resizeButton.Parent = settingsFrame
	resizeButton.MouseButton1Click:Connect(function()
		local newWidth = tonumber(widthInput.Text)
		local newHeight = tonumber(heightInput.Text)
		if newWidth and newHeight then
			if newWidth < 500 or newHeight < 400 or newWidth > 1920 or newHeight > 1080 then
				print("[EndRegion] Invalid UI dimensions: " .. newWidth .. "x" .. newHeight)
			else
				local mainF = settingsFrame.Parent.Parent:FindFirstChild("MainFrame")
				if mainF then
					mainF.Size = UDim2.new(0, newWidth, 0, newHeight)
					EndRegionUI:showNotification("UI resized to " .. newWidth .. "x" .. newHeight, 2)
				else
					print("[EndRegion] MainFrame not found for resizing.")
				end
			end
		else
			print("[EndRegion] Non-numeric input for dimensions.")
		end
	end)
	yOffset = yOffset + 50
	local resetPosButton = createInstance("TextButton", {
		Name = "ResetPosButton",
		Text = "Reset Position",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		Size = UDim2.new(0, 140, 0, 30),
		Position = UDim2.new(0, 20, 0, yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
	})
	resetPosButton.Parent = settingsFrame
	resetPosButton.MouseButton1Click:Connect(function()
		local mainF = settingsFrame.Parent.Parent:FindFirstChild("MainFrame")
		if mainF then
			mainF.Position = UDim2.new(0.5, 0, 0.5, 0)
			print("[EndRegion] UI reset to centered position.")
		else
			print("[EndRegion] MainFrame not found for UI reset.")
		end
	end)
end

function EndRegionUI:validateInput(inputValue, minVal, maxVal)
	local num = tonumber(inputValue)
	if not num then
		print("[EndRegion] Invalid input (not a number): " .. tostring(inputValue))
		return false, nil
	elseif num < minVal or num > maxVal then
		print("[EndRegion] Input " .. num .. " out of bounds (" .. minVal .. "-" .. maxVal .. ")")
		return false, num
	end
	return true, num
end

-- ESP functions (used for highlighting players)
function EndRegionUI:ToggleHighlights()
	self.HighlightEnabled = not self.HighlightEnabled
	if self.HighlightEnabled then
		print("[EndRegion] ESP turned ON")
		self:showNotification("ESP ON", 2)
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Character then
				self:EnableHighlight(player.Character)
			end
		end
	else
		print("[EndRegion] ESP turned OFF")
		self:showNotification("ESP OFF", 2)
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Character then
				self:DisableHighlight(player.Character)
			end
		end
	end
end

function EndRegionUI:EnableHighlight(character)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if head then
		if not head:FindFirstChild("UsernameBillboard") then
			local billboard = createInstance("BillboardGui", {
				Name = "UsernameBillboard",
				Adornee = head,
				Size = UDim2.new(0, 100, 0, 50),
				StudsOffset = Vector3.new(0, 2, 0),
				AlwaysOnTop = true,
			})
			local textLabel = createInstance("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = character.Name,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
			})
			textLabel.Parent = billboard
			billboard.Parent = head
		end
	end
	if not character:FindFirstChild("PlayerHighlight") then
		local hl = createInstance("Highlight", {
			Name = "PlayerHighlight",
			FillColor = Color3.new(1, 1, 1),
			OutlineColor = Color3.new(1, 1, 1),
			Enabled = true,
		})
		hl.Parent = character
	end
end

function EndRegionUI:DisableHighlight(character)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if head and head:FindFirstChild("UsernameBillboard") then
		head.UsernameBillboard:Destroy()
	end
	local hl = character:FindFirstChild("PlayerHighlight")
	if hl then
		hl:Destroy()
	end
end

function EndRegionUI:SetupHighlightListeners()
	for _, player in pairs(game.Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			if self.HighlightEnabled then
				self:EnableHighlight(char)
			end
		end)
	end
	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			if self.HighlightEnabled then
				self:EnableHighlight(char)
			end
		end)
	end)
end

-- Mobile Fly (bad i know, I'm a newbie.)
function EndRegionUI:ToggleFly()
	self.FlyEnabled = not self.FlyEnabled
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart
		if self.FlyEnabled then
			local bv = createInstance("BodyVelocity", {
				Name = "FlyVelocity",
				MaxForce = Vector3.new(1e5, 1e5, 1e5),
				Velocity = hrp.CFrame.LookVector * 20 + Vector3.new(0, 10, 0),
				Parent = hrp,
			})
			local bg = createInstance("BodyGyro", {
				Name = "FlyGyro",
				MaxTorque = Vector3.new(0, 400000, 0),
				CFrame = hrp.CFrame,
				Parent = hrp,
			})
			self:showNotification("Mobile Fly enabled", 2)
			if self.FlyStatusLabel then
				self.FlyStatusLabel.Text = "Fly: true"
			end
		else
			if hrp:FindFirstChild("FlyVelocity") then
				hrp.FlyVelocity:Destroy()
			end
			if hrp:FindFirstChild("FlyGyro") then
				hrp.FlyGyro:Destroy()
			end
			self:showNotification("Mobile Fly disabled", 2)
			if self.FlyStatusLabel then
				self.FlyStatusLabel.Text = "Fly: false"
			end
		end
	end
end

EndRegionUI:initUI()
return EndRegionUI