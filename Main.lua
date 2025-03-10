local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
assert(localPlayer, "LocalPlayer not found")

local Theme = {
	MainBackground = Color3.fromRGB(50,50,50),
	TitleBackground = Color3.fromRGB(80,80,80),
	ButtonNormal = Color3.fromRGB(70,70,70),
	ButtonHover = Color3.fromRGB(90,90,90),
	ButtonPressed = Color3.fromRGB(50,50,50),
	AccentStart = Color3.fromRGB(100,100,100),
	AccentEnd = Color3.fromRGB(70,70,70),
	TextColor = Color3.fromRGB(255,255,255),
	HighlightColor = Color3.fromRGB(200,200,200)
}

local function createObject(className, properties)
	local obj = Instance.new(className)
	if properties then
		for prop, val in pairs(properties) do
			pcall(function() obj[prop] = val end)
		end
	end
	return obj
end

local EndRegionUI = {
	version = "1.4",
	backup = {},
	errorLog = {},
	espObjects = {},
	highlightObjects = {},
	highlightsActive = false,
	db = false,
	esp = false,
	spin = false,
	noclip = false,
	infiniteJump = false,
	multiJump = false,
	multiJumpMax = 1,
	currentJumpCount = 0,
	dayNightCycleActive = false,
	spinSpeed = 5,
	boxColor = Theme.HighlightColor,
	tracerColor = Color3.fromRGB(255,255,255),
	labelColor = Theme.TextColor
}

function EndRegionUI:logError(errMsg)
	table.insert(self.errorLog, {time = os.time(), err = errMsg})
	warn("Error:", errMsg)
end

function EndRegionUI:notify(title, msg, duration)
	title = title or "EndRegionUI"
	duration = duration or 2
	pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = msg, Duration = duration, Button1 = "OK"}) end)
	print("["..title.."] "..msg)
end

function EndRegionUI:retryFunction(fn, retries, delayTime)
	retries = retries or 3
	delayTime = delayTime or 0.5
	for i = 1, retries do
		local ok, result = pcall(fn)
		if ok then return result end
		wait(delayTime)
	end
	self:logError("Retry failed for "..tostring(fn))
	return nil
end

function EndRegionUI:checkInput(val, minValue, maxValue)
	local num = tonumber(val)
	if num and num >= minValue and num <= maxValue then return true, num end
	return false, num
end

function EndRegionUI:setStat(stat, value)
	local character = localPlayer.Character
	if not character then return self:notify("Error", "Character not found", 2) end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return self:notify("Error", "Humanoid not found", 2) end
	if stat=="JumpPower" then humanoid.JumpPower = value 
	elseif stat=="Gravity" then Workspace.Gravity = value 
	elseif stat=="WalkSpeed" then humanoid.WalkSpeed = value 
	elseif stat=="HipHeight" then humanoid.HipHeight = value 
	elseif stat=="CameraFOV" then Workspace.CurrentCamera.FieldOfView = value 
	else return self:notify("Error", "Invalid stat: "..tostring(stat), 2) end
	print(stat.." set to "..tostring(value))
end

function EndRegionUI:hasTools(player)
	local count = 0
	local bp = player:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") then count = count + 1 end end
	end
	if player.Character then
		for _, tool in ipairs(player.Character:GetChildren()) do if tool:IsA("Tool") then count = count + 1 end end
	end
	return (count>0), count
end

function EndRegionUI:updateCanvas(frame)
	local layout = frame:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() frame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16) end)
		frame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
	end
end

function EndRegionUI:fadeIn(uiObject, duration)
	duration = duration or 0.5
	local tInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, child in ipairs(uiObject:GetDescendants()) do
		if child:IsA("GuiObject") then
			local props = {}
			if child.BackgroundTransparency ~= nil then props.BackgroundTransparency = 0 end
			if child:IsA("TextLabel") or child:IsA("TextButton") then props.TextTransparency = 0 end
			if next(props) then TweenService:Create(child, tInfo, props):Play() end
		end
	end
end

