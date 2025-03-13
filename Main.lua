local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local function httpGet(url)
	local success, result = pcall(function() return game:HttpGet(url) end)
	return success and result or nil
end

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
assert(localPlayer, "LocalPlayer not found!")

local function createObject(className, properties)
	local obj = Instance.new(className)
	if properties then
		for prop, val in pairs(properties) do
			pcall(function() obj[prop] = val end)
		end
	end
	return obj
end

local ShadieUI = {}
ShadieUI.version = "3.1"
ShadieUI.localSignature = "SUI_SIGNATURE:3.1_Live"
ShadieUI.errorLog = {}
ShadieUI.espObjects = {}
ShadieUI.highlightObjects = {}
ShadieUI.categoryButtons = {}
ShadieUI.categoryFrames = {}
ShadieUI.categoryCounters = {}
ShadieUI.highlightsActive = false
ShadieUI.espEnabled = false
ShadieUI.spinEnabled = false
ShadieUI.noclipEnabled = false
ShadieUI.bunnyHopEnabled = false
ShadieUI.infinityJumpEnabled = false
ShadieUI.platformStandEnabled = false
ShadieUI.spinSpeed = 5
ShadieUI.dayNightCycleActive = false
ShadieUI.dayNightConnection = nil
ShadieUI.debounceBusy = false
ShadieUI.updateAvailable = false
ShadieUI.updateApplied = false
ShadieUI.updatePromptShown = false
ShadieUI.currentJumpCount = 0

function ShadieUI:logError(msg)
	table.insert(self.errorLog, {time = os.time(), error = msg})
	warn("Error:", msg)
end

function ShadieUI:notify(title, text, duration)
	title = title or "ShadieUI"
	duration = duration or 2
	pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration}) end)
	print("[" .. title .. "] " .. text)
end

function ShadieUI:checkInput(value, minValue, maxValue)
	local num = tonumber(value)
	if num and num >= minValue and num <= maxValue then
		return true, num
	end
	return false, num
end

function ShadieUI:createCategory(name)
	assert(type(name) == "string" and name ~= "", "Invalid category name!")
	local btn = createObject("TextButton", {Name = name.."Btn", Text = name, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
	local grad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 90})
	grad.Parent = btn
	btn.Parent = self.categoriesPanel
	self.categoryButtons[name] = btn
	self.categoryCounters[name] = 0
	btn.MouseButton1Click:Connect(function() self:switchCategory(name) end)
	local frame = createObject("ScrollingFrame", {Name = name.."Frame", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingEnabled = true})
	local layout = createObject("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	layout.Parent = frame
	frame.Parent = self.contentArea
	self.categoryFrames[name] = frame
	frame.Visible = false
end

function ShadieUI:createItem(name, category, hasInput, callback)
	assert(type(name) == "string" and name ~= "", "Invalid item name")
	assert(type(category) == "string" and category ~= "", "Invalid category")
	assert(type(hasInput) == "boolean", "hasInput must be boolean")
	assert(type(callback) == "function", "Callback must be a function")
	local parent = self.categoryFrames[category]
	if not parent then
		self:notify("Error", "Category '"..category.."' missing", 2)
		return
	end
	local container = createObject("Frame", {Name = name.."Container", Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, BorderSizePixel = 0})
	container.LayoutOrder = self.categoryCounters[category] or 0
	self.categoryCounters[category] = self.categoryCounters[category] + 1
	container.Parent = parent
	local btn = createObject("TextButton", {Name = name.."Button", Text = name, Size = UDim2.new(0,140,1,0), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(80,80,80), Font = Enum.Font.Gotham, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
	local grad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 90})
	grad.Parent = btn
	btn.Parent = container
	if hasInput then
		local input = createObject("TextBox", {Name = name.."Input", Text = "", PlaceholderText = "Enter value", PlaceholderColor3 = Color3.fromRGB(150,150,150), Size = UDim2.new(0,120,1,0), Position = UDim2.new(0,150,0,0), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), Font = Enum.Font.Gotham, TextScaled = true, TextColor3 = Color3.fromRGB(240,240,240), BorderSizePixel = 0})
		input.Parent = container
		btn.MouseButton1Click:Connect(function()
			local text = input.Text
			if text == "" then
				self:notify("Input Error", "Enter a value", 2)
			else
				callback(text)
			end
		end)
	else
		btn.MouseButton1Click:Connect(callback)
	end
end

