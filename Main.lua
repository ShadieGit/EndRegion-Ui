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

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
assert(player, "LocalPlayer not found!")

local function createInstance(className, props)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			pcall(function() inst[k] = v end)
		end
	end
	return inst
end

local UI = {}
UI.version = "4.0"
UI.signature = "SUI_SIGNATURE:4.0_Live"
UI.errors = {}
UI.highlights = {}
UI.espElements = {}
UI.categoryButtons = {}
UI.categoryFrames = {}
UI.categoryOrder = {}
UI.features = {ESP = false, Spin = false, NoClip = false, BunnyHop = false, InfinityJump = false, Highlights = false, DayNightCycle = false}
UI.lastNotifs = {}
UI.lastBunnyTime = 0
UI.spinSpeed = 5
UI.remoteCode = nil
UI.updateAvailable = false
UI.updateApplied = false
UI.updatePromptShown = false
UI.featureCallbacks = {}

function UI:flipFeature(feature)
	self.features[feature] = not self.features[feature]
	if self.featureCallbacks[feature] then
		if self.features[feature] and self.featureCallbacks[feature].on then
			self.featureCallbacks[feature].on(self)
		elseif not self.features[feature] and self.featureCallbacks[feature].off then
			self.featureCallbacks[feature].off(self)
		end
	end
	self:notify("Local", feature .. " " .. (self.features[feature] and "Enabled" or "Disabled"), 2)
end

UI.featureCallbacks["Spin"] = {
	on = function(self)
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if not self.spinBody then
				self.spinBody = Instance.new("BodyAngularVelocity")
				self.spinBody.Name = "SpinAV"
				self.spinBody.Parent = hrp
			end
			self.spinBody.MaxTorque = Vector3.new(0, 1e6, 0)
			self.spinBody.AngularVelocity = Vector3.new(0, self.spinSpeed, 0)
		end
	end,
	off = function(self)
		if self.spinBody then
			self.spinBody:Destroy()
			self.spinBody = nil
		end
	end,
}

function UI:logError(msg)
	table.insert(self.errors, {time = os.time(), error = msg})
	warn("Error:", msg)
end

function UI:notify(title, text, duration)
	title = title or "UI"
	duration = duration or 2
	local now = tick()
	self.lastNotifs = self.lastNotifs or {}
	local key = title .. ":" .. text
	if self.lastNotifs[key] and (now - self.lastNotifs[key] < duration) then
		return
	end
	self.lastNotifs[key] = now
	pcall(function()
		StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration})
	end)
	print("[" .. title .. "] " .. text)
end

function UI:checkInput(value, minVal, maxVal)
	local num = tonumber(value)
	if num and num >= minVal and num <= maxVal then
		return true, num
	end
	return false, num
end

function UI:createCategory(catName)
	assert(type(catName) == "string" and catName ~= "", "Invalid category name!")
	local btn = createInstance("TextButton", {
		Name = catName.."Btn",
		Text = catName,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0,
	})
	local grad = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40,40,40))
		}),
		Rotation = 90
	})
	grad.Parent = btn
	local stroke = createInstance("UIStroke", {Color = Color3.fromRGB(100,100,100), Thickness = 1})
	stroke.Parent = btn
	local corner = createInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
	corner.Parent = btn
	btn.Parent = self.catPanel
	self.categoryButtons[catName] = btn
	self.categoryOrder[catName] = 0
	btn.MouseButton1Click:Connect(function() self:switchCategory(catName) end)
	local frame = createInstance("ScrollingFrame", {
		Name = catName.."Frame",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingEnabled = true,
		BackgroundColor3 = Color3.fromRGB(30,30,30)
	})
	local layout = createInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	layout.Parent = frame
	frame.Parent = self.contentArea
	self.categoryFrames[catName] = frame
	frame.Visible = false
end

