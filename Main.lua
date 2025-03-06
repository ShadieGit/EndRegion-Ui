local function FineInstance(className, properties)
	local inst = Instance.new(className)
	if properties then
		for prop, value in pairs(properties) do
			pcall(function() inst[prop] = value end)
		end
	end
	return inst
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local EndRegionUI = {}
EndRegionUI.CategoryButtons = {}
EndRegionUI.CategoryFrames = {}
EndRegionUI.HighlightEnabled = false
EndRegionUI.SpinEnabled = false
EndRegionUI.HighlightTheme = "light"

function EndRegionUI:showNotification(message, duration)
	if message:find("UI loaded successfully") then
		pcall(function() StarterGui:SetCore("SendNotification", {Title = "EndRegion", Text = tostring(message), Duration = duration or 2, Button1 = "OK"}) end)
		print("[EndRegion] " .. tostring(message))
	else
		print("[EndRegion] " .. tostring(message))
	end
end

local function AutoSpace(parent, margin)
	margin = margin or 10
	local offset = margin
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Position = UDim2.new(child.Position.X.Scale, margin, child.Position.Y.Scale, offset)
			offset = offset + child.AbsoluteSize.Y + margin
		end
	end
end

function EndRegionUI:applyStat(statName, value)
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if statName == "Jump Power" and humanoid then
		humanoid.JumpPower = value
	elseif statName == "Gravity" then
		workspace.Gravity = value
	elseif statName == "Walk Speed" and humanoid then
		humanoid.WalkSpeed = value
	elseif statName == "Hip Height" and humanoid then
		humanoid.HipHeight = value
	elseif statName == "Camera FOV" then
		workspace.CurrentCamera.FieldOfView = value
	end
	print("[EndRegion] " .. statName .. " set to " .. tostring(value))
end

