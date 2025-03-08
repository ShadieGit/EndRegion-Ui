local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
if not LocalPlayer then warn("LocalPlayer not found.") return end

local function CreateInstance(className, props)
	local inst = Instance.new(className)
	if props then
		for prop, val in pairs(props) do
			local ok, err = pcall(function() inst[prop] = val end)
			if not ok then warn("[EndRegionUI] "..prop.." error - "..tostring(err)) end
		end
	end
	return inst
end

local EndRegionUI = {}
EndRegionUI.CatButtons = {}
EndRegionUI.CatFrames = {}
EndRegionUI.HighlightEnabled = false
EndRegionUI.SpinEnabled = false
EndRegionUI.NoclipEnabled = false
EndRegionUI.InfJumpEnabled = false
EndRegionUI.MultiJumpEnabled = false
EndRegionUI.MultiJumpMax = 1
EndRegionUI.CurrentJumpCount = 0
EndRegionUI._db = false
EndRegionUI.ShaderOn = false
EndRegionUI.RainOn = false
EndRegionUI.ESPEnabled = false
EndRegionUI.ESPObjects = {}

EndRegionUI.notify = function(self, title, msg, dur)
	title = title or "EndRegionUI"
	dur = dur or 2
	pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = msg, Duration = dur, Button1 = "OK"}) end)
	print("["..title.."] "..msg)
end

EndRegionUI.checkInput = function(self, val, mi, ma)
	local n = tonumber(val)
	if n and n >= mi and n <= ma then return true, n end
	return false, n
end

EndRegionUI.setStat = function(self, stat, v)
	local char = LocalPlayer.Character
	if not char then self:notify("Error", "Character not found",2) return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if stat == "Jump Power" and hum then hum.JumpPower = v
	elseif stat == "Gravity" then Workspace.Gravity = v
	elseif stat == "Walk Speed" and hum then hum.WalkSpeed = v
	elseif stat == "Hip Height" and hum then hum.HipHeight = v
	elseif stat == "Camera FOV" then Workspace.CurrentCamera.FieldOfView = v
	else self:notify("Error", "Invalid stat: "..tostring(stat),2) return end
	print(stat.." = "..tostring(v))
end

EndRegionUI.hasTools = function(self, p)
	local cnt = 0
	local bp = p:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then cnt = cnt + 1 end end
	end
	if p.Character then
		for _, t in ipairs(p.Character:GetChildren()) do if t:IsA("Tool") then cnt = cnt + 1 end end
	end
	return (cnt > 0), cnt
end

EndRegionUI.updateCanvas = function(self, sf)
	local layout = sf:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16) end)
		sf.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
	end
end

EndRegionUI.addCat = function(self, name)
	if type(name) ~= "string" or name == "" then self:notify("Error", "Invalid category name",2) return end
	local btn = CreateInstance("TextButton", {Name = name.."Btn", Text = name, BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = Color3.fromRGB(240,240,240), Size = UDim2.new(1,0,0,40)})
	local grad = CreateInstance("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(80,80,80)), ColorSequenceKeypoint.new(1,Color3.fromRGB(60,60,60))}), Rotation = 90})
	grad.Parent = btn
	local crn = CreateInstance("UICorner", {CornerRadius = UDim.new(0,8)})
	crn.Parent = btn
	btn.Parent = self.CategoriesPanel
	self.CatButtons[name] = btn
	btn.MouseButton1Click:Connect(function() self:switchCat(name) end)
	local sf = CreateInstance("ScrollingFrame", {Name = name.."Frame", Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollingEnabled = true})
	local layout2 = CreateInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	layout2.Parent = sf
	local pad = CreateInstance("UIPadding", {PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)})
	pad.Parent = sf
	sf.Parent = self.ContentArea
	self.CatFrames[name] = sf
	self:updateCanvas(sf)
	sf.Visible = false
end