function EndRegionUI:fadeOut(uiObject, duration)
	duration = duration or 0.5
	local tInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, child in ipairs(uiObject:GetDescendants()) do
		if child:IsA("GuiObject") then
			local props = {}
			if child.BackgroundTransparency ~= nil then props.BackgroundTransparency = 1 end
			if child:IsA("TextLabel") or child:IsA("TextButton") then props.TextTransparency = 1 end
			if next(props) then TweenService:Create(child, tInfo, props):Play() end
		end
	end
	wait(duration)
end

function EndRegionUI:destroyUI()
	if self.screenGui then
		self:fadeOut(self.screenGui, 0.5)
		wait(0.5)
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

function EndRegionUI:addCategory(name)
	assert(type(name)=="string" and name~="", "Invalid category name")
	self.categoryButtons = self.categoryButtons or {}
	self.categoryCounters = self.categoryCounters or {}
	self.categoryFrames = self.categoryFrames or {}
	local btn = createObject("TextButton", {
		Name = name.."Btn",
		Text = name,
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.ButtonNormal,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Theme.TextColor,
		Size = UDim2.new(1,0,0,40)
	})
	btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Theme.ButtonPressed end)
	btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = Theme.ButtonNormal end)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.ButtonHover end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.ButtonNormal end)
	local grad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Theme.AccentStart), ColorSequenceKeypoint.new(1, Theme.AccentEnd)}), Rotation = 90})
	grad.Parent = btn
	local crn = createObject("UICorner", {CornerRadius = UDim.new(0,8)})
	crn.Parent = btn
	btn.Parent = self.categoriesPanel
	self.categoryButtons[name] = btn
	self.categoryCounters[name] = 0
	btn.MouseButton1Click:Connect(function() self:switchCategory(name) end)
	local sf = createObject("ScrollingFrame", {
		Name = name.."Frame",
		Size = UDim2.new(1,0,1,0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollingEnabled = true
	})
	local lay2 = createObject("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	lay2.Parent = sf
	local pad = createObject("UIPadding", {PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)})
	pad.Parent = sf
	sf.Parent = self.contentArea
	self.categoryFrames[name] = sf
	self:updateCanvas(sf)
	sf.Visible = false
end

function EndRegionUI:switchCategory(categoryName)
	if self.categoryFrames and self.categoryFrames[categoryName] then
		for name, frame in pairs(self.categoryFrames) do frame.Visible = (name==categoryName) end
	else
		self:notify("Error", "Category '"..tostring(categoryName).."' does not exist",2)
	end
end

function EndRegionUI:addItem(itemName, categoryName, hasInput, callback)
	assert(type(itemName)=="string" and itemName~="", "Invalid item name")
	assert(type(categoryName)=="string" and categoryName~="", "Invalid category")
	assert(type(hasInput)=="boolean", "hasInput must be boolean")
	assert(type(callback)=="function", "Callback must be a function")
	local parentFrame = self.categoryFrames and self.categoryFrames[categoryName]
	if not parentFrame then return self:notify("Error", "Category '"..categoryName.."' does not exist",2) end
	local container = createObject("Frame", {Name = itemName.."Container", Size = UDim2.new(1,0,0,40), BorderSizePixel = 0, BackgroundTransparency = 1})
	local order = self.categoryCounters[categoryName] or 0
	container.LayoutOrder = order
	self.categoryCounters[categoryName] = order+1
	container.Parent = parentFrame
	local btn = createObject("TextButton", {
		Name = itemName.."Button",
		Text = itemName,
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(70,70,70),
		Font = Enum.Font.Gotham,
		TextScaled = true,
		TextColor3 = Theme.TextColor,
		Size = UDim2.new(0,140,1,0)
	})
	btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(50,50,50) end)
	btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,70) end)
	local btnGrad = createObject("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60,60,60))}), Rotation = 90})
	btnGrad.Parent = btn
	local btnCrn = createObject("UICorner", {CornerRadius = UDim.new(0,6)})
	btnCrn.Parent = btn
	btn.Parent = container
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80,80,80) end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,70) end)
	if hasInput then
		local inputBox = createObject("TextBox", {
			Name = itemName.."Input",
			Text = "",
			PlaceholderText = "Enter value",
			PlaceholderColor3 = Color3.fromRGB(150,150,150),
			BorderSizePixel = 0,
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(50,50,50),
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextColor3 = Theme.TextColor,
			Size = UDim2.new(0,120,1,0),
			Position = UDim2.new(0,150,0,0)
		})
		inputBox.Parent = container
		btn.MouseButton1Click:Connect(function()
			local str = inputBox.Text
			if str=="" then
				self:notify("Input Error", "Enter a value",2)
			else
				if tonumber(str) then
					local valid, num = self:checkInput(str,0,10000)
					if valid then
						inputBox.TextColor3 = Color3.fromRGB(0,255,0)
						callback(str)
					else
						inputBox.TextColor3 = Color3.fromRGB(255,0,0)
						inputBox.Text = ""
						self:notify("Input Error", "Invalid number",2)
					end
				else
					callback(str)
				end
			end
		end)
	else
		btn.MouseButton1Click:Connect(callback)
	end