function EndRegionUI:initUI()
	local screenGui = FineInstance("ScreenGui", {Name = "EndRegionUI", ResetOnSpawn = false})
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	local mainFrame = FineInstance("Frame", {
		Name = "MainFrame",
		BackgroundColor3 = Color3.fromRGB(30,30,30),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(0,800,0,600),
		BorderSizePixel = 0,
	})
	mainFrame.Parent = screenGui
	mainFrame.Active = true
	mainFrame.Draggable = true
	FineInstance("UICorner", {CornerRadius = UDim.new(0,8)}).Parent = mainFrame
	
	local aspect = FineInstance("UIAspectRatioConstraint", {
		AspectRatio = 800/600,
		AspectType = Enum.AspectType.ScaleWithParentSize,
		DominantAxis = Enum.DominantAxis.Width,
	})
	aspect.Parent = mainFrame
	
	local titleFrame = FineInstance("Frame", {
		Name = "TitleFrame",
		BackgroundColor3 = Color3.fromRGB(15,15,15),
		Position = UDim2.new(0.5,0,0,10),
		Size = UDim2.new(0,500,0,50),
		AnchorPoint = Vector2.new(0.5,0),
	})
	titleFrame.Parent = mainFrame
	FineInstance("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = titleFrame
	local titleGradient = FineInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,20))
		}),
		Rotation = 45,
	})
	titleGradient.Parent = titleFrame
	local titleStroke = FineInstance("UIStroke", {Color = Color3.fromRGB(80,80,100), Thickness = 2})
	titleStroke.Parent = titleFrame
	local titleLabel = FineInstance("TextLabel", {
		Name = "TitleLabel",
		Text = "EndRegion",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 18,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		TextColor3 = Color3.new(1,1,1)
	})
	FineInstance("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1}).Parent = titleLabel
	titleLabel.Parent = titleFrame
	
	local openButton = FineInstance("TextButton", {
		Name = "OpenButton",
		Text = "Open",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 16,
		BackgroundColor3 = Color3.fromRGB(15,15,15),
		Size = UDim2.new(0,100,0,40),
		AnchorPoint = Vector2.new(0.5,0),
		Position = UDim2.new(0.5,0,0,10),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1),
		Visible = true
	})
	openButton.ZIndex = 10
	FineInstance("UICorner", {CornerRadius = UDim.new(0,8)}).Parent = openButton
	openButton.Parent = screenGui
	openButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		openButton.Visible = false
		print("[EndRegion] UI opened.")
	end)
	
	local closeButton = FineInstance("TextButton", {
		Name = "CloseButton",
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 16,
		BackgroundColor3 = Color3.fromRGB(200,50,50),
		Size = UDim2.new(0,30,0,30),
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-5,0,5),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1)
	})
	FineInstance("UICorner", {CornerRadius = UDim.new(0,15)}).Parent = closeButton
	closeButton.Parent = titleFrame
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		openButton.Visible = true
		print("[EndRegion] UI closed.")
	end)
	
	local categoriesPanel = FineInstance("Frame", {
		Name = "CategoriesPanel",
		BackgroundColor3 = Color3.fromRGB(40,40,40),
		Position = UDim2.new(0,0,0,70),
		Size = UDim2.new(0,220,1,-70),
		BorderSizePixel = 0
	})
	categoriesPanel.Parent = mainFrame
	FineInstance("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = categoriesPanel
	
	local contentArea = FineInstance("Frame", {
		Name = "ContentArea",
		BackgroundColor3 = Color3.fromRGB(35,35,35),
		Position = UDim2.new(0,220,0,70),
		Size = UDim2.new(1,-220,1,-70),
		BorderSizePixel = 0
	})
	contentArea.Parent = mainFrame
	FineInstance("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = contentArea
	
	local divider = FineInstance("Frame", {
		Name = "Divider",
		BackgroundColor3 = Color3.fromRGB(80,80,80),
		Position = UDim2.new(0,220,0,70),
		Size = UDim2.new(0,2,1,-70),
		BorderSizePixel = 0
	})
	divider.Parent = mainFrame
	
	local categoriesList = {"Home","Settings","Player Mods"}
	for _, cat in ipairs(categoriesList) do
		local catFrame = FineInstance("Frame", {
			Name = cat .. "Frame",
			BackgroundTransparency = 1,
			Size = UDim2.new(1,0,1,0),
			Position = UDim2.new(1,0,0,0)
		})
		catFrame.Parent = contentArea
		self.CategoryFrames[cat] = catFrame
		catFrame.Visible = false
	end
	self.CategoryFrames["Home"].Position = UDim2.new(0,0,0,0)
	self.CategoryFrames["Home"].Visible = true
	
	self:setupHomeCategory(self.CategoryFrames["Home"])
	self:setupSettingsCategory(self.CategoryFrames["Settings"], mainFrame)
	self:setupPlayerModsCategory(self.CategoryFrames["Player Mods"])
	
	local BUTTON_HEIGHT = 24
	local BUTTON_PADDING = 12
	for index, catName in ipairs(categoriesList) do
		local catButton = FineInstance("TextButton", {
			Name = catName .. "Button",
			Text = catName,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(55,55,55),
			Size = UDim2.new(1, -2 * BUTTON_PADDING, 0, BUTTON_HEIGHT),
			Position = UDim2.new(0, BUTTON_PADDING, 0, (index-1)*(BUTTON_HEIGHT+BUTTON_PADDING) + BUTTON_PADDING),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1,1,1)
		})
		FineInstance("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = catButton
		catButton.Parent = categoriesPanel
		self.CategoryButtons[catName] = catButton
		catButton.MouseEnter:Connect(function()
			TweenService:Create(catButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(75,75,75)}):Play()
		end)
		catButton.MouseLeave:Connect(function()
			TweenService:Create(catButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55,55,55)}):Play()
		end)
		catButton.MouseButton1Click:Connect(function() self:switchCategory(catName) end)
	end
	
	self:SetupHighlightListeners()
	self:showNotification("UI loaded successfully", 3)
end