EndRegionUI.addItem = function(self, name, cate, hasInput, callback)
	if type(name) ~= "string" or name == "" then self:notify("Error", "Invalid item name",2) return end
	if type(cate) ~= "string" or cate == "" then self:notify("Error", "Invalid category",2) return end
	if type(hasInput) ~= "boolean" then self:notify("Error", "hasInput must be boolean",2) return end
	if type(callback) ~= "function" then self:notify("Error", "Callback must be function",2) return end
	local parentFrame = self.CatFrames[cate]
	if not parentFrame then self:notify("Error", "Category '"..cate.."' does not exist",2) return end
	local cont = CreateInstance("Frame", {Name = name.."Cont", Size = UDim2.new(1,0,0,40), BorderSizePixel = 0, BackgroundTransparency = 1})
	cont.Parent = parentFrame
	local btn = CreateInstance("TextButton", {Name = name.."Btn", Text = name, BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(80,80,80), Font = Enum.Font.Gotham, TextScaled = true, TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0,140,1,0)})
	local grad = CreateInstance("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,90,90)), ColorSequenceKeypoint.new(1,Color3.fromRGB(70,70,70))}), Rotation = 90})
	grad.Parent = btn
	local crn = CreateInstance("UICorner", {CornerRadius = UDim.new(0,6)})
	crn.Parent = btn
	btn.Parent = cont
	if hasInput then
		local input = CreateInstance("TextBox", {Name = name.."Input", Text = "", PlaceholderText = "Enter value", PlaceholderColor3 = Color3.fromRGB(150,150,150), BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), Font = Enum.Font.Gotham, TextScaled = true, TextColor3 = Color3.fromRGB(240,240,240), Size = UDim2.new(0,120,1,0), Position = UDim2.new(0,150,0,0)})
		input.Parent = cont
		btn.MouseButton1Click:Connect(function()
			local txt = input.Text
			if txt == "" then
				self:notify("Input Error", "Enter a value",2)
			else
				if tonumber(txt) then
					local valid, num = self:checkInput(txt, 0, 10000)
					if valid then
						input.TextColor3 = Color3.fromRGB(0,255,0)
						callback(txt)
					else
						input.TextColor3 = Color3.fromRGB(255,0,0)
						input.Text = ""
						self:notify("Input Error", "Invalid number",2)
					end
				else
					callback(txt)
				end
			end
		end)
	else
		btn.MouseButton1Click:Connect(callback)
	end
end

EndRegionUI.switchCat = function(self, name)
	for k, frm in pairs(self.CatFrames) do
		frm.Visible = (k == name)
	end
end

