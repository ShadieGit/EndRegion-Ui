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

local ShadieUI = {}
ShadieUI.version = "4.0"
ShadieUI.signature = "SUI_SIGNATURE:4.0_Live"
ShadieUI.errors = {}
ShadieUI.highlights = {}
ShadieUI.espElements = {}
ShadieUI.categoryButtons = {}
ShadieUI.categoryFrames = {}
ShadieUI.categoryOrder = {}
ShadieUI.features = {ESP = false, Spin = false, NoClip = false, BunnyHop = false, InfinityJump = false, Highlights = false, DayNightCycle = false}
ShadieUI.lastNotifs = {}
ShadieUI.lastBunnyTime = 0
ShadieUI.spinSpeed = 5
ShadieUI.remoteCode = nil
ShadieUI.updateAvailable = false
ShadieUI.updateApplied = false
ShadieUI.updatePromptShown = false
ShadieUI.featureCallbacks = {}

function ShadieUI:flipFeature(feature)
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

ShadieUI.featureCallbacks["Spin"] = {
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

function ShadieUI:logError(msg)
        table.insert(self.errors, {time = os.time(), error = msg})
        warn("Error:", msg)
end

function ShadieUI:notify(title, text, duration)
        title = title or "ShadieUI"
        duration = duration or 2
        local now = tick()
        self.lastNotifs = self.lastNotifs or {}
        local key = title .. ":" .. text
        if self.lastNotifs[key] and (now - self.lastNotifs[key] < duration) then return end
        self.lastNotifs[key] = now
        pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration}) end)
        print("[" .. title .. "] " .. text)
end

function ShadieUI:checkInput(value, minVal, maxVal)
        local num = tonumber(value)
        if num and num >= minVal and num <= maxVal then
                return true, num
        end
        return false, num
end

function ShadieUI:addPage(pageName)
        assert(type(pageName) == "string" and pageName ~= "", "Invalid page name!")
        local btn = createInstance("TextButton", {
                Name = pageName.."Btn",
                Text = pageName,
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
        self.categoryButtons[pageName] = btn
        self.categoryOrder[pageName] = 0
        btn.MouseButton1Click:Connect(function() self:switchPage(pageName) end)
        local frame = createInstance("ScrollingFrame", {
                Name = pageName.."Frame",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollingEnabled = true,
                BackgroundColor3 = Color3.fromRGB(30,30,30),
                Position = UDim2.new(0,0,0,0)
        })
        local layout = createInstance("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
        layout.Parent = frame
        frame.Parent = self.contentArea
        self.categoryFrames[pageName] = frame
        frame.Visible = false
end

--[[
        Instead of createItem, we now use addButton to add a UI button/control.
]]
function ShadieUI:addButton(itemName, page, hasInput, action)
        assert(type(itemName) == "string" and itemName ~= "", "Invalid item name")
        assert(type(page) == "string" and page ~= "", "Invalid page")
        assert(type(hasInput) == "boolean", "hasInput must be boolean")
        assert(type(action) == "function", "Callback must be a function")
        local parent = self.categoryFrames[page]
        if not parent then
                self:notify("Error", "Page '"..page.."' missing", 2)
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
        container.LayoutOrder = self.categoryOrder[page] or 0
        self.categoryOrder[page] = self.categoryOrder[page] + 1
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

function ShadieUI:playOpeningAnim()
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local goal = {BackgroundTransparency = 0.1, Size = UDim2.new(0,700,0,400), Position = UDim2.new(0.5, -350, 0.5, -200)}
        local tween = TweenService:Create(self.mainFrame, tweenInfo, goal)
        self.mainFrame.Visible = true
        tween:Play()
end

function ShadieUI:playClosingAnim()
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local goal = {BackgroundTransparency = 1, Size = UDim2.new(0,350,0,200), Position = UDim2.new(0.5, -175, 0.5, -100)}
        local tween = TweenService:Create(self.mainFrame, tweenInfo, goal)
        tween:Play()
        tween.Completed:Connect(function()
                self.mainFrame.Visible = false
        end)
end

function ShadieUI:switchPage(pageName)
        if self.categoryFrames and self.categoryFrames[pageName] then
                local currentPage
                for name, frame in pairs(self.categoryFrames) do
                        if frame.Visible then
                                currentPage = frame
                        end
                end
                local newPage = self.categoryFrames[pageName]
                if currentPage then
                        local tweenOut = TweenService:Create(currentPage, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(-1,0,0,0)})
                        tweenOut:Play()
                        tweenOut.Completed:Connect(function()
                                currentPage.Visible = false
                        end)
                end
                newPage.Position = UDim2.new(1,0,0,0)
                newPage.Visible = true
                local tweenIn = TweenService:Create(newPage, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)})
                tweenIn:Play()
        else
                self:notify("Error", "Page '" .. tostring(pageName) .. "' not found", 2)
        end