function ShadieUI:initializeUI()
	local pg = localPlayer:WaitForChild("PlayerGui")
	local sg = createObject("ScreenGui", {Name = "ShadieUI_Main", ResetOnSpawn = false})
	sg.Parent = pg
	self.screenGui = sg
	local mainFrame = createObject("Frame", {Name = "MainFrame", Size = UDim2.new(0,700,0,400), Position = UDim2.new(0.5,-350,0.5,-200), BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, Active = true, Draggable = true})
	mainFrame.Parent = sg
	self.mainFrame = mainFrame
	local mainGrad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 45})
	mainGrad.Parent = mainFrame
	local titleFrame = createObject("Frame", {Name = "TitleFrame", Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(20,20,20), BorderSizePixel = 0})
	titleFrame.Parent = mainFrame
	local titleLabel = createObject("TextLabel", {Name = "TitleLabel", Text = "ShadieUI", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
	local titleGrad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 45})
	titleGrad.Parent = titleLabel
	titleLabel.Parent = titleFrame
	local toggleBtn = createObject("TextButton", {Name = "ToggleButton", Text = "O", Size = UDim2.new(0,50,0,50), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Position = UDim2.new(0,10,0,10)})
	local toggleGrad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 45})
	toggleGrad.Parent = toggleBtn
	local roundCorner = createObject("UICorner", {CornerRadius = UDim.new(1,0)})
	roundCorner.Parent = toggleBtn
	toggleBtn.Parent = sg
	toggleBtn.MouseButton1Click:Connect(function()
		if self.mainFrame.Visible then
			self:playClosingAnim()
		else
			self.mainFrame.Visible = true
			self:playOpeningAnim()
		end
	end)
	local categoriesPanel = createObject("ScrollingFrame", {Name = "CategoriesPanel", Size = UDim2.new(0,180,0,mainFrame.Size.Y.Offset - 36), Position = UDim2.new(0,0,0,36), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingEnabled = true})
	local cp = createObject("UIPadding", {PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)})
	cp.Parent = categoriesPanel
	local clayout = createObject("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	clayout.Parent = categoriesPanel
	categoriesPanel.Parent = mainFrame
	self.categoriesPanel = categoriesPanel
	local contentArea = createObject("Frame", {Name = "ContentArea", Size = UDim2.new(1,-180,1,-36), Position = UDim2.new(0,180,0,36), BackgroundTransparency = 1, BorderSizePixel = 0})
	local conCrn = createObject("UICorner", {CornerRadius = UDim.new(0,8)})
	conCrn.Parent = contentArea
	contentArea.Parent = mainFrame
	self.contentArea = contentArea
end

function ShadieUI:initializeCategories()
	local cats = {"Home","Local","Player","Workspace","Backpack","Advanced"}
	for _, cat in ipairs(cats) do
		self:createCategory(cat)
	end
	self:switchCategory("Home")
end

function ShadieUI:switchCategory(name)
	if self.categoryFrames and self.categoryFrames[name] then
		for cat, frame in pairs(self.categoryFrames) do
			frame.Visible = (cat == name)
		end
	else
		self:notify("Error", "Category '" .. tostring(name) .. "' not found", 2)
	end
end

function ShadieUI:SetTitle(newTitle)
	assert(type(newTitle) == "string" and newTitle ~= "", "Invalid title!")
	local titleFrame = self.mainFrame and self.mainFrame:FindFirstChild("TitleFrame")
	if titleFrame then
		local titleLabel = titleFrame:FindFirstChild("TitleLabel")
		if titleLabel then
			titleLabel.Text = newTitle
		end
	end
end

function ShadieUI:playOpeningAnim()
	local frame = self.mainFrame
	if not frame then return end
	frame.Size = UDim2.new(0,350,0,200)
	frame.BackgroundTransparency = 1
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0,700,0,400), BackgroundTransparency = 0.3})
	tween:Play()
end

function ShadieUI:playClosingAnim()
	local frame = self.mainFrame
	if not frame then return end
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0,350,0,200), BackgroundTransparency = 1})
	tween:Play()
	tween.Completed:Connect(function()
		frame.Visible = false
	end)
end