function EndRegionUI:switchCategory(activeCategory)
	for cat, frame in pairs(self.CategoryFrames) do
		if frame then
			if cat == activeCategory then
				frame.Visible = true
				frame.Position = UDim2.new(1,0,0,0)
				TweenService:Create(frame, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
			else
				frame.Visible = false
			end
		else
			print("[EndRegion] Missing frame for category: " .. tostring(cat))
		end
	end
end

function EndRegionUI:setupHomeCategory(homeFrame)
	local profileCard = FineInstance("Frame", {
		Name = "ProfileCard",
		BackgroundColor3 = Color3.fromRGB(35,35,35),
		Size = UDim2.new(0,250,0,150),
		Position = UDim2.new(0,20,0,20),
		BorderSizePixel = 0
	})
	profileCard.Parent = homeFrame
	FineInstance("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = profileCard
	local cardGradient = FineInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30,30,40))
		}),
		Rotation = 90
	})
	cardGradient.Parent = profileCard
	local profilePic = FineInstance("ImageLabel", {
		Name = "ProfilePic",
		Size = UDim2.new(0,80,0,80),
		Position = UDim2.new(0,10,0,10),
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		BorderSizePixel = 0,
		Image = "",
		ScaleType = Enum.ScaleType.Crop
	})
	profilePic.Parent = profileCard
	FineInstance("UICorner", {CornerRadius = UDim.new(1,0)}).Parent = profilePic
	local picStroke = FineInstance("UIStroke", {Color = Color3.fromRGB(80,80,80), Thickness = 2})
	picStroke.Parent = profilePic
	local success, thumbnail = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
	if success and thumbnail then
		profilePic.Image = thumbnail
	else
		print("[EndRegion] Failed to fetch profile picture for UserId " .. tostring(LocalPlayer.UserId))
		profilePic.Image = "rbxassetid://123456789"
	end
	local usernameLabel = FineInstance("TextLabel", {
		Name = "Username",
		Text = LocalPlayer.Name,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 14,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,180,0,30),
		Position = UDim2.new(0,100,0,10),
		TextColor3 = Color3.new(1,1,1)
	})
	FineInstance("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1}).Parent = usernameLabel
	usernameLabel.Parent = profileCard
	local displayNameLabel = FineInstance("TextLabel", {
		Name = "DisplayName",
		Text = LocalPlayer.DisplayName or "N/A",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextSize = 12,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,180,0,25),
		Position = UDim2.new(0,100,0,45),
		TextColor3 = Color3.fromRGB(200,200,200)
	})
	local dispStroke = FineInstance("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1})
	dispStroke.Parent = displayNameLabel
	displayNameLabel.Parent = profileCard
	local userIDLabel = FineInstance("TextLabel", {
		Name = "UserID",
		Text = "ID: " .. tostring(LocalPlayer.UserId),
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextSize = 12,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,180,0,25),
		Position = UDim2.new(0,100,0,75),
		TextColor3 = Color3.fromRGB(150,150,150)
	})
	local idStroke = FineInstance("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1})
	idStroke.Parent = userIDLabel
	userIDLabel.Parent = profileCard
end

function EndRegionUI:setupPlayerModsCategory(modsFrame)
	local scrollingFrame = FineInstance("ScrollingFrame", {
		Name = "StatsScroller",
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		ScrollBarThickness = 8,
		ScrollingEnabled = true,
		CanvasSize = UDim2.new(0,0,0,0)
	})
	scrollingFrame.Parent = modsFrame
	local layout = FineInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	layout.Parent = scrollingFrame
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 8)
	end)
	local stats = {
		{name = "Jump Power", min = 10, max = 300},
		{name = "Gravity", min = 10, max = 300},
		{name = "Walk Speed", min = 10, max = 300},
		{name = "Hip Height", min = 0, max = 10},
		{name = "Camera FOV", min = 70, max = 120}
	}
	for index, stat in ipairs(stats) do
		local container = FineInstance("Frame", {
			Name = stat.name .. "Container",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -40, 0, 35),
			LayoutOrder = index
		})
		container.Parent = scrollingFrame
		local statButton = FineInstance("TextButton", {
			Name = stat.name .. "Button",
			Text = stat.name,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(55,55,55),
			Size = UDim2.new(0,120,1,0),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1,1,1)
		})
		FineInstance("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = statButton
		statButton.Parent = container
		local inputBox = FineInstance("TextBox", {
			Name = stat.name .. "Input",
			Text = "",
			PlaceholderText = "Enter (" .. stat.min .. "-" .. stat.max .. ")",
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(60,60,60),
			Size = UDim2.new(0,120,1,0),
			Position = UDim2.new(0,130,0,0),
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1,1,1)
		})
		FineInstance("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = inputBox
		inputBox.Parent = container
		statButton.MouseButton1Click:Connect(function()
			local valid, num = EndRegionUI:validateInput(inputBox.Text, stat.min, stat.max)
			if valid then
				EndRegionUI:applyStat(stat.name, num)
			end
		end)
		inputBox.FocusLost:Connect(function()
			local valid, num = EndRegionUI:validateInput(inputBox.Text, stat.min, stat.max)
			if valid then
				inputBox.BackgroundColor3 = Color3.fromRGB(0,100,0)
				EndRegionUI:applyStat(stat.name, num)
			else
				inputBox.BackgroundColor3 = Color3.fromRGB(100,0,0)
				inputBox.Text = ""
				print("[EndRegion] Invalid input for " .. stat.name)
			end
		end)
	end
	local spinContainer = FineInstance("Frame", {
		Name = "SpinContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 35),
		LayoutOrder = #stats + 1
	})
	spinContainer.Parent = scrollingFrame
	local spinButton = FineInstance("TextButton", {
		Name = "SpinButton",
		Text = "Spin",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(55,55,55),
		Size = UDim2.new(0,120,1,0),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1)
	})
	FineInstance("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = spinButton
	spinButton.Parent = spinContainer
	spinButton.MouseButton1Click:Connect(function()
		EndRegionUI:ToggleSpin()
	end)
end

function EndRegionUI:setupSettingsCategory(settingsFrame, mainFrame)
	local yOffset = 20
	local resizeLabel = FineInstance("TextLabel", {
		Name = "ResizeLabel",
		Text = "UI Dimensions (min:500x400, max:1920x1080):",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0,300,0,30),
		Position = UDim2.new(0,20,0,yOffset),
		TextColor3 = Color3.new(1,1,1)
	})
	resizeLabel.Parent = settingsFrame
	yOffset = yOffset + 40
	local widthInput = FineInstance("TextBox", {
		Name = "WidthInput",
		Text = "500",
		PlaceholderText = "Width",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		Size = UDim2.new(0,100,0,30),
		Position = UDim2.new(0,20,0,yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1)
	})
	widthInput.Parent = settingsFrame
	local heightInput = FineInstance("TextBox", {
		Name = "HeightInput",
		Text = "400",
		PlaceholderText = "Height",
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		Size = UDim2.new(0,100,0,30),
		Position = UDim2.new(0,130,0,yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1)
	})
	heightInput.Parent = settingsFrame
	yOffset = yOffset + 50
	local resizeButton = FineInstance("TextButton", {
		Name = "ResizeButton",
		Text = "Resize UI",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(0,170,255),
		TextColor3 = Color3.new(1,1,1),
		Size = UDim2.new(0,120,0,30),
		Position = UDim2.new(0,20,0,yOffset),
		BorderSizePixel = 0
	})
	resizeButton.Parent = settingsFrame
	resizeButton.MouseButton1Click:Connect(function()
		local newWidth = tonumber(widthInput.Text)
		local newHeight = tonumber(heightInput.Text)
		if newWidth and newHeight and newWidth >= 500 and newHeight >= 400 and newWidth <= 1920 and newHeight <= 1080 then
			if mainFrame then
				mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
				print("[EndRegion] UI resized to " .. newWidth .. "x" .. newHeight)
			else
				print("[EndRegion] MainFrame not found for resizing.")
			end
		else
			print("[EndRegion] Invalid or out-of-bound UI dimensions.")
		end
	end)
	yOffset = yOffset + 50
	local resetPosButton = FineInstance("TextButton", {
		Name = "ResetPosButton",
		Text = "Reset Position",
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(55,55,55),
		Size = UDim2.new(0,140,0,30),
		Position = UDim2.new(0,20,0,yOffset),
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1,1,1)
	})
	resetPosButton.Parent = settingsFrame
	resetPosButton.MouseButton1Click:Connect(function()
		if mainFrame then
			mainFrame.Position = UDim2.new(0.5,0,0.5,0)
			print("[EndRegion] UI reset to centered position.")
		else
			print("[EndRegion] MainFrame not found for UI reset.")
		end
	end)