end

function ShadieUI:initializeCategories()
        local pages = {"Home", "Local", "Player", "Workspace", "Backpack"}
        for _, p in ipairs(pages) do
                self:addPage(p)
        end
        self:switchPage("Home")
end

function ShadieUI:initializeUI()
        local pg = player:WaitForChild("PlayerGui")
        local sg = createInstance("ScreenGui", {Name = "ShadieUI_Main", ResetOnSpawn = false})
        sg.Parent = pg
        self.screenGui = sg
        local mainFrame = createInstance("Frame", {
                Name = "MainFrame",
                Size = UDim2.new(0,700,0,400),
                Position = UDim2.new(0.5, -350, 0.5, -200),
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

function ShadieUI:setupHome()
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
end

function ShadieUI:setupLocal()
        local frame = self.categoryFrames["Local"]
        if not frame then return end
        self:addButton("Set Walk Speed", "Local", true, function(value)
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
        self:addButton("Set Jump Power", "Local", true, function(value)
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
        self:addButton("Set Gravity", "Local", true, function(value)
                local valid, num = self:checkInput(value, 0, 10000)
                if valid then
                        Workspace.Gravity = num
                        self:notify("Local", "Gravity set to " .. num, 2)
                else
                        self:notify("Local", "Invalid gravity value", 2)
                end
        end)
        self:addButton("Set Hip Height", "Local", true, function(value)
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
        self:addButton("NoClip", "Local", false, function()
                self:flipFeature("NoClip")
        end)
        self:addButton("Spin (enter speed)", "Local", true, function(value)
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
        self:addButton("Platform Stand", "Local", false, function()
                local char = player.Character
                if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                                hum.PlatformStand = not hum.PlatformStand
                                self:notify("Local", "Platform Stand " .. (hum.PlatformStand and "Enabled" or "Disabled"), 2)
                        end
                end
        end)
        self:addButton("Bunny Hop", "Local", false, function()
                self:flipFeature("BunnyHop")
        end)
        self:addButton("Infinity Jump", "Local", false, function()
                self:flipFeature("InfinityJump")
        end)
        self:addButton("Reset Stats", "Local", false, function()
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
        self:addButton("Respawn", "Local", false, function()
                if player.Character then
                        player.Character:BreakJoints()
                        self:notify("Local", "Respawn triggered", 2)
                end
        end)
        self:addButton("Play Animation", "Local", true, function(animId)
                self:playAnimation(animId)
        end)
end

function ShadieUI:setupPlayer()
        local frame = self.categoryFrames["Player"]
        if not frame then return end
        self:addButton("ESP", "Player", false, function()
                self:flipFeature("ESP")
        end)
        self:addButton("Highlights", "Player", false, function()
                self:flipFeature("Highlights")
        end)
        self:addButton("Teleport Random", "Player", false, function()
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
        self:addButton("Teleport Behind", "Player", false, function()
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

function ShadieUI:setupWorkspace()
        local frame = self.categoryFrames["Workspace"]
        if not frame then return end
        self:addButton("Day-Night Cycle", "Workspace", false, function()
                if not self.features.DayNightCycle then
                        self:startDayNightCycle()
                        self:notify("Workspace", "Day-Night Cycle Started", 2)
                else
                        self:stopDayNightCycle()
                        self:notify("Workspace", "Day-Night Cycle Stopped", 2)
                end
                self:flipFeature("DayNightCycle")
        end)
        self:addButton("Gravity", "Workspace", true, function(value)
                local valid, num = self:checkInput(value, 0, 10000)
                if valid then
                        Workspace.Gravity = num
                        self:notify("Workspace", "Gravity set to " .. num, 2)
                else
                        self:notify("Workspace", "Invalid gravity value", 2)
                end
        end)
        self:addButton("Camera FOV", "Workspace", true, function(value)
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
        self:addButton("Camera Min Zoom", "Workspace", true, function(value)
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
        self:addButton("Camera Max Zoom", "Workspace", true, function(value)
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
        self:addButton("Steal Items", "Backpack", false, function()
                local stolen, withItems, withoutItems = 0, 0, 0
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
                                        withItems = withItems + 1
                                else
                                        withoutItems = withoutItems + 1
                                end
                        end
                end
                if stolen > 0 then
                        self:notify("Backpack", "Stolen " .. stolen .. " items from " .. withItems .. " players", 2)
                else
                        self:notify("Backpack", "No tools stolen (" .. withoutItems .. " without tools)", 2)
                end
        end)
        self:addButton("Equip All", "Backpack", false, function()
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
        self:addButton("Clear Backpack", "Backpack", false, function()
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
        self:addButton("Drop All", "Backpack", false, function()
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
        self:addButton("Duplicate All", "Backpack", false, function()
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

function ShadieUI:playAnimation(animId)
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

function ShadieUI:startDayNightCycle()
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

function ShadieUI:stopDayNightCycle()
        if self.features.DayNightCycle and self.dayNightConn then
                self.dayNightConn:Disconnect()
                self.features.DayNightCycle = false
        end
end

local function updateESP()
        if ShadieUI.features.ESP then
                local myHead = player.Character and player.Character:FindFirstChild("Head")
                local myPos = myHead and myHead.Position
                for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                                local otherHead = p.Character.Head
                                local pos, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(otherHead.Position)
                                if onscreen then
                                        if not ShadieUI.espElements[p.Name] then
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
                                                ShadieUI.espElements[p.Name] = {box = box, tracer = tracer, label = label}
                                        end
                                        local esp = ShadieUI.espElements[p.Name]
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
                                        if ShadieUI.espElements[p.Name] then
                                                ShadieUI.espElements[p.Name].box.Visible = false
                                                ShadieUI.espElements[p.Name].tracer.Visible = false
                                                ShadieUI.espElements[p.Name].label.Visible = false
                                        end
                                end
                        end
                end
        else
                for _, esp in pairs(ShadieUI.espElements) do
                        if esp.box then esp.box:Remove() end
                        if esp.tracer then esp.tracer:Remove() end
                        if esp.label then esp.label:Remove() end
                end
                ShadieUI.espElements = {}
        end
end

local function updateNoClipBunny()
        local char = player.Character
        if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and ShadieUI.features.NoClip then
                        for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                        end
                end
                if ShadieUI.features.BunnyHop then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                                if tick() - ShadieUI.lastBunnyTime > 0.2 then
                                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                                        ShadieUI.lastBunnyTime = tick()
                                end
                        end
                end
        end
end

RunService.RenderStepped:Connect(function() updateNoClipBunny() end)

local function resetJumpCount(char)
        local hum = char:WaitForChild("Humanoid")
        hum.StateChanged:Connect(function(_, new)
                if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
                        ShadieUI.currentJumpCount = 0
                end
        end)
end

local function onCharacterAdded(char)
        resetJumpCount(char)
        ShadieUI.features.Spin = false
        ShadieUI.features.NoClip = false
        ShadieUI.features.BunnyHop = false
        ShadieUI.features.InfinityJump = false
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
        resetJumpCount(player.Character)
        ShadieUI.features.Spin = false
        ShadieUI.features.NoClip = false
        ShadieUI.features.BunnyHop = false
        ShadieUI.features.InfinityJump = false
end

UserInputService.JumpRequest:Connect(function()
        if ShadieUI.features.InfinityJump then
                local char = player.Character
                if char then
                        local hum = char:FindFirstChildWhichIsA("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
        end
end)

VirtualUser:CaptureController()
player.Idled:Connect(function() pcall(function() VirtualUser:ClickButton2(Vector2.new(0,0)) end) end)

ShadieUI:initializeUI()
ShadieUI:initializeCategories()
ShadieUI:setupHome()
ShadieUI:setupLocal()
ShadieUI:setupPlayer()
ShadieUI:setupWorkspace()
ShadieUI:setupBackpack()
ShadieUI:notify("ShadieUI", "Loaded Successfully", 3)

return ShadieUI