function ShadieUI:setupHome()
	local frame = self.categoryFrames["Home"]
	if not frame then return end
	local card = createObject("Frame", {Name = "ProfileCard", Size = UDim2.new(1, -16, 0, 250), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30,30,30), BorderSizePixel = 0})
	local grad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,40))}), Rotation = 45})
	grad.Parent = card
	local crn = createObject("UICorner", {CornerRadius = UDim.new(0,12)})
	crn.Parent = card
	card.Parent = frame
	local pic = createObject("ImageLabel", {Name = "ProfilePic", Size = UDim2.new(0,80,0,80), Position = UDim2.new(0,10,0,10), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20,20,20), BorderSizePixel = 0, Image = ""})
	local picCrn = createObject("UICorner", {CornerRadius = UDim.new(1,0)})
	picCrn.Parent = pic
	pic.Parent = card
	local ok, thumb = pcall(function() return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
	if ok and thumb then
		pic.Image = thumb
	else
		pic.Image = "rbxassetid://1"
	end
	local info = createObject("Frame", {Name = "InfoFrame", Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,100,0,10), BackgroundTransparency = 1, BorderSizePixel = 0})
	info.Parent = card
	local list = createObject("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
	list.Parent = info
	local function addInfo(text)
		local lbl = createObject("TextLabel", {Text = text, Font = Enum.Font.Gotham, TextScaled = true, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1,0,0,30), BorderSizePixel = 0})
		local tgrad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(192,192,192))}), Rotation = 45})
		tgrad.Parent = lbl
		lbl.Parent = info
	end
	spawn(function()
		while wait(1) do
			if frame and frame.Parent then
				for _, child in ipairs(info:GetChildren()) do
					if child:IsA("TextLabel") then child:Destroy() end
				end
				addInfo("Username: " .. localPlayer.Name)
				addInfo("Display Name: " .. (localPlayer.DisplayName or "N/A"))
				addInfo("UserID: " .. tostring(localPlayer.UserId))
				addInfo("Premium: " .. (localPlayer.MembershipType == Enum.MembershipType.Premium and "Yes" or "No"))
				if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
					local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
					addInfo("Health: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth))
					addInfo("WalkSpeed: " .. humanoid.WalkSpeed)
					addInfo("JumpPower: " .. humanoid.JumpPower)
				end
			else break end
		end
	end)
	if self.updateAvailable and not self.updateApplied then self:showUpdatePrompt() end
end

function ShadieUI:setupLocal()
	local frame = self.categoryFrames["Local"]
	if not frame then return end
	self:createItem("Set Walk Speed", "Local", true, function(value)
		local speed = tonumber(value)
		if speed then
			local character = localPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = speed
					self:notify("Local", "Walk Speed set to " .. speed, 2)
				end
			end
		else
			self:notify("Local", "Invalid speed value", 2)
		end
	end)
	self:createItem("Set Jump Power", "Local", true, function(value)
		local jump = tonumber(value)
		if jump then
			local character = localPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.JumpPower = jump
					self:notify("Local", "Jump Power set to " .. jump, 2)
				end
			end
		else
			self:notify("Local", "Invalid jump power", 2)
		end
	end)
	self:createItem("Set Gravity", "Local", true, function(value)
		local valid, num = self:checkInput(value, 0, 10000)
		if valid then
			Workspace.Gravity = num
			self:notify("Local", "Gravity set to " .. num, 2)
		else
			self:notify("Local", "Invalid gravity value", 2)
		end
	end)
	self:createItem("Set Hip Height", "Local", true, function(value)
		local hip = tonumber(value)
		if hip then
			local character = localPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.HipHeight = hip
					self:notify("Local", "Hip Height set to " .. hip, 2)
				end
			end
		else
			self:notify("Local", "Invalid hip height", 2)
		end
	end)
	self:createItem("NoClip", "Local", false, function()
		self.noclipEnabled = not self.noclipEnabled
		self:notify("Local", "NoClip " .. (self.noclipEnabled and "Enabled" or "Disabled"), 2)
	end)
	self:createItem("Spin", "Local", true, function(value)
		if value and value ~= "" then
			local newSpeed = tonumber(value)
			if newSpeed then
				self.spinSpeed = newSpeed
				if self.spinEnabled and self.spinObject then
					self.spinObject.AngularVelocity = Vector3.new(0, newSpeed, 0)
				end
				self:notify("Local", "Spin speed set to " .. newSpeed, 2)
			else
				self:notify("Local", "Invalid spin speed", 2)
				return
			end
		end
		self:toggleSpin()
	end)
	self:createItem("Platform Stand", "Local", false, function()
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.PlatformStand = not humanoid.PlatformStand
				self:notify("Local", "Platform Stand " .. (humanoid.PlatformStand and "Enabled" or "Disabled"), 2)
			end
		end
	end)
	self:createItem("Bunny Hop", "Local", false, function()
		self.bunnyHopEnabled = not self.bunnyHopEnabled
		self:notify("Local", "Bunny Hop " .. (self.bunnyHopEnabled and "Enabled" or "Disabled"), 2)
	end)
	self:createItem("Infinity Jump", "Local", false, function()
		self.infinityJumpEnabled = not self.infinityJumpEnabled
		self:notify("Local", "Infinity Jump " .. (self.infinityJumpEnabled and "Enabled" or "Disabled"), 2)
	end)
	self:createItem("Reset Stats", "Local", false, function()
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
		end
		Workspace.Gravity = 196.2
		self:notify("Local", "Stats Reset", 2)
	end)
	self:createItem("Respawn", "Local", false, function()
		if localPlayer.Character then
			localPlayer.Character:BreakJoints()
			self:notify("Local", "Respawn triggered", 2)
		end
	end)
	self:createItem("Play Animation", "Local", true, function(animId)
		self:playAnimation(animId)
	end)
end

function ShadieUI:setupPlayer()
	local frame = self.categoryFrames["Player"]
	if not frame then return end
	self:createItem("ESP", "Player", false, function()
		self.espEnabled = not self.espEnabled
		if not self.espEnabled then
			for name, esp in pairs(self.espObjects) do
				if esp.box then esp.box:Remove() end
				if esp.tracer then esp.tracer:Remove() end
				if esp.label then esp.label:Remove() end
			end
			self.espObjects = {}
		end
		self:notify("Player", "ESP " .. (self.espEnabled and "Enabled" or "Disabled"), 2)
	end)
	self:createItem("Highlights", "Player", false, function()
		self.highlightsActive = not self.highlightsActive
		if self.highlightsActive then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= localPlayer and p.Character then
					if not p.Character:FindFirstChild("Highlight") then
						local hl = Instance.new("Highlight")
						hl.FillColor = Color3.new(0,1,0)
						hl.OutlineColor = Color3.new(1,1,1)
						hl.Parent = p.Character
						self.highlightObjects[p.Name] = hl
					end
				end
			end
			self:notify("Player", "Highlights Enabled", 2)
		else
			for _, hl in pairs(self.highlightObjects) do
				if hl then hl:Destroy() end
			end
			self.highlightObjects = {}
			self:notify("Player", "Highlights Disabled", 2)
		end
	end)
	self:createItem("Teleport Random", "Player", false, function()
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(targets, p)
			end
		end
		if #targets > 0 then
			local target = targets[math.random(1, #targets)]
			if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				localPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
				self:notify("Player", "Teleported to " .. target.Name, 2)
			end
		else
			self:notify("Player", "No target found", 2)
		end
	end)
	self:createItem("Teleport Behind", "Player", false, function()
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(targets, p)
			end
		end
		if #targets > 0 then
			local target = targets[math.random(1, #targets)]
			if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = target.Character.HumanoidRootPart
				local newPos = hrp.Position - hrp.CFrame.LookVector * 5
				localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(newPos)
				self:notify("Player", "Teleported behind " .. target.Name, 2)
			end
		else
			self:notify("Player", "No target found", 2)
		end
	end)
end

function ShadieUI:setupWorkspace()
	local frame = self.categoryFrames["Workspace"]
	if not frame then return end
	self:createItem("Day-Night Cycle", "Workspace", false, function()
		if not self.dayNightCycleActive then
			self:startDayNightCycle()
			self:notify("Workspace", "Day-Night Cycle Started", 2)
		else
			self:stopDayNightCycle()
			self:notify("Workspace", "Day-Night Cycle Stopped", 2)
		end
	end)
	self:createItem("Gravity", "Workspace", true, function(value)
		local valid, num = self:checkInput(value, 0, 10000)
		if valid then
			Workspace.Gravity = num
			self:notify("Workspace", "Gravity set to " .. num, 2)
		else
			self:notify("Workspace", "Invalid gravity value", 2)
		end
	end)
	self:createItem("Camera FOV", "Workspace", true, function(value)
		local fov = tonumber(value)
		if fov then
			local cam = Workspace.CurrentCamera
			if cam then
				cam.FieldOfView = fov
				self:notify("Workspace", "FOV set to " .. fov, 2)
			end
		else
			self:notify("Workspace", "Invalid FOV", 2)
		end
	end)
	self:createItem("Camera Min Zoom", "Workspace", true, function(value)
		local minZoom = tonumber(value)
		if minZoom then
			local cam = Workspace.CurrentCamera
			if cam then
				cam.CameraMinZoomDistance = minZoom
				self:notify("Workspace", "Min Zoom set to " .. minZoom, 2)
			end
		else
			self:notify("Workspace", "Invalid Min Zoom", 2)
		end
	end)
	self:createItem("Camera Max Zoom", "Workspace", true, function(value)
		local maxZoom = tonumber(value)
		if maxZoom then
			local cam = Workspace.CurrentCamera
			if cam then
				cam.CameraMaxZoomDistance = maxZoom
				self:notify("Workspace", "Max Zoom set to " .. maxZoom, 2)
			end
		else
			self:notify("Workspace", "Invalid Max Zoom", 2)
		end
	end)
end

function ShadieUI:setupBackpack()
	local frame = self.categoryFrames["Backpack"]
	if not frame then return end
	self:createItem("Steal Items", "Backpack", false, function()
		local stolen, withTools, withoutTools = 0, 0, 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer then
				local bp = p:FindFirstChild("Backpack")
				local foundTool = false
				if bp then
					for _, tool in ipairs(bp:GetChildren()) do
						if tool:IsA("Tool") then
							tool.Parent = localPlayer.Backpack
							stolen = stolen + 1
							foundTool = true
						end
					end
				end
				if p.Character then
					for _, tool in ipairs(p.Character:GetChildren()) do
						if tool:IsA("Tool") then
							tool.Parent = localPlayer.Backpack
							stolen = stolen + 1
							foundTool = true
						end
					end
				end
				if foundTool then
					withTools = withTools + 1
				else
					withoutTools = withoutTools + 1
				end
			end
		end
		if stolen > 0 then
			self:notify("Backpack", "Stolen " .. stolen .. " items from " .. withTools .. " players", 2)
		else
			self:notify("Backpack", "No tools stolen (" .. withoutTools .. " without tools)", 2)
		end
	end)
	self:createItem("Equip All", "Backpack", false, function()
		if localPlayer.Backpack and #localPlayer.Backpack:GetChildren() > 0 then
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
					if tool:IsA("Tool") then
						humanoid:EquipTool(tool)
					end
				end
				self:notify("Backpack", "Equipped all tools", 2)
			end
		else
			self:notify("Backpack", "No tools in Backpack", 2)
		end
	end)
	self:createItem("Clear Backpack", "Backpack", false, function()
		local count = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
				count = count + 1
			end
		end
		if count > 0 then
			self:notify("Backpack", "Cleared " .. count .. " tools", 2)
		else
			self:notify("Backpack", "Backpack is empty", 2)
		end
	end)
	self:createItem("Drop All", "Backpack", false, function()
		local count = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:FindFirstChild("Handle") then
					tool.Parent = Workspace
					local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrp and tool:FindFirstChild("Handle") then
						tool.Handle.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5),5,math.random(-5,5))
					end
				else
					tool.Parent = Workspace
				end
				count = count + 1
			end
		end
		if count > 0 then
			self:notify("Backpack", "Dropped " .. count .. " tools", 2)
		else
			self:notify("Backpack", "No tools to drop", 2)
		end
	end)
	self:createItem("Duplicate All", "Backpack", false, function()
		local count = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local dup = tool:Clone()
				dup.Parent = localPlayer.Backpack
				count = count + 1
			end
		end
		self:notify("Backpack", "Duplicated " .. count .. " tools", 2)
	end)
end

function ShadieUI:setupAdvanced()
	local frame = self.categoryFrames["Advanced"]
	if not frame then return end
	self:createItem("Console Logs", "Advanced", false, function()
		for _, log in ipairs(self.errorLog) do
			print(os.date("%X", log.time), log.error)
		end
		self:notify("Advanced", "Console logs printed", 2)
	end)
end

function ShadieUI:toggleSpin()
	self.spinEnabled = not self.spinEnabled
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if self.spinEnabled then
		if not self.spinObject then
			self.spinObject = createObject("BodyAngularVelocity", {Parent = hrp, Name = "SpinAV"})
		end
		self.spinObject.MaxTorque = Vector3.new(0, 1e6, 0)
		self.spinObject.AngularVelocity = Vector3.new(0, self.spinSpeed, 0)
	else
		if self.spinObject then
			self.spinObject:Destroy()
			self.spinObject = nil
		end
	end
	if not self._lastSpinToggle or tick() - self._lastSpinToggle > 1 then
		self._lastSpinToggle = tick()
		self:notify("Local", "Spin " .. (self.spinEnabled and ("Enabled (Speed: " .. self.spinSpeed .. ")") or "Disabled"), 2)
	end
end

function ShadieUI:startDayNightCycle()
	if self.dayNightCycleActive then return end
	self.dayNightCycleActive = true
	local lastTick = tick()
	self.dayNightConnection = RunService.RenderStepped:Connect(function()
		local now = tick()
		local dt = now - lastTick
		lastTick = now
		Lighting.ClockTime = (Lighting.ClockTime + dt * 0.1) % 24
		if Lighting.ClockTime >= 6 and Lighting.ClockTime < 18 then
			Lighting.Brightness = 1.2
			Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
			Lighting.ColorShift_Top = Color3.fromRGB(210,210,255)
			Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
		elseif Lighting.ClockTime >= 18 and Lighting.ClockTime < 22 then
			Lighting.Brightness = 0.8
			Lighting.OutdoorAmbient = Color3.fromRGB(100,100,130)
			Lighting.ColorShift_Top = Color3.fromRGB(90,90,110)
			Lighting.ColorShift_Bottom = Color3.fromRGB(80,80,100)
		else
			Lighting.Brightness = 0.5
			Lighting.OutdoorAmbient = Color3.fromRGB(50,50,70)
			Lighting.ColorShift_Top = Color3.fromRGB(40,40,60)
			Lighting.ColorShift_Bottom = Color3.fromRGB(30,30,50)
		end
	end)
end

function ShadieUI:stopDayNightCycle()
	if self.dayNightCycleActive and self.dayNightConnection then
		self.dayNightConnection:Disconnect()
		self.dayNightCycleActive = false
	end
end

function ShadieUI:playAnimation(animId)
	if not localPlayer.Character then return self:notify("Animation", "Character unavailable", 2) end
	local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return self:notify("Animation", "Humanoid unavailable", 2) end
	local animNum = tonumber(animId)
	if not animNum then return self:notify("Animation", "Invalid animation ID", 2) end
	local anim = createObject("Animation", {AnimationId = "rbxassetid://" .. animId})
	local track = humanoid:LoadAnimation(anim)
	local ok = pcall(function() track:Play() end)
	if not ok then
		self:notify("Animation", "Failed to play animation", 2)
	else
		self:notify("Animation", "Playing " .. animId, 2)
	end
end

function ShadieUI:checkForUpdates()
	spawn(function()
		local url = "https://raw.githubusercontent.com/ShadieGit/Shadie-Ui/refs/heads/main/Main.lua"
		local result = httpGet(url)
		if result then
			local remoteSignature = result:match("SUI_SIGNATURE:(%S+)")
			if remoteSignature and remoteSignature ~= self.localSignature and not self.updateApplied then
				self.updateAvailable = true
				self.remoteCode = result
				self:notify("Update", "New update available", 5)
				wait(1)
				if self.categoryFrames["Home"] then
					self:showUpdatePrompt()
				end
			end
		end
	end)
end

function ShadieUI:showUpdatePrompt()
	if self.updatePromptShown or self.updateApplied then return end
	self.updatePromptShown = true
	local frame = self.categoryFrames["Home"]
	if not frame then return end
	local prompt = createObject("Frame", {Name = "UpdatePrompt", Size = UDim2.new(1, -16, 0, 100), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(50,50,50), BorderSizePixel = 0})
	local grad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)), ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))}), Rotation = 45})
	grad.Parent = prompt
	local crn = createObject("UICorner", {CornerRadius = UDim.new(0,8)})
	crn.Parent = prompt
	prompt.Parent = frame
	local label = createObject("TextLabel", {Text = "Update detected. Restart the script?", Size = UDim2.new(1,0,0.6,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
	label.Parent = prompt
	local btn = createObject("TextButton", {Text = "Restart", Size = UDim2.new(0,100,0,40), Position = UDim2.new(0.5, -50, 0.65, 0), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(200,50,50), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0})
	btn.Parent = prompt
	btn.MouseButton1Click:Connect(function()
		self:applyUpdate()
	end)
end

function ShadieUI:applyUpdate()
	if self.screenGui then self.screenGui:Destroy() end
	self.updateApplied = true
	self:notify("Update", "Updating... please wait.", 3)
	local success, func = pcall(loadstring, self.remoteCode)
	if success and func then
		func()
	else
		self:notify("Update", "Failed to update.", 3)
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(character)
		if self.highlightsActive and p ~= localPlayer then
			if not character:FindFirstChild("Highlight") then
				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.new(0,1,0)
				hl.OutlineColor = Color3.new(1,1,1)
				hl.Parent = character
				self.highlightObjects[p.Name] = hl
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	if self.highlightObjects[p.Name] then
		self.highlightObjects[p.Name]:Destroy()
		self.highlightObjects[p.Name] = nil
	end
end)

local function updateESP()
	if ShadieUI.espEnabled then
		local myHead = localPlayer.Character and localPlayer.Character:FindFirstChild("Head")
		local myPos = myHead and myHead.Position
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer and p.Character and p.Character:FindFirstChild("Head") then
				local otherHead = p.Character.Head
				local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(otherHead.Position)
				if onscreen then
					if not ShadieUI.espObjects[p.Name] then
						local box = Drawing.new("Square")
						box.Visible = true
						box.Thickness = 2
						box.Filled = false
						local tracer = Drawing.new("Line")
						tracer.Visible = true
						tracer.Thickness = 1
						local label = Drawing.new("Text")
						label.Visible = true
						label.Text = p.Name
						label.Size = 20
						label.Font = 2
						ShadieUI.espObjects[p.Name] = {box = box, tracer = tracer, label = label}
					end
					local esp = ShadieUI.espObjects[p.Name]
					local color = Color3.fromRGB(255,0,0)
					if myPos then
						local dot = otherHead.CFrame.LookVector:Dot((myPos - otherHead.Position).Unit)
						if dot > 0.95 then color = Color3.new(1,1,1) end
					end
					esp.box.Color = color
					esp.box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
					esp.box.Size = Vector2.new(50,50)
					esp.tracer.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y)
					esp.tracer.To = Vector2.new(pos.X, pos.Y)
					esp.label.Position = Vector2.new(pos.X, pos.Y - 30)
					esp.box.Visible = true
					esp.tracer.Visible = true
					esp.label.Visible = true
				else
					if ShadieUI.espObjects[p.Name] then
						ShadieUI.espObjects[p.Name].box.Visible = false
						ShadieUI.espObjects[p.Name].tracer.Visible = false
						ShadieUI.espObjects[p.Name].label.Visible = false
					end
				end
			end
		end
	else
		for _, esp in pairs(ShadieUI.espObjects) do
			if esp.box then esp.box:Remove() end
			if esp.tracer then esp.tracer:Remove() end
			if esp.label then esp.label:Remove() end
		end
		ShadieUI.espObjects = {}
	end
end

RunService.Heartbeat:Connect(updateESP)

RunService.RenderStepped:Connect(function()
	local character = localPlayer.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			if ShadieUI.noclipEnabled then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end
		if ShadieUI.bunnyHopEnabled then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Landed then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
end)

local function resetJump(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			ShadieUI.currentJumpCount = 0
		end
	end)
end

local function onCharacterAdded(character)
	resetJump(character)
	ShadieUI.spinEnabled = false
	ShadieUI.noclipEnabled = false
	ShadieUI.bunnyHopEnabled = false
	ShadieUI.infinityJumpEnabled = false
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
	resetJump(localPlayer.Character)
	ShadieUI.spinEnabled = false
	ShadieUI.noclipEnabled = false
	ShadieUI.bunnyHopEnabled = false
	ShadieUI.infinityJumpEnabled = false
end

UserInputService.JumpRequest:Connect(function()
	if ShadieUI.infinityJumpEnabled then
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
end)

VirtualUser:CaptureController()
localPlayer.Idled:Connect(function() pcall(function() VirtualUser:ClickButton2(Vector2.new(0,0)) end) end)

ShadieUI:initializeUI()
ShadieUI:initializeCategories()
ShadieUI:setupHome()
ShadieUI:setupLocal()
ShadieUI:setupPlayer()
ShadieUI:setupWorkspace()
ShadieUI:setupBackpack()
ShadieUI:setupAdvanced()
ShadieUI:notify("ShadieUI", "Loaded Successfully", 3)
ShadieUI:checkForUpdates()

return ShadieUI