end

function EndRegionUI:setupHome()
	local frame = self.categoryFrames and self.categoryFrames["Home"]
	if not frame then return end
	local profileCard = createObject("Frame", {
		Name = "ProfileCard",
		Size = UDim2.new(1,-16,0,220),
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.MainBackground
	})
	local grad = createObject("UIGradient", {
		Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(50,50,70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,40))}),
		Rotation = 45
	})
	grad.Parent = profileCard
	local crn = createObject("UICorner", {CornerRadius = UDim.new(0,12)})
	crn.Parent = profileCard
	profileCard.Parent = frame
	local pic = createObject("ImageLabel", {
		Name = "ProfilePic",
		Size = UDim2.new(0,80,0,80),
		Position = UDim2.new(0,10,0,10),
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(20,20,20),
		Image = ""
	})
	local picCrn = createObject("UICorner", {CornerRadius = UDim.new(1,0)})
	picCrn.Parent = pic
	pic.Parent = profileCard
	local suc, thumb = pcall(function() return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
	if suc and thumb then pic.Image = thumb else pic.Image = "rbxassetid://1" end
	local info = createObject("Frame", {
		Name = "InfoFrame",
		Size = UDim2.new(1,-100,1,0),
		Position = UDim2.new(0,100,0,10),
		BorderSizePixel = 0,
		BackgroundTransparency = 1
	})
	info.Parent = profileCard
	local ilayout = createObject("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
	ilayout.Parent = info
	local function addInfo(text)
		local lbl = createObject("TextLabel", {
			Text = text,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			TextColor3 = Theme.TextColor,
			Size = UDim2.new(1,0,0,30)
		})
		lbl.Parent = info
	end
	addInfo("Username: "..localPlayer.Name)
	addInfo("Display: "..(localPlayer.DisplayName or "N/A"))
	addInfo("ID: "..tostring(localPlayer.UserId))
	addInfo("Premium: "..(localPlayer.MembershipType==Enum.MembershipType.Premium and "Yes" or "No"))
end

function EndRegionUI:setupLocal()
	local frame = self.categoryFrames and self.categoryFrames["Local"]
	if not frame then return end
	self:addItem("Set Walk Speed","Local",true,function(value)
		local speed = tonumber(value)
		if speed then
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.WalkSpeed = speed end
			self:notify("Local","Walk Speed set to "..speed,2)
		end
	end)
	self:addItem("Set Jump Power","Local",true,function(value)
		local jump = tonumber(value)
		if jump then
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.JumpPower = jump end
			self:notify("Local","Jump Power set to "..jump,2)
		end
	end)
	self:addItem("Set Gravity","Local",true,function(value)
		local grav = tonumber(value)
		if grav then
			Workspace.Gravity = grav
			self:notify("Local","Gravity set to "..grav,2)
		end
	end)
	self:addItem("Set Hip Height","Local",true,function(value)
		local hip = tonumber(value)
		if hip then
			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.HipHeight = hip end
			self:notify("Local","Hip Height set to "..hip,2)
		end
	end)
	self:addItem("NoClip","Local",false,function() self:switchNoClip() end)
	self:addItem("Spin","Local",false,function() self:switchSpin() end)
	self:addItem("Set Spin Speed","Local",true,function(value)
		local newSpeed = tonumber(value)
		if newSpeed then
			self.spinSpeed = newSpeed
			if self.spin and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = localPlayer.Character.HumanoidRootPart
				local spinObj = hrp:FindFirstChild("SpinAngularVelocity")
				if spinObj then spinObj.AngularVelocity = Vector3.new(0,newSpeed,0) end
			end
			self:notify("Local","Spin speed set to "..newSpeed,2)
		end
	end)
	self:addItem("Platform Stand","Local",false,function() self:switchPlatformStand() end)
	self:addItem("Reset Stats","Local",false,function()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
		Workspace.Gravity = 196.2
		self:notify("Local","Stats reset",2)
	end)
	self:addItem("Respawn","Local",false,function()
		if localPlayer.Character then localPlayer.Character:BreakJoints() end
		self:notify("Local","Respawn triggered",2)
	end)
	self:addItem("Play Animation","Local",true,function(animId) self:playAnimation(animId) end)
end

function EndRegionUI:setupVisual()
	local frame = self.categoryFrames and self.categoryFrames["Visual"]
	if not frame then return end
	self:addItem("ESP","Visual",false,function()
		self.esp = not self.esp
		if not self.esp then
			for name, esp in pairs(self.espObjects) do
				if esp.box then esp.box:Remove() end
				if esp.tracer then esp.tracer:Remove() end
				if esp.label then esp.label:Remove() end
			end
			self.espObjects = {}
		end
		self:notify("Visual","ESP "..(self.esp and "On" or "Off"),2)
	end)
	self:addItem("Highlights","Visual",false,function() self:switchHighlights() end)
end

function EndRegionUI:switchHighlights()
	self.highlightsActive = not self.highlightsActive
	if self.highlightsActive then
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=localPlayer and p.Character then
				updateHighlightsOnCharacter(p)
			end
		end
		self:notify("Visual","Highlights On",2)
	else
		for _, hl in pairs(self.highlightObjects) do
			if hl then hl:Destroy() end
		end
		self.highlightObjects = {}
		self:notify("Visual","Highlights Off",2)
	end
end

function EndRegionUI:setupItems()
	local frame = self.categoryFrames and self.categoryFrames["Items"]
	if not frame then return end
	self:addItem("Steal Items","Items",false,function()
		local total,withTools,withoutTools,stolen = 0,0,0,0
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=localPlayer then
				total = total+1
				local has,_ = self:hasTools(p)
				if has then
					withTools = withTools+1
					local bp = p:FindFirstChild("Backpack")
					if bp then
						for _, tool in ipairs(bp:GetChildren()) do
							if tool:IsA("Tool") then tool.Parent = localPlayer.Backpack; stolen = stolen+1 end
						end
					end
					if p.Character then
						for _, tool in ipairs(p.Character:GetChildren()) do
							if tool:IsA("Tool") then tool.Parent = localPlayer.Backpack; stolen = stolen+1 end
						end
					end
				else
					withoutTools = withoutTools+1
				end
			end
		end
		if stolen>0 then self:notify("Items","Stolen "..stolen.." items from "..withTools.." players",2)
		else self:notify("Items","No items stolen ("..withoutTools.." lacked tools)",2) end
	end)
	self:addItem("Equip All","Items",false,function()
		local has,_ = self:hasTools(localPlayer)
		if not has then return self:notify("Items","No tools in Backpack",2) end
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
				if tool:IsA("Tool") then humanoid:EquipTool(tool) end
			end
			self:notify("Items","Equipped all tools",2)
		end
	end)
	self:addItem("Clear Backpack","Items",false,function()
		local cnt = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then tool:Destroy(); cnt = cnt+1 end
		end
		if cnt>0 then self:notify("Items","Cleared "..cnt.." tools",2) else self:notify("Items","Backpack empty",2) end
	end)
	self:addItem("Drop All","Items",false,function()
		local cnt = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:FindFirstChild("Handle") then
					tool.Parent = Workspace
					local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrp then tool.Handle.CFrame = hrp.CFrame+Vector3.new(math.random(-5,5),5,math.random(-5,5)) end
				else
					tool.Parent = Workspace
				end
				cnt = cnt+1
			end
		end
		if cnt>0 then self:notify("Items","Dropped "..cnt.." tools",2) else self:notify("Items","No tools to drop",2) end
	end)
	self:addItem("Duplicate All","Items",false,function()
		local cnt = 0
		for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local dup = tool:Clone()
				dup.Parent = localPlayer.Backpack
				cnt = cnt+1
			end
		end
		self:notify("Items","Duplicated "..cnt.." tools",2)
	end)
end

function EndRegionUI:setupWorkspace()
	local frame = self.categoryFrames and self.categoryFrames["Workspace"]
	if not frame then return end
	self:addItem("Day-Night Cycle","Workspace",false,function()
		if not self.dayNightCycleActive then
			self:startDayNightCycle()
			self:notify("Workspace","Day-Night Cycle Started",2)
		else
			self:stopDayNightCycle()
			self:notify("Workspace","Day-Night Cycle Stopped",2)
		end
	end)
	self:addItem("Set Global Gravity","Workspace",true,function(value)
		local valid,num = self:checkInput(value,0,10000)
		if valid then
			Workspace.Gravity = num
			self:notify("Workspace","Gravity set to "..num,2)
		else
			self:notify("Workspace","Invalid gravity value",2)
		end
	end)
	self:addItem("Toggle Fog","Workspace",false,function()
		if Lighting.FogEnd>0 then
			Lighting.FogEnd = 0
			self:notify("Workspace","Fog disabled",2)
		else
			Lighting.FogEnd = 1000
			self:notify("Workspace","Fog enabled",2)
		end
	end)
	self:addItem("Reset Lighting","Workspace",false,function()
		Lighting.Ambient = Color3.fromRGB(128,128,128)
		Lighting.Brightness = 2
		Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
		Lighting.FogEnd = 1000
		self:notify("Workspace","Lighting reset",2)
	end)
end

function EndRegionUI:setupPlayers()
	local frame = self.categoryFrames and self.categoryFrames["Players"]
	if not frame then return end
	self:addItem("Teleport to Random","Players",false,function()
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(others,p) end
		end
		if #others>0 then
			local target = others[math.random(1,#others)]
			if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				localPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
				self:notify("Players","Teleported to "..target.Name,2)
			end
		else
			self:notify("Players","No target found",2)
		end
	end)
	self:addItem("Teleport Behind Random","Players",false,function()
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(others,p) end
		end
		if #others>0 then
			local target = others[math.random(1,#others)]
			if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local targetHRP = target.Character.HumanoidRootPart
				localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position - targetHRP.CFrame.LookVector*5)
				self:notify("Players","Teleported behind "..target.Name,2)
			end
		else
			self:notify("Players","No target found",2)
		end
	end)
end

function EndRegionUI:playAnimation(animId)
	if not localPlayer.Character then return self:notify("Animation","Character not found",2) end
	local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return self:notify("Animation","Humanoid not found",2) end
	local anim = createObject("Animation",{AnimationId = "rbxassetid://"..animId})
	local track = humanoid:LoadAnimation(anim)
	pcall(function() track:Play() end)
	self:notify("Animation","Playing "..animId,2)
end

function EndRegionUI:switchSpin()
	self.spin = not self.spin
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if self.spin then
		local spinObj = hrp:FindFirstChild("SpinAngularVelocity") or createObject("BodyAngularVelocity",{Parent = hrp, Name = "SpinAngularVelocity"})
		spinObj.MaxTorque = Vector3.new(0,1e6,0)
		spinObj.AngularVelocity = Vector3.new(0,self.spinSpeed,0)
	else
		local spinObj = hrp:FindFirstChild("SpinAngularVelocity")
		if spinObj then spinObj:Destroy() end
	end
	self:notify("Local","Spin "..(self.spin and "On" or "Off"),2)
end

function EndRegionUI:switchNoClip()
	self.noclip = not self.noclip
	self:notify("Local","NoClip "..(self.noclip and "On" or "Off"),2)
end

function EndRegionUI:switchPlatformStand()
	if localPlayer.Character then
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = not humanoid.PlatformStand
			self:notify("Local","Platform Stand "..(humanoid.PlatformStand and "On" or "Off"),2)
		end
	end
end

function EndRegionUI:startDayNightCycle()
	if self.dayNightCycleActive then return end
	self.dayNightCycleActive = true
	local lastTick = tick()
	self.dayNightConnection = RunService.RenderStepped:Connect(function()
		local now = tick()
		local dt = now - lastTick
		lastTick = now
		Lighting.ClockTime = (Lighting.ClockTime + dt*0.1)%24
		if Lighting.ClockTime>=6 and Lighting.ClockTime<18 then
			Lighting.Brightness = 1.2
			Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
			Lighting.ColorShift_Top = Color3.fromRGB(210,210,255)
			Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
		elseif Lighting.ClockTime>=18 and Lighting.ClockTime<22 then
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

function EndRegionUI:stopDayNightCycle()
	if self.dayNightCycleActive and self.dayNightConnection then
		self.dayNightConnection:Disconnect()
		self.dayNightCycleActive = false
	end
end

local function setupJumpReset(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(function(old,new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then EndRegionUI.currentJumpCount = 0 end
	end)
end

local function onCharacterAdded(character)
	setupJumpReset(character)
	EndRegionUI.spin = false
	EndRegionUI.noclip = false
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then setupJumpReset(localPlayer.Character); EndRegionUI.spin = false; EndRegionUI.noclip = false end

UserInputService.JumpRequest:Connect(function()
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			if EndRegionUI.infiniteJump then humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			elseif EndRegionUI.multiJump and EndRegionUI.currentJumpCount < EndRegionUI.multiJumpMax then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				EndRegionUI.currentJumpCount = EndRegionUI.currentJumpCount + 1
			end
		end
	end
end)

VirtualUser:CaptureController()
localPlayer.Idled:Connect(function() pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end)

RunService.Heartbeat:Connect(function()
	if EndRegionUI.esp then
		local myHead = localPlayer.Character and localPlayer.Character:FindFirstChild("Head")
		local myPos = myHead and myHead.Position
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=localPlayer and p.Character and p.Character:FindFirstChild("Head") then
				local otherHead = p.Character.Head
				local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(otherHead.Position)
				if onscreen then
					if not EndRegionUI.espObjects[p.Name] then
						local box = Drawing.new("Square"); box.Visible = true; box.Thickness = 2; box.Filled = false
						local tracer = Drawing.new("Line"); tracer.Visible = true; tracer.Thickness = 1
						local label = Drawing.new("Text"); label.Visible = true; label.Text = p.Name; label.Size = 20; label.Font = 2
						EndRegionUI.espObjects[p.Name] = {box = box, tracer = tracer, label = label}
					end
					local esp = EndRegionUI.espObjects[p.Name]
					local dot = 0
					if myPos then dot = otherHead.CFrame.LookVector:Dot((myPos - otherHead.Position).Unit) end
					local color = EndRegionUI.boxColor
					if dot > 0.95 then color = Color3.new(1,1,1) end
					esp.box.Color = color
					esp.box.Position = Vector2.new(pos.X-25, pos.Y-25)
					esp.box.Size = Vector2.new(50,50)
					esp.tracer.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y)
					esp.tracer.To = Vector2.new(pos.X, pos.Y)
					esp.label.Position = Vector2.new(pos.X, pos.Y-30)
					esp.box.Visible = true; esp.tracer.Visible = true; esp.label.Visible = true
				else
					if EndRegionUI.espObjects[p.Name] then
						EndRegionUI.espObjects[p.Name].box.Visible = false
						EndRegionUI.espObjects[p.Name].tracer.Visible = false
						EndRegionUI.espObjects[p.Name].label.Visible = false
					end
				end
			end
		end
	else
		for k, esp in pairs(EndRegionUI.espObjects) do
			if esp.box then esp.box:Remove() end
			if esp.tracer then esp.tracer:Remove() end
			if esp.label then esp.label:Remove() end
		end
		EndRegionUI.espObjects = {}
	end
end)

RunService.RenderStepped:Connect(function()
	local character = localPlayer.Character
	if character and EndRegionUI.noclip then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)

local function updateHighlightsOnCharacter(player)
	if EndRegionUI.highlightsActive and player~=localPlayer and player.Character then
		local hl = player.Character:FindFirstChild("EndRegionUI_Highlight")
		if not hl then
			hl = Instance.new("Highlight")
			hl.Name = "EndRegionUI_Highlight"
			hl.FillColor = Theme.HighlightColor
			hl.OutlineColor = Color3.fromRGB(255,255,255)
			hl.Parent = player.Character
			EndRegionUI.highlightObjects[player.Name] = hl
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		updateHighlightsOnCharacter(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if EndRegionUI.highlightObjects[player.Name] then
		EndRegionUI.highlightObjects[player.Name]:Destroy()
		EndRegionUI.highlightObjects[player.Name] = nil
	end
end)

local pg = localPlayer:FindFirstChild("PlayerGui")
if not pg then EndRegionUI:notify("Error", "PlayerGui not found", 2) return end
local sg = createObject("ScreenGui", {Name = "EndRegionUI", ResetOnSpawn = false})
sg.Parent = pg
EndRegionUI.screenGui = sg

local mainFrame = createObject("Frame", {
	Name = "MainFrame",
	BackgroundColor3 = Theme.MainBackground,
	AnchorPoint = Vector2.new(0.5,0.5),
	Position = UDim2.new(0.5,0,0.5,0),
	Size = UDim2.new(0,700,0,400),
	BorderSizePixel = 0,
	Active = true,
	Draggable = true,
	BackgroundTransparency = 0
})
mainFrame.Parent = sg
EndRegionUI.mainFrame = mainFrame

local mg = createObject("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.MainBackground),
		ColorSequenceKeypoint.new(1, Theme.ButtonNormal)
	}),
	Rotation = 45
})
mg.Parent = mainFrame

local mc = createObject("UICorner", {CornerRadius = UDim.new(0,12)})
mc.Parent = mainFrame

local titleFrame = createObject("Frame", {
	Name = "TitleFrame",
	BackgroundColor3 = Theme.TitleBackground,
	Size = UDim2.new(1,0,0,36),
	Position = UDim2.new(0,0,0,0),
	BorderSizePixel = 0,
	BackgroundTransparency = 0
})
titleFrame.Parent = mainFrame

local tg = createObject("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100,100,100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,50))
	}),
	Rotation = 45
})
tg.Parent = titleFrame

local tc = createObject("UICorner", {CornerRadius = UDim.new(0,12)})
tc.Parent = titleFrame

local titleLabel = createObject("TextLabel", {
	Name = "TitleLabel",
	Text = "EndRegionUI",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	BackgroundTransparency = 1,
	TextColor3 = Theme.TextColor,
	Size = UDim2.new(1,0,1,0),
	BorderSizePixel = 0,
	TextTransparency = 0
})
titleLabel.Parent = titleFrame

local openBtn = createObject("TextButton", {
	Name = "OpenButton",
	Text = "O",
	BorderSizePixel = 0,
	BackgroundTransparency = 0,
	BackgroundColor3 = Theme.ButtonNormal,
	TextColor3 = Theme.TextColor,
	Size = UDim2.new(0,40,0,40),
	Position = UDim2.new(0,4,0,4)
})
openBtn.MouseButton1Down:Connect(function() openBtn.BackgroundColor3 = Theme.ButtonPressed end)
openBtn.MouseButton1Up:Connect(function() openBtn.BackgroundColor3 = Theme.ButtonNormal end)
local obCrn = createObject("UICorner", {CornerRadius = UDim.new(1,0)})
obCrn.Parent = openBtn
openBtn.Parent = sg
openBtn.MouseButton1Click:Connect(function()
	if EndRegionUI.debounceBusy or EndRegionUI.mainFrame.Visible then return end
	EndRegionUI.debounceBusy = true
	EndRegionUI.mainFrame.Visible = true
	EndRegionUI:fadeIn(EndRegionUI.mainFrame,0.5)
	openBtn.Visible = false
	delay(0.3, function() EndRegionUI.debounceBusy = false end)
end)

local closeBtn = createObject("TextButton", {
	Name = "CloseButton",
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	BorderSizePixel = 0,
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(200,50,50),
	TextColor3 = Theme.TextColor,
	Size = UDim2.new(0,28,0,28),
	Position = UDim2.new(1,-36,0,4)
})
closeBtn.MouseButton1Down:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(180,40,40) end)
closeBtn.MouseButton1Up:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50) end)
local cbCrn = createObject("UICorner", {CornerRadius = UDim.new(1,0)})
cbCrn.Parent = closeBtn
closeBtn.Parent = titleFrame
closeBtn.MouseButton1Click:Connect(function()
	if EndRegionUI.debounceBusy then return end
	EndRegionUI.debounceBusy = true
	EndRegionUI:fadeOut(EndRegionUI.mainFrame,0.5)
	EndRegionUI.mainFrame.Visible = false
	openBtn.Visible = true
	delay(0.3, function() EndRegionUI.debounceBusy = false end)
end)