function UI:createItem(itemName, cat, hasInput, action)
	assert(type(itemName) == "string" and itemName ~= "", "Invalid item name")
	assert(type(cat) == "string" and cat ~= "", "Invalid category")
	assert(type(hasInput) == "boolean", "hasInput must be boolean")
	assert(type(action) == "function", "Callback must be a function")
	local parent = self.categoryFrames[cat]
	if not parent then
		self:notify("Error", "Category '"..cat.."' missing", 2)
		return
	end
	local container = createInstance("Frame", {
		Name = itemName.."Container",
		Size = UDim2.new(1,0,0,50),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(45,45,45),
		BorderSizePixel = 0
	})
	local cCorner = createInstance("UICorner", {CornerRadius = UDim.new(0, 8)})
	cCorner.Parent = container
	local cStroke = createInstance("UIStroke", {Color = Color3.fromRGB(70,70,70), Thickness = 1})
	cStroke.Parent = container
	container.LayoutOrder = self.categoryOrder[cat] or 0
	self.categoryOrder[cat] = self.categoryOrder[cat] + 1
	container.Parent = parent
	local btn = createInstance("TextButton", {
		Name = itemName.."Button",
		Text = itemName,
		Size = UDim2.new(0,140,1,0),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(65,65,65),
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0
	})
	local btnGrad = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100,100,100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,50))
		}),
		Rotation = 45
	})
	btnGrad.Parent = btn
	local btnCorner = createInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
	btnCorner.Parent = btn
	local btnStroke = createInstance("UIStroke", {Color = Color3.fromRGB(120,120,120), Thickness = 1})
	btnStroke.Parent = btn
	btn.Parent = container
	if hasInput then
		local input = createInstance("TextBox", {
			Name = itemName.."Input",
			Text = "",
			PlaceholderText = "Enter value",
			PlaceholderColor3 = Color3.fromRGB(160,160,160),
			Size = UDim2.new(0,150,1,-10),
			Position = UDim2.new(0,150,0,5),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(40,40,40),
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(240,240,240),
			BorderSizePixel = 0
		})
		local inpCorner = createInstance("UICorner", {CornerRadius = UDim.new(0, 6)})
		inpCorner.Parent = input
		local inpStroke = createInstance("UIStroke", {Color = Color3.fromRGB(80,80,80), Thickness = 1})
		inpStroke.Parent = input
		local inpGrad = createInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30,30,30))
			}),
			Rotation = 90
		})
		inpGrad.Parent = input
		input.Parent = container
		btn.MouseButton1Click:Connect(function()
			local text = input.Text
			if text == "" then
				self:notify("Input Error", "Enter a value", 2)
			else
				action(text)
			end
		end)
	else
		btn.MouseButton1Click:Connect(action)
	end
end