EndRegionUI.setupHome = function(self)
	local frm = self.CatFrames["Home"]
	if not frm then return end
	local card = CreateInstance("Frame", {Name = "ProfileCard", Size = UDim2.new(1,-16,0,220), BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(30,30,30)})
	local grad = CreateInstance("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(50,50,70)), ColorSequenceKeypoint.new(1,Color3.fromRGB(20,20,40))}), Rotation = 45})
	grad.Parent = card
	local crn = CreateInstance("UICorner", {CornerRadius = UDim.new(0,12)})
	crn.Parent = card
	card.Parent = frm
	local pic = CreateInstance("ImageLabel", {Name = "ProfilePic", Size = UDim2.new(0,80,0,80), Position = UDim2.new(0,10,0,10), BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20,20,20), Image = ""})
	local pcrn = CreateInstance("UICorner", {CornerRadius = UDim.new(1,0)})
	pcrn.Parent = pic
	pic.Parent = card
	local suc, thumb = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
	if suc and thumb then pic.Image = thumb else pic.Image = "rbxassetid://1" end
	local info = CreateInstance("Frame", {Name = "InfoFrame", Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,100,0,10), BorderSizePixel = 0, BackgroundTransparency = 1})
	info.Parent = card
	local il = CreateInstance("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
	il.Parent = info
	local addI = function(txt) local lbl = CreateInstance("TextLabel", {Text = txt, Font = Enum.Font.Gotham, TextScaled = true, BorderSizePixel = 0, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1,0,0,30)}) lbl.Parent = info end
	addI("Username: " .. LocalPlayer.Name)
	addI("Display: " .. (LocalPlayer.DisplayName or "N/A"))
	addI("ID: " .. tostring(LocalPlayer.UserId))
	addI("Premium: " .. (LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Yes" or "No"))
end

EndRegionUI.setupPlayerMods = function(self)
	local frm = self.CatFrames["Player Mods"]
	if not frm then return end
	self:addItem("Set Walk Speed", "Player Mods", true, function(val)
		local s = tonumber(val)
		if s then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = s end
			self:notify("Player Mods", "Walk Speed set to " .. s, 2)
		end
	end)
	self:addItem("Set Jump Power", "Player Mods", true, function(val)
		local p = tonumber(val)
		if p then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.JumpPower = p end
			self:notify("Player Mods", "Jump Power set to " .. p, 2)
		end
	end)
	self:addItem("Set Gravity", "Player Mods", true, function(val)
		local g = tonumber(val)
		if g then
			Workspace.Gravity = g
			self:notify("Player Mods", "Gravity set to " .. g, 2)
		end
	end)
	self:addItem("Set Hip Height", "Player Mods", true, function(val)
		local h = tonumber(val)
		if h then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.HipHeight = h end
			self:notify("Player Mods", "Hip Height set to " .. h, 2)
		end
	end)
	self:addItem("NoClip", "Player Mods", false, function()
		EndRegionUI.Noclip = not EndRegionUI.Noclip
		self:notify("Player Mods", "NoClip " .. (EndRegionUI.Noclip and "On" or "Off"), 2)
	end)
	self:addItem("Spin", "Player Mods", false, function()
		self:applySpin()
		self:notify("Player Mods", "Spin " .. (EndRegionUI.Spin and "On" or "Off"), 2)
	end)
	self:addItem("Set Spin Speed", "Player Mods", true, function(val)
		local spd = tonumber(val)
		if spd then
			EndRegionUI.SpinSpeed = spd
			if EndRegionUI.Spin and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = LocalPlayer.Character.HumanoidRootPart
				if hrp:FindFirstChild("SpinAngularVelocity") then
					hrp.SpinAngularVelocity.AngularVelocity = Vector3.new(0, spd, 0)
				end
			end
			self:notify("Player Mods", "Spin speed set to " .. spd, 2)
		end
	end)
	self:addItem("Reset", "Player Mods", false, function()
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.HipHeight = 2
		end
		Workspace.Gravity = 196.2
		self:notify("Player Mods", "Reset Done", 2)
	end)
	self:addItem("ESP", "Player Mods", false, function()
		self:toggleESP()
		self:notify("Player Mods", "ESP " .. (EndRegionUI.ESPEnabled and "On" or "Off"), 2)
	end)
end

EndRegionUI.setupItems = function(self)
	local frm = self.CatFrames["Items"]
	if not frm then return end
	self:addItem("Steal Items", "Items", false, function()
		local tot, wi, wo, cnt = 0, 0, 0, 0
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				tot = tot + 1
				local has, _ = self:hasTools(p)
				if has then
					wi = wi + 1
					local bp = p:FindFirstChild("Backpack")
					if bp then
						for _, tool in ipairs(bp:GetChildren()) do
							if tool:IsA("Tool") then
								tool.Parent = LocalPlayer.Backpack
								cnt = cnt + 1
							end
						end
					end
					if p.Character then
						for _, tool in ipairs(p.Character:GetChildren()) do
							if tool:IsA("Tool") then
								tool.Parent = LocalPlayer.Backpack
								cnt = cnt + 1
							end
						end
					end
				else
					wo = wo + 1
				end
			end
		end
		if cnt > 0 then self:notify("Items", "Stolen "..cnt.." from "..wi.." players", 2)
		else self:notify("Items", "No items stolen ("..wo.." lacked items)", 2) end
	end)
	self:addItem("Equip All", "Items", false, function()
		local has, _ = self:hasTools(LocalPlayer)
		if not has then self:notify("Items", "No items to equip", 2) return end
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
				if tool:IsA("Tool") then hum:EquipTool(tool) end
			end
			self:notify("Items", "Equipped items", 2)
		end
	end)
	self:addItem("Clear Backpack", "Items", false, function()
		local c = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then tool:Destroy() c = c + 1 end
		end
		if c > 0 then self:notify("Items", "Cleared "..c.." items", 2)
		else self:notify("Items", "Backpack empty", 2) end
	end)
	self:addItem("Drop All", "Items", false, function()
		local c = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:FindFirstChild("Handle") then
					tool.Parent = Workspace
					local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrp then tool.Handle.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5),5,math.random(-5,5)) end
				else
					tool.Parent = Workspace
				end
				c = c + 1
			end
		end
		if c > 0 then self:notify("Items", "Dropped "..c.." items", 2)
		else self:notify("Items", "No items to drop", 2) end
	end)
	self:addItem("Duplicate All", "Items", false, function()
		local d = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local cl = tool:Clone()
				cl.Parent = LocalPlayer.Backpack
				d = d + 1
			end
		end
		self:notify("Items", "Duplicated "..d.." items", 2)
	end)