end

function EndRegionUI:validateInput(inputValue, minVal, maxVal)
	local num = tonumber(inputValue)
	if num and num >= minVal and num <= maxVal then
		return true, num
	end
	return false, num
end

function EndRegionUI:ToggleHighlights()
	self.HighlightEnabled = not self.HighlightEnabled
	print("[EndRegion] ESP toggled: " .. tostring(self.HighlightEnabled))
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character then
			local char = player.Character
			local head = char:FindFirstChild("Head")
			if self.HighlightEnabled then
				if head and not head:FindFirstChild("UsernameBillboard") then
					local billboard = FineInstance("BillboardGui", {
						Name = "UsernameBillboard",
						Adornee = head,
						Size = UDim2.new(0,100,0,50),
						StudsOffset = Vector3.new(0,2,0),
						AlwaysOnTop = true
					})
					local textLabel = FineInstance("TextLabel", {
						Size = UDim2.new(1,0,1,0),
						BackgroundTransparency = 1,
						Text = char.Name,
						TextColor3 = Color3.new(1,1,1),
						Font = Enum.Font.GothamBold,
						TextScaled = true,
						TextSize = 14
					})
					textLabel.Parent = billboard
					billboard.Parent = head
				end
				if not char:FindFirstChild("PlayerHighlight") then
					local hl = FineInstance("Highlight", {
						Name = "PlayerHighlight",
						FillColor = Color3.new(1,1,1),
						OutlineColor = Color3.new(1,1,1),
						Enabled = true
					})
					hl.Parent = char
				end
			else
				if head and head:FindFirstChild("UsernameBillboard") then
					head.UsernameBillboard:Destroy()
				end
				local hl = char:FindFirstChild("PlayerHighlight")
				if hl then hl:Destroy() end
			end
		end
	end