EndRegionUI.categoriesPanel = createObject("ScrollingFrame", {
	Name = "CategoriesPanel",
	Size = UDim2.new(0,180,0,EndRegionUI.mainFrame.Size.Y.Offset-36),
	Position = UDim2.new(0,0,0,36),
	BorderSizePixel = 0,
	BackgroundTransparency = 0,
	BackgroundColor3 = Theme.ButtonNormal,
	ScrollBarThickness = 4,
	ScrollingEnabled = true
})
local cp = createObject("UIPadding", {PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)})
cp.Parent = EndRegionUI.categoriesPanel
local clayout = createObject("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
clayout.Parent = EndRegionUI.categoriesPanel
EndRegionUI:updateCanvas(EndRegionUI.categoriesPanel)
EndRegionUI.categoriesPanel.Parent = EndRegionUI.mainFrame

EndRegionUI.contentArea = createObject("Frame", {
	Name = "ContentArea",
	Size = UDim2.new(1,-180,1,-36),
	Position = UDim2.new(0,180,0,36),
	BorderSizePixel = 0,
	BackgroundTransparency = 0,
	BackgroundColor3 = Theme.MainBackground
})
local conCrn = createObject("UICorner", {CornerRadius = UDim.new(0,8)})
conCrn.Parent = EndRegionUI.contentArea
EndRegionUI.contentArea.Parent = EndRegionUI.mainFrame

local cats = {"Home","Local","Visual","Items","Workspace","Players"}
for _, cat in ipairs(cats) do EndRegionUI:addCategory(cat) end
EndRegionUI:setupHome()
EndRegionUI:setupLocal()
EndRegionUI:setupVisual()
EndRegionUI:setupItems()
EndRegionUI:setupWorkspace()
EndRegionUI:setupPlayers()
EndRegionUI:switchCategory("Home")
EndRegionUI:notify("EndRegionUI","Loaded Successfully",3)

function EndRegionUI:checkForUpdates()
	spawn(function()
		while wait(300) do
			local success, remoteCode = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/ShadieGit/EndRegion-Ui/refs/heads/main/Main.lua",true) end)
			if success and remoteCode then
				local remoteVersion = remoteCode:match('EndRegionUI%.version%s*=%s*"(.-)"')
				if remoteVersion and remoteVersion ~= self.version then
					self:notify("Updater","New version detected, restarting...",2)
					wait(2)
					self:destroyUI()
					loadstring(remoteCode)()
					break
				end
			else
				self:notify("Updater","Failed to check for updates",2)
			end
		end
	end)
end

EndRegionUI:checkForUpdates()
return EndRegionUI