end

EndRegionUI.setupWorkspace = function(self)
	local frm = self.CatFrames["Workspace"]
	if not frm then return end
	self:addItem("Shader", "Workspace", false, function()
		if not self.ShaderOn then
			local f = Instance.new("Folder", Lighting)
			f.Name = "WorkspaceShaders"
			local bloom = Instance.new("BloomEffect", f)
			bloom.Intensity = 1.2
			bloom.Threshold = 2.5
			local cc = Instance.new("ColorCorrectionEffect", f)
			cc.Contrast = 0.35
			cc.Saturation = -0.2
			cc.TintColor = Color3.fromRGB(255,240,220)
			self.ShaderOn = true
			self:notify("Workspace", "Shader On", 2)
		else
			local f = Lighting:FindFirstChild("WorkspaceShaders")
			if f then f:Destroy() end
			self.ShaderOn = false
			self:notify("Workspace", "Shader Off", 2)
		end
	end)
	self:addItem("Daytime", "Workspace", false, function()
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		self:notify("Workspace", "Daytime set", 2)
	end)
	self:addItem("Nighttime", "Workspace", false, function()
		Lighting.ClockTime = 0
		Lighting.Brightness = 1
		self:notify("Workspace", "Nighttime set", 2)
	end)
	self:addItem("Rain", "Workspace", false, function()
		if not self.RainOn then
			local rp = Instance.new("Part")
			rp.Name = "RainPart"
			rp.Size = Vector3.new(1,1,1)
			rp.Transparency = 1
			rp.Anchored = true
			rp.CanCollide = false
			rp.Parent = Workspace
			rp.Position = Vector3.new(0,100,0)
			local pe = Instance.new("ParticleEmitter", rp)
			pe.Texture = "rbxassetid://489594173"
			pe.Lifetime = NumberRange.new(2,4)
			pe.Rate = 1000
			pe.Speed = NumberRange.new(50,60)
			pe.VelocitySpread = 180
			pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)})
			self.RainPart = rp
			self.RainOn = true
			self:notify("Workspace", "Rain On", 2)
		else
			if self.RainPart and self.RainPart.Parent then self.RainPart:Destroy() end
			self.RainOn = false
			self:notify("Workspace", "Rain Off", 2)
		end
	end)
	self:addItem("Set Global Gravity", "Workspace", true, function(val)
		local valid, num = self:checkInput(val, 0, 10000)
		if valid then
			Workspace.Gravity = num
			self:notify("Workspace", "Gravity set to "..num, 2)
		else
			self:notify("Workspace", "Invalid gravity", 2)
		end
	end)
end