end

function EndRegionUI:SetupHighlightListeners()
	for _, player in pairs(game.Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			self:SetHighlight(char, self.Highlightchar, self.HighlightEnabled)
		end)
	end
	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			self:SetHighlight(char, self.HighlightEnabled)
		end)
	end)
end

function EndRegionUI:SetHighlight(character, state)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if state then
		if head and not head:FindFirstChild("UsernameBillboard") then
			local billboard = FineInstance("BillboardGui", {
				Name = "UsernameBillboard",
				Adornee = head,
				Size = UDim2.new(0, 100, 0, 50),
				StudsOffset = Vector3.new(0, 2, 0),
				AlwaysOnTop = true
			})
			local textLabel = FineInstance("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = character.Name,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextSize = 14
			})
			textLabel.Parent = billboard
			billboard.Parent = head
		end
		if not character:FindFirstChild("PlayerHighlight") then
			local hl = FineInstance("Highlight", {
				Name = "PlayerHighlight",
				FillColor = Color3.new(1, 1, 1),
				OutlineColor = Color3.new(1, 1, 1),
				Enabled = true
			})
			hl.Parent = character
		end
	else
		if head and head:FindFirstChild("UsernameBillboard") then
			head.UsernameBillboard:Destroy()
		end
		local hl = character:FindFirstChild("PlayerHighlight")
		if hl then hl:Destroy() end
	end
end

function EndRegionUI:ToggleSpin()
	self.SpinEnabled = not self.SpinEnabled
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if self.SpinEnabled then
		local bav = hrp:FindFirstChild("SpinAngularVelocity") or Instance.new("BodyAngularVelocity", hrp)
		bav.Name = "SpinAngularVelocity"
		bav.MaxTorque = Vector3.new(0, 1e6, 0)
		bav.AngularVelocity = Vector3.new(0, 5, 0)
		print("[EndRegion] Spin enabled")
	else
		if hrp:FindFirstChild("SpinAngularVelocity") then
			hrp.SpinAngularVelocity:Destroy()
		end
		print("[EndRegion] Spin disabled")
	end
end

EndRegionUI:initUI()

return EndRegionUI