function UI:initializeUI()
	local pg = player:WaitForChild("PlayerGui")
	local sg = createInstance("ScreenGui", {Name = "ShadieUI_Main", ResetOnSpawn = false})
	sg.Parent = pg
	self.screenGui = sg
	local shadow = createInstance("Frame", {
		Name = "Shadow",
		Size = UDim2.new(0,710,0,410),
		Position = UDim2.new(0.5, -355, 0.5, -205),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0
	})
	shadow.Parent = sg
	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0,700,0,400),
		Position = UDim2.new(0.5, -350,0.5,-200),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = Color3.fromRGB(20,20,20),
		BorderSizePixel = 0,
		Active = true,
		Draggable = true
	})
	local mfCorner = createInstance("UICorner", {CornerRadius = UDim.new(0, 10)})
	mfCorner.Parent = mainFrame
	local mfStroke = createInstance("UIStroke", {Color = Color3.fromRGB(50,50,50), Thickness = 2})
	mfStroke.Parent = mainFrame
	mainFrame.Parent = sg
	self.mainFrame = mainFrame
	local titleFrame = createInstance("Frame", {
		Name = "TitleFrame",
		Size = UDim2.new(1,0,0,36),
		Position = UDim2.new(0,0,0,0),
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		BorderSizePixel = 0
	})
	titleFrame.Parent = mainFrame
	local titleLabel = createInstance("TextLabel", {
		Name = "TitleLabel",
		Text = "ShadieUI",
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0
	})
	local titleGrad = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100,100,100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,50))
		}),
		Rotation = 45
	})
	titleGrad.Parent = titleLabel
	titleLabel.Parent = titleFrame
	local hideBtn = createInstance("TextButton", {
		Name = "HideButton",
		Text = "O",
		Size = UDim2.new(0,50,0,50),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(60,60,60),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0,
		Position = UDim2.new(0,10,0,10)
	})
	local hideGrad = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40,40,40))
		}),
		Rotation = 45
	})
	hideGrad.Parent = hideBtn
	local hideCorner = createInstance("UICorner", {CornerRadius = UDim.new(1,0)})
	hideCorner.Parent = hideBtn
	hideBtn.Parent = sg
	hideBtn.MouseButton1Click:Connect(function()
		if self.mainFrame.Visible then
			self:playClosingAnim()
		else
			self.mainFrame.Visible = true
			self:playOpeningAnim()
		end
	end)
	local catPanel = createInstance("ScrollingFrame", {
		Name = "CategoriesPanel",
		Size = UDim2.new(0,180,0,mainFrame.Size.Y.Offset - 36),
		Position = UDim2.new(0,0,0,36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingEnabled = true
	})
	local pad = createInstance("UIPadding", {
		PaddingTop = UDim.new(0,8),
		PaddingBottom = UDim.new(0,8),
		PaddingLeft = UDim.new(0,8),
		PaddingRight = UDim.new(0,8)
	})
	pad.Parent = catPanel
	local layout = createInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	layout.Parent = catPanel
	catPanel.Parent = mainFrame
	self.catPanel = catPanel
	local content = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1,-180,1,-36),
		Position = UDim2.new(0,180,0,36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	local contentCorner = createInstance("UICorner", {CornerRadius = UDim.new(0,8)})
	contentCorner.Parent = content
	content.Parent = mainFrame
	self.contentArea = content
end

function UI:switchCategory(catName)
	if self.categoryFrames and self.categoryFrames[catName] then
		for name, frame in pairs(self.categoryFrames) do
			frame.Visible = (name == catName)
		end
	else
		self:notify("Error", "Category '" .. tostring(catName) .. "' not found", 2)
	end
end

function UI:initializeCategories()
	local cats = {"Home", "Local", "Player", "Workspace", "Backpack"}
	for _, cat in ipairs(cats) do
		self:createCategory(cat)
	end
	self:switchCategory("Home")
end

function UI:setupHome()
	local frame = self.categoryFrames["Home"]
	if not frame then return end
	local card = createInstance("Frame", {
		Name = "ProfileCard",
		Size = UDim2.new(1, -16, 0, 250),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(30,30,30),
		BorderSizePixel = 0
	})
	local gradCard = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,40))
		}),
		Rotation = 45
	})
	gradCard.Parent = card
	local cardCorner = createInstance("UICorner", {CornerRadius = UDim.new(0,12)})
	cardCorner.Parent = card
	card.Parent = frame
	local pic = createInstance("ImageLabel", {
		Name = "ProfilePic",
		Size = UDim2.new(0,80,0,80),
		Position = UDim2.new(0,10,0,10),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(20,20,20),
		BorderSizePixel = 0,
		Image = ""
	})
	local picCorner = createInstance("UICorner", {CornerRadius = UDim.new(1,0)})
	picCorner.Parent = pic
	pic.Parent = card
	local ok, thumb = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
	if ok and thumb then
		pic.Image = thumb
	else
		pic.Image = "rbxassetid://1"
	end
	local info = createInstance("Frame", {
		Name = "InfoFrame",
		Size = UDim2.new(1,-100,1,0),
		Position = UDim2.new(0,100,0,10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	info.Parent = card
	local list = createInstance("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
	list.Parent = info
	local function addInfo(text)
		local lbl = createInstance("TextLabel", {
			Text = text,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255,255,255),
			Size = UDim2.new(1,0,0,30),
			BorderSizePixel = 0
		})
		local lblGrad = createInstance("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(192,192,192))
			}),
			Rotation = 45
		})
		lblGrad.Parent = lbl
		lbl.Parent = info
	end
	spawn(function()
		while wait(1) do
			if frame and frame.Parent then
				for _, child in ipairs(info:GetChildren()) do
					if child:IsA("TextLabel") then child:Destroy() end
				end
				addInfo("Username: " .. player.Name)
				addInfo("Display Name: " .. (player.DisplayName or "N/A"))
				addInfo("UserID: " .. tostring(player.UserId))
				addInfo("Premium: " .. (player.MembershipType == Enum.MembershipType.Premium and "Yes" or "No"))
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					local hum = player.Character:FindFirstChildOfClass("Humanoid")
					addInfo("Health: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth))
					addInfo("WalkSpeed: " .. hum.WalkSpeed)
					addInfo("JumpPower: " .. hum.JumpPower)
				end
			else break end
		end
	end)
	if self.updateAvailable and not self.updateApplied then 
		self:showUpdatePrompt() 
	end
end

function UI:setupLocal()
	local frame = self.categoryFrames["Local"]
	if not frame then return end
	self:createItem("Set Walk Speed", "Local", true, function(value)
		local speed = tonumber(value)
		if speed then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = speed
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
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.JumpPower = jump
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
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.HipHeight = hip
					self:notify("Local", "Hip Height set to " .. hip, 2)
				end
			end
		else
			self:notify("Local", "Invalid hip height", 2)
		end
	end)
	self:createItem("NoClip", "Local", false, function()
		self:flipFeature("NoClip")
	end)
	self:createItem("Spin (enter speed)", "Local", true, function(value)
		if value and value ~= "" then
			local spd = tonumber(value)
			if spd then
				self.spinSpeed = spd
			else
				self:notify("Local", "Invalid spin speed", 2)
				return
			end
		end
		self:flipFeature("Spin")
	end)
	self:createItem("Platform Stand", "Local", false, function()
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = not hum.PlatformStand
				self:notify("Local", "Platform Stand " .. (hum.PlatformStand and "Enabled" or "Disabled"), 2)
			end
		end
	end)
	self:createItem("Bunny Hop", "Local", false, function()
		self:flipFeature("BunnyHop")
	end)
	self:createItem("Infinity Jump", "Local", false, function()
		self:flipFeature("InfinityJump")
	end)
	self:createItem("Reset Stats", "Local", false, function()
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 16
				hum.JumpPower = 50
			end
		end
		Workspace.Gravity = 196.2
		self:notify("Local", "Stats Reset", 2)
	end)
	self:createItem("Respawn", "Local", false, function()
		if player.Character then
			player.Character:BreakJoints()
			self:notify("Local", "Respawn triggered", 2)
		end
	end)
	self:createItem("Play Animation", "Local", true, function(animId)
		self:playAnimation(animId)
	end)
end

function UI:setupPlayer()
	local frame = self.categoryFrames["Player"]
	if not frame then return end
	self:createItem("ESP", "Player", false, function()
		self:flipFeature("ESP")
	end)
	self:createItem("Highlights", "Player", false, function()
		self:flipFeature("Highlights")
	end)
	self:createItem("Teleport Random", "Player", false, function()
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(targets, p)
			end
		end
		if #targets > 0 then
			local target = targets[math.random(1, #targets)]
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
				self:notify("Player", "Teleported to " .. target.Name, 2)
			end
		else
			self:notify("Player", "No target found", 2)
		end
	end)
	self:createItem("Teleport Behind", "Player", false, function()
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(targets, p)
			end
		end
		if #targets > 0 then
			local target = targets[math.random(1, #targets)]
			if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = target.Character.HumanoidRootPart
				local newPos = hrp.Position - hrp.CFrame.LookVector * 5
				player.Character.HumanoidRootPart.CFrame = CFrame.new(newPos)
				self:notify("Player", "Teleported behind " .. target.Name, 2)
			end
		else
			self:notify("Player", "No target found", 2)
		end
	end)
end

function UI:setupWorkspace()
	local frame = self.categoryFrames["Workspace"]
	if not frame then return end
	self:createItem("Day-Night Cycle", "Workspace", false, function()
		if not self.features.DayNightCycle then
			self:startDayNightCycle()
			self:notify("Workspace", "Day-Night Cycle Started", 2)
		else
			self:stopDayNightCycle()
			self:notify("Workspace", "Day-Night Cycle Stopped", 2)
		end
		self:flipFeature("DayNightCycle")
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

function UI:setupBackpack()
	local frame = self.categoryFrames["Backpack"]
	if not frame then return end
	self:createItem("Steal Items", "Backpack", false, function()
		local stolen, playersWith, playersWithout = 0, 0, 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local bp = p:FindFirstChild("Backpack")
				local found = false
				if bp then
					for _, tool in ipairs(bp:GetChildren()) do
						if tool:IsA("Tool") then
							tool.Parent = player.Backpack
							stolen = stolen + 1
							found = true
						end
					end
				end
				if p.Character then
					for _, tool in ipairs(p.Character:GetChildren()) do
						if tool:IsA("Tool") then
							tool.Parent = player.Backpack
							stolen = stolen + 1
							found = true
						end
					end
				end
				if found then
					playersWith = playersWith + 1
				else
					playersWithout = playersWithout + 1
				end
			end
		end
		if stolen > 0 then
			self:notify("Backpack", "Stolen " .. stolen .. " items from " .. playersWith .. " players", 2)
		else
			self:notify("Backpack", "No tools stolen (" .. playersWithout .. " without tools)", 2)
		end
	end)
	self:createItem("Equip All", "Backpack", false, function()
		if player.Backpack and #player.Backpack:GetChildren() > 0 then
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				for _, tool in ipairs(player.Backpack:GetChildren()) do
					if tool:IsA("Tool") then
						hum:EquipTool(tool)
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
		for _, tool in ipairs(player.Backpack:GetChildren()) do
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
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:FindFirstChild("Handle") then
					tool.Parent = Workspace
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
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
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local dup = tool:Clone()
				dup.Parent = player.Backpack
				count = count + 1
			end
		end
		self:notify("Backpack", "Duplicated " .. count .. " tools", 2)
	end)
end

function UI:playAnimation(animId)
	if not player.Character then return self:notify("Animation", "Character unavailable", 2) end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return self:notify("Animation", "Humanoid unavailable", 2) end
	local num = tonumber(animId)
	if not num then return self:notify("Animation", "Invalid animation ID", 2) end
	local anim = createInstance("Animation", {AnimationId = "rbxassetid://" .. animId})
	local track = hum:LoadAnimation(anim)
	local success = pcall(function() track:Play() end)
	if not success then
		self:notify("Animation", "Failed to play animation", 2)
	else
		self:notify("Animation", "Playing " .. animId, 2)
	end
end

function UI:startDayNightCycle()
	if self.features.DayNightCycle then return end
	self.features.DayNightCycle = true
	local prevTime = tick()
	self.dayNightConn = RunService.RenderStepped:Connect(function()
		local now = tick()
		local dt = now - prevTime
		prevTime = now
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

function UI:stopDayNightCycle()
	if self.features.DayNightCycle and self.dayNightConn then
		self.dayNightConn:Disconnect()
		self.features.DayNightCycle = false
	end
end

function UI:checkForUpdates()
	spawn(function()
		local url = "https://raw.githubusercontent.com/ShadieGit/Shadie-Ui/refs/heads/main/Main.lua"
		local result = httpGet(url)
		if result then
			local remoteSig = result:match("SUI_SIGNATURE:(%S+)")
			if remoteSig and remoteSig ~= self.signature and not self.updateApplied then
				self.updateAvailable = true
				self.remoteCode = result
				wait(1)
				if self.categoryFrames["Home"] and not self.updatePromptShown then
					self:showUpdatePrompt()
				end
			else
				self.updateAvailable = false
			end
		end
	end)
end

function UI:showUpdatePrompt()
	if self.updatePromptShown or self.updateApplied then return end
	self.updatePromptShown = true
	local frame = self.categoryFrames["Home"]
	if not frame then return end
	local prompt = createInstance("Frame", {
		Name = "UpdatePrompt",
		Size = UDim2.new(1, -16, 0, 100),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(50,50,50),
		BorderSizePixel = 0
	})
	local grad = createInstance("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(138,43,226)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(75,0,130))
		}),
		Rotation = 45
	})
	grad.Parent = prompt
	local corner = createInstance("UICorner", {CornerRadius = UDim.new(0,8)})
	corner.Parent = prompt
	prompt.Parent = frame
	local label = createInstance("TextLabel", {
		Text = "Update detected. Restart the script?",
		Size = UDim2.new(1,0,0.6,0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0
	})
	label.Parent = prompt
	local btn = createInstance("TextButton", {
		Text = "Restart",
		Size = UDim2.new(0,100,0,40),
		Position = UDim2.new(0.5, -50, 0.65, 0),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(200,50,50),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0
	})
	btn.Parent = prompt
	btn.MouseButton1Click:Connect(function()
		self:applyUpdate()
	end)
end

function UI:applyUpdate()
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

local function updateESP()
	if UI.features.ESP then
		local myHead = player.Character and player.Character:FindFirstChild("Head")
		local myPos = myHead and myHead.Position
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
				local otherHead = p.Character.Head
				local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(otherHead.Position)
				if onscreen then
					if not UI.espElements[p.Name] then
						local box = Drawing.new("Square")
						box.Visible = true
						box.Thickness = 2
						box.Filled = false
						box.Color = Color3.fromRGB(128,128,128)
						local tracer = Drawing.new("Line")
						tracer.Visible = true
						tracer.Thickness = 1
						tracer.Color = Color3.fromRGB(128,128,128)
						local label = Drawing.new("Text")
						label.Visible = true
						label.Text = p.Name
						label.Size = 20
						label.Font = 2
						label.Color = Color3.fromRGB(128,128,128)
						UI.espElements[p.Name] = {box = box, tracer = tracer, label = label}
					end
					local esp = UI.espElements[p.Name]
					local color = Color3.fromRGB(128,128,128)
					if myPos then
						local dot = otherHead.CFrame.LookVector:Dot((myPos - otherHead.Position).Unit)
						if dot > 0.95 then color = Color3.new(0.8,0.8,0.8) end
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
					if UI.espElements[p.Name] then
						UI.espElements[p.Name].box.Visible = false
						UI.espElements[p.Name].tracer.Visible = false
						UI.espElements[p.Name].label.Visible = false
					end
				end
			end
		end
	else
		for _, esp in pairs(UI.espElements) do
			if esp.box then esp.box:Remove() end
			if esp.tracer then esp.tracer:Remove() end
			if esp.label then esp.label:Remove() end
		end
		UI.espElements = {}
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char)
		if UI.features.Highlights and p ~= player then
			if not char:FindFirstChild("Highlight") then
				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.new(0,1,0)
				hl.OutlineColor = Color3.new(1,1,1)
				hl.Parent = char
				UI.highlights[p.Name] = hl
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	if UI.highlights[p.Name] then
		UI.highlights[p.Name]:Destroy()
		UI.highlights[p.Name] = nil
	end
end)

local function updateNoClipBunny()
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and UI.features.NoClip then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
		if UI.features.BunnyHop then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
				if tick() - UI.lastBunnyTime > 0.2 then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
					UI.lastBunnyTime = tick()
				end
			end
		end
	end
end

RunService.RenderStepped:Connect(function()
	updateNoClipBunny()
end)

local function resetJumpCount(char)
	local hum = char:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			UI.currentJumpCount = 0
		end
	end)
end

local function onCharacterAdded(char)
	resetJumpCount(char)
	UI.features.Spin = false
	UI.features.NoClip = false
	UI.features.BunnyHop = false
	UI.features.InfinityJump = false
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	resetJumpCount(player.Character)
	UI.features.Spin = false
	UI.features.NoClip = false
	UI.features.BunnyHop = false
	UI.features.InfinityJump = false
end

UserInputService.JumpRequest:Connect(function()
	if UI.features.InfinityJump then
		local char = player.Character
		if char then
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
end)

VirtualUser:CaptureController()
player.Idled:Connect(function()
	pcall(function() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
end)

UI:initializeUI()
UI:initializeCategories()
UI:setupHome()
UI:setupLocal()
UI:setupPlayer()
UI:setupWorkspace()
UI:setupBackpack()
UI:notify("ShadieUI", "Loaded Successfully", 3)
UI:checkForUpdates()

return UI