EndRegionUI.setupPlayers = function(self)
	local frm = self.CatFrames["Players"]
	if not frm then return end
	self:addItem("TP to Random", "Players", false, function()
		local others = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(others, p)
			end
		end
		if #others > 0 then
			local targ = others[math.random(1,#others)]
			LocalPlayer.Character.HumanoidRootPart.CFrame = targ.Character.HumanoidRootPart.CFrame
			self:notify("Players", "TP to "..targ.Name, 2)
		else
			self:notify("Players", "No target", 2)
		end
	end, "Players")
	self:addItem("TP Behind Random", "Players", false, function()
		self:teleportBehindRandom()
	end, "Players")
	self:addItem("Play Animation", "Players", true, function(val)
		self:playAnim(val)
	end, "Players")
end

EndRegionUI.teleportBehindRandom = function(self)
	local others = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(others, p)
		end
	end
	if #others > 0 then
		local targ = others[math.random(1,#others)]
		local hrp = targ.Character:FindFirstChild("HumanoidRootPart")
		if hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hrp.Position - hrp.CFrame.LookVector * 5)
			self:notify("Players", "TP Behind "..targ.Name, 2)
		end
	else
		self:notify("Players", "No target found", 2)
	end
end

EndRegionUI.playAnim = function(self, animId)
	if not LocalPlayer.Character then
		self:notify("Animation", "Character not found", 2)
		return
	end
	local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		self:notify("Animation", "Humanoid not found", 2)
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..animId
	local track = hum:LoadAnimation(anim)
	track:Play()
	self:notify("Animation", "Playing "..animId, 2)
end

EndRegionUI.applySpin = function(self)
	EndRegionUI.Spin = not EndRegionUI.Spin
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if EndRegionUI.Spin then
		local bav = hrp:FindFirstChild("SpinAngularVelocity") or Instance.new("BodyAngularVelocity", hrp)
		bav.Name = "SpinAngularVelocity"
		bav.MaxTorque = Vector3.new(0, 1e6, 0)
		bav.AngularVelocity = Vector3.new(0, EndRegionUI.SpinSpeed, 0)
	else
		if hrp:FindFirstChild("SpinAngularVelocity") then hrp.SpinAngularVelocity:Destroy() end
	end
end

EndRegionUI.toggleNoclip = function(self)
	EndRegionUI.Noclip = not EndRegionUI.Noclip
end

EndRegionUI.toggleESP = function(self)
	EndRegionUI.ESPEnabled = not EndRegionUI.ESPEnabled
	if not EndRegionUI.ESPEnabled then
		for _, obj in pairs(EndRegionUI.ESPObjects) do
			if obj.box then obj.box:Remove() end
			if obj.label then obj.label:Remove() end
		end
		EndRegionUI.ESPObjects = {}
	end
end

RunService.RenderStepped:Connect(function()
	if EndRegionUI.ESPEnabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
				local head = player.Character.Head
				local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
				if onscreen then
					if not EndRegionUI.ESPObjects[player.Name] then
						local square = Drawing.new("Square")
						square.Visible = true
						square.Color = Color3.fromRGB(255,0,0)
						square.Thickness = 2
						square.Filled = false
						local label = Drawing.new("Text")
						label.Visible = true
						label.Text = player.Name
						label.Color = Color3.fromRGB(255,255,255)
						label.Size = 20
						label.Font = 2
						EndRegionUI.ESPObjects[player.Name] = {box = square, label = label}
					end
					local box = EndRegionUI.ESPObjects[player.Name].box
					local label = EndRegionUI.ESPObjects[player.Name].label
					box.Visible = true
					label.Visible = true
					box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
					box.Size = Vector2.new(50, 50)
					label.Position = Vector2.new(pos.X, pos.Y - 30)
				else
					if EndRegionUI.ESPObjects[player.Name] then
						EndRegionUI.ESPObjects[player.Name].box.Visible = false
						EndRegionUI.ESPObjects[player.Name].label.Visible = false
					end
				end
			end
		end
	end
end)

EndRegionUI.setupItems = function(self)
	local frm = self.CatFrames["Items"]
	if not frm then return end
	self:addItem("Steal Items", "Items", false, function()
		local tot, withItems, withoutItems, cnt = 0, 0, 0, 0
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				tot = tot + 1
				local has, _ = self:hasTools(p)
				if has then
					withItems = withItems + 1
					local bp = p:FindFirstChild("Backpack")
					if bp then
						for _, tool in ipairs(bp:GetChildren()) do
							if tool:IsA("Tool") then
								tool.Parent = LocalPlayer.Backpack
								cnt = cnt + 1
							end
						end
					end
					if p.Character then
						for _, tool in ipairs(p.Character:GetChildren()) do
							if tool:IsA("Tool") then
								tool.Parent = LocalPlayer.Backpack
								cnt = cnt + 1
							end
						end
					end
				else
					withoutItems = withoutItems + 1
				end
			end
		end
		if cnt > 0 then
			self:notify("Items", "Stolen "..cnt.." from "..withItems.." players", 2)
		else
			self:notify("Items", "No items stolen ("..withoutItems.." lacked items)", 2)
		end
	end, "Items")
	self:addItem("Equip All", "Items", false, function()
		local has, _ = self:hasTools(LocalPlayer)
		if not has then
			self:notify("Items", "No items to equip", 2)
			return
		end
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
				if tool:IsA("Tool") then hum:EquipTool(tool) end
			end
			self:notify("Items", "Equipped all items", 2)
		end
	end, "Items")
	self:addItem("Clear Backpack", "Items", false, function()
		local c = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
				c = c + 1
			end
		end
		if c > 0 then self:notify("Items", "Cleared "..c.." items", 2)
		else self:notify("Items", "Backpack empty", 2) end
	end, "Items")
	self:addItem("Drop All", "Items", false, function()
		local c = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if tool:FindFirstChild("Handle") then
					tool.Parent = Workspace
					local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if hrp then tool.Handle.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5),5,math.random(-5,5)) end
				else
					tool.Parent = Workspace
				end
				c = c + 1
			end
		end
		if c > 0 then self:notify("Items", "Dropped "..c.." items", 2)
		else self:notify("Items", "No items to drop", 2) end
	end, "Items")
	self:addItem("Duplicate All", "Items", false, function()
		local d = 0
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local dup = tool:Clone()
				dup.Parent = LocalPlayer.Backpack
				d = d + 1
			end
		end
		self:notify("Items", "Duplicated "..d.." items", 2)
	end, "Items")
end

EndRegionUI.setupWorkspace = function(self)
	local frm = self.CatFrames["Workspace"]
	if not frm then return end
	self:addItem("Shader", "Workspace", false, function()
		if not self.ShaderOn then
			local folder = Instance.new("Folder", Lighting)
			folder.Name = "WorkspaceShaders"
			local bloom = Instance.new("BloomEffect", folder)
			bloom.Intensity = 1.2
			bloom.Threshold = 2.5
			local cc = Instance.new("ColorCorrectionEffect", folder)
			cc.Contrast = 0.35
			cc.Saturation = -0.2
			cc.TintColor = Color3.fromRGB(255,240,220)
			self.ShaderOn = true
			self:notify("Workspace", "Shader On", 2)
		else
			local folder = Lighting:FindFirstChild("WorkspaceShaders")
			if folder then folder:Destroy() end
			self.ShaderOn = false
			self:notify("Workspace", "Shader Off", 2)
		end
	end, "Workspace")
	self:addItem("Daytime", "Workspace", false, function()
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		self:notify("Workspace", "Daytime set", 2)
	end, "Workspace")
	self:addItem("Nighttime", "Workspace", false, function()
		Lighting.ClockTime = 0
		Lighting.Brightness = 1
		self:notify("Workspace", "Nighttime set", 2)
	end, "Workspace")
	self:addItem("Rain", "Workspace", false, function()
		if not self.RainOn then
			local rp = Instance.new("Part")
			rp.Name = "RainPart"
			rp.Size = Vector3.new(1,1,1)
			rp.Transparency = 1
			rp.Anchored = true
			rp.CanCollide = false
			rp.Parent = Workspace
			rp.Position = Vector3.new(0,100,0)
			local pe = Instance.new("ParticleEmitter", rp)
			pe.Texture = "rbxassetid://489594173"
			pe.Lifetime = NumberRange.new(2,4)
			pe.Rate = 1000
			pe.Speed = NumberRange.new(50,60)
			pe.VelocitySpread = 180
			pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)})
			self.RainPart = rp
			self.RainOn = true
			self:notify("Workspace", "Rain On", 2)
		else
			if self.RainPart and self.RainPart.Parent then self.RainPart:Destroy() end
			self.RainOn = false
			self:notify("Workspace", "Rain Off", 2)
		end
	end, "Workspace")
	self:addItem("Set Global Gravity", "Workspace", true, function(val)
		local valid, num = self:checkInput(val, 0, 10000)
		if valid then
			Workspace.Gravity = num
			self:notify("Workspace", "Gravity set to "..num, 2)
		else
			self:notify("Workspace", "Invalid gravity", 2)
		end
	end, "Workspace")
end

EndRegionUI.setupPlayers = function(self)
	local frm = self.CatFrames["Players"]
	if not frm then return end
	self:addItem("TP to Random", "Players", false, function()
		local others = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(others, p)
			end
		end
		if #others > 0 then
			local targ = others[math.random(1,#others)]
			LocalPlayer.Character.HumanoidRootPart.CFrame = targ.Character.HumanoidRootPart.CFrame
			self:notify("Players", "TP to "..targ.Name, 2)
		else
			self:notify("Players", "No target", 2)
		end
	end, "Players")
	self:addItem("TP Behind Random", "Players", false, function()
		self:teleportBehindRandom()
	end, "Players")
	self:addItem("Play Animation", "Players", true, function(val)
		self:playAnim(val)
	end, "Players")
end

EndRegionUI.setupESP = function(self)
	if EndRegionUI.ESPEnabled then return end
	EndRegionUI.ESPEnabled = true
end

RunService.RenderStepped:Connect(function()
	if EndRegionUI.ESPEnabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
				local head = player.Character.Head
				local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
				if onscreen then
					if not EndRegionUI.ESPObjects[player.Name] then
						local box = Drawing.new("Square")
						box.Visible = true
						box.Color = Color3.new(1,0,0)
						box.Thickness = 2
						box.Filled = false
						local label = Drawing.new("Text")
						label.Visible = true
						label.Text = player.Name
						label.Color = Color3.new(1,1,1)
						label.Size = 20
						label.Font = 2
						EndRegionUI.ESPObjects[player.Name] = {box = box, label = label}
					end
					local esp = EndRegionUI.ESPObjects[player.Name]
					esp.box.Visible = true
					esp.label.Visible = true
					esp.box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
					esp.box.Size = Vector2.new(50,50)
					esp.label.Position = Vector2.new(pos.X, pos.Y - 30)
				else
					if EndRegionUI.ESPObjects[player.Name] then
						EndRegionUI.ESPObjects[player.Name].box.Visible = false
						EndRegionUI.ESPObjects[player.Name].label.Visible = false
					end
				end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if EndRegionUI.NoclipEnabled then
		local char = LocalPlayer.Character
		if char then
			for _, obj in ipairs(char:GetDescendants()) do
				if obj:IsA("BasePart") then obj.CanCollide = false end
			end
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			EndRegionUI.CurrentJumpCount = 0
		end
	end)
end)

if LocalPlayer.Character then
	local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.StateChanged:Connect(function(old, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				EndRegionUI.CurrentJumpCount = 0
			end
		end)
	end
end

UserInputService.JumpRequest:Connect(function()
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if EndRegionUI.InfJump then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			elseif EndRegionUI.MultiJump and EndRegionUI.CurrentJumpCount < EndRegionUI.MultiJumpMax then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				EndRegionUI.CurrentJumpCount = EndRegionUI.CurrentJumpCount + 1
			end
		end
	end
end)

VirtualUser:CaptureController()
LocalPlayer.Idled:Connect(function() VirtualUser:ClickButton2(Vector2.new()) end)

EndRegionUI.initUI = function(self)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then warn("PlayerGui not found.") return end
	local sg = CreateInstance("ScreenGui", {Name = "EndRegionUI", ResetOnSpawn = false})
	sg.Parent = pg
	self.ScreenGui = sg
	self.MainFrame = CreateInstance("Frame", {Name = "MainFrame", BackgroundColor3 = Color3.fromRGB(20,20,20), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,700,0,500), BorderSizePixel = 0, Active = true, Draggable = true})
	self.MainFrame.Parent = sg
	local mg = CreateInstance("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,10))}), Rotation = 45})
	mg.Parent = self.MainFrame
	local mc = CreateInstance("UICorner", {CornerRadius = UDim.new(0,12)})
	mc.Parent = self.MainFrame
	local tF = CreateInstance("Frame", {Name = "TitleFrame", BackgroundColor3 = Color3.fromRGB(15,15,15), Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,0), BorderSizePixel = 0})
	tF.Parent = self.MainFrame
	local tg = CreateInstance("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(100,100,100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,50))}), Rotation = 45})
	tg.Parent = tF
	local tc = CreateInstance("UICorner", {CornerRadius = UDim.new(0,12)})
	tc.Parent = tF
	local tL = CreateInstance("TextLabel", {Name = "TitleLabel", Text = "EndRegionUI", Font = Enum.Font.GothamBold, TextScaled = true, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0})
	tL.Parent = tF
	local ob = CreateInstance("TextButton", {Name = "OpenButton", Text = "", BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0,40,0,40), Position = UDim2.new(0,4,0,4)})
	local oc = CreateInstance("UICorner", {CornerRadius = UDim.new(1,0)})
	oc.Parent = ob
	ob.Parent = sg
	ob.MouseButton1Click:Connect(function()
		if EndRegionUI._db then return end
		EndRegionUI._db = true
		self.MainFrame.Visible = true
		ob.Visible = false
		delay(0.3, function() EndRegionUI._db = false end)
	end)
	local cb = CreateInstance("TextButton", {Name = "CloseButton", Text = "✕", Font = Enum.Font.GothamBold, TextScaled = true, BorderSizePixel = 0, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(200,50,50), TextColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-36,0,4)})
	local cc = CreateInstance("UICorner", {CornerRadius = UDim.new(1,0)})
	cc.Parent = cb
	cb.Parent = tF
	cb.MouseButton1Click:Connect(function()
		if EndRegionUI._db then return end
		EndRegionUI._db = true
		self.MainFrame.Visible = false
		ob.Visible = true
		delay(0.3, function() EndRegionUI._db = false end)
	end)
	self.CategoriesPanel = CreateInstance("ScrollingFrame", {Name = "CategoriesPanel", Size = UDim2.new(0,180,0,self.MainFrame.Size.Y.Offset-36), Position = UDim2.new(0,0,0,36), BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 4})
	local cp = CreateInstance("UIPadding", {PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)})
	cp.Parent = self.CategoriesPanel
	local cl = CreateInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
	cl.Parent = self.CategoriesPanel
	self:updateCanvas(self.CategoriesPanel)
	self.CategoriesPanel.Parent = self.MainFrame
	self.ContentArea = CreateInstance("Frame", {Name = "ContentArea", Size = UDim2.new(1,-180,1,-36), Position = UDim2.new(0,180,0,36), BorderSizePixel = 0, BackgroundTransparency = 1})
	local conC = CreateInstance("UICorner", {CornerRadius = UDim.new(0,8)})
	conC.Parent = self.ContentArea
	self.ContentArea.Parent = self.MainFrame
	self:addCat("Home")
	self:addCat("Player Mods")
	self:addCat("Items")
	self:addCat("Workspace")
	self:addCat("Players")
	self:setupHome()
	self:setupPlayerMods()
	self:setupItems()
	self:setupWorkspace()
	self:setupPlayers()
	self:switchCat("Home")
	self:notify("EndRegionUI", "Loaded Successfully", 3)
end

RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	if char and EndRegionUI.NoclipEnabled then
		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") then obj.CanCollide = false end
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			EndRegionUI.CurrentJumpCount = 0
		end
	end)
end)

if LocalPlayer.Character then
	local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.StateChanged:Connect(function(old, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				EndRegionUI.CurrentJumpCount = 0
			end
		end)
	end
end

UserInputService.JumpRequest:Connect(function()
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if EndRegionUI.InfJump then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			elseif EndRegionUI.MultiJump and EndRegionUI.CurrentJumpCount < EndRegionUI.MultiJumpMax then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				EndRegionUI.CurrentJumpCount = EndRegionUI.CurrentJumpCount + 1
			end
		end
	end
end)

VirtualUser:CaptureController()
LocalPlayer.Idled:Connect(function() VirtualUser:ClickButton2(Vector2.new()) end)

EndRegionUI:initUI()
return EndRegionUI