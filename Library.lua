--[[
    Valincia UI Library v1.0.0
    Single-file loadstring-compatible UI library for Roblox executors.
    Usage: local Library = loadstring(game:HttpGet("url/Library.lua"))()
    
    API modeled after LinoriaLib/Obsidian.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
--// Icon Module \\--
type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

--// Utils \\--
--------------------------------------------------------------------------------
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return setmetatable(copy, getmetatable(t))
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t) return a + (b - a) * t end
local function roundTo(v, step)
    if step == 0 then return v end
    return math.floor(v / step + 0.5) * step
end

local function uuid()
    local chars = "0123456789abcdef"
    local parts = {}
    for i = 1, 8 do parts[i] = chars:sub(math.random(1, 16), math.random(1, 16)) end
    return table.concat(parts)
end

local function keyCodeToString(kc)
    local name = tostring(kc)
    return name:gsub("Enum.KeyCode.", "")
end

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- Signal (lightweight event system)
--------------------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _listeners = {}, _destroyed = false }, Signal)
end

function Signal:Connect(fn)
    if self._destroyed then return { Disconnect = function() end } end
    local conn = { _fn = fn, _connected = true }
    function conn:Disconnect() self._connected = false end
    table.insert(self._listeners, conn)
    return conn
end

function Signal:Fire(...)
    for _, c in ipairs(self._listeners) do
        if c._connected then task.spawn(c._fn, ...) end
    end
end

function Signal:Destroy()
    self._listeners = {}
    self._destroyed = true
end

--------------------------------------------------------------------------------
-- Library (top-level)
--------------------------------------------------------------------------------
local Library = {
    Version = "1.0.0",
    Name = "Valincia",
    Toggles = {},
    Options = {},
    _windows = {},
    _connections = {},
    _unloaded = false,
    ForceCheckbox = false,
    ToggleKeybind = nil,
    _screenGui = nil,
}

function Library:SafeCallback(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Valincia] Callback error:", err) end
end

function Library:GetIcon(IconName: string)
    if not FetchIcons then return end
    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then return end
    return Icon
end

function Library:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self._connections, conn)
    return conn
end

function Library:Unload()
    if self._unloaded then return end
    self._unloaded = true
    
    for _, c in ipairs(self._connections) do
        if c and c.Connected then c:Disconnect() end
    end
    self._connections = {}

    if self._screenGui then
        self._screenGui:Destroy()
        self._screenGui = nil
    end
    self.Toggles = {}
    self.Options = {}
    self._windows = {}
end
Library.Destroy = Library.Unload

function Library:Notify(config)
    config = config or {}
    local text = config.Text or config.Title or "Notification"
    local duration = config.Duration or 3

    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 220, 0, 36)
    notif.Position = UDim2.new(1, -230, 1, -50)
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notif.TextColor3 = Color3.fromRGB(220, 220, 220)
    notif.Text = "  " .. text
    notif.TextSize = 12
    notif.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    notif.TextXAlignment = Enum.TextXAlignment.Left
    notif.BorderSizePixel = 0
    notif.ZIndex = 9999

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = notif

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(60, 60, 60)
    s.Thickness = 1
    s.Parent = notif

    notif.Parent = self._screenGui

    task.delay(duration, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TWEEN_MED, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
            task.wait(0.3)
            notif:Destroy()
        end
    end)
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
local Window = {}
Window.__index = Window

function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Valincia"
    local footer = config.Footer or "v" .. self.Version
    local size = config.Size or UDim2.new(0, 550, 0, 380)
    local center = config.Center ~= false
    local autoShow = config.AutoShow ~= false
    local toggleKey = config.ToggleKeybind or Enum.KeyCode.RightControl

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ValinciaUI_" .. uuid()
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    local ok = pcall(function() screenGui.Parent = CoreGui end)
    if not ok then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    self._screenGui = screenGui

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = size
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    main.BorderSizePixel = 0
    main.Visible = autoShow
    main.Parent = screenGui

    if center then
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
    else
        main.Position = config.Position or UDim2.new(0.5, -275, 0.5, -190)
    end

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(50, 50, 50)
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = main

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 8)
    tbCorner.Parent = titleBar

    -- Fix bottom corners
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 10)
    tbFix.Position = UDim2.new(0, 0, 1, -10)
    tbFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    -- Header Icon
    local headerIconId = config.Icon
    local titlePositionX = 12

    if headerIconId then
        local headerIcon = Instance.new("ImageLabel")
        headerIcon.Name = "HeaderIcon"
        headerIcon.Size = UDim2.new(0, 20, 0, 20)
        headerIcon.Position = UDim2.new(0, 8, 0, 8)
        headerIcon.BackgroundTransparency = 1
        headerIcon.Image = "rbxassetid://" .. tostring(headerIconId)
        headerIcon.Parent = titleBar
        
        titlePositionX = 36 -- Shift title to the right
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -16 - titlePositionX, 1, 0)
    titleLabel.Position = UDim2.new(0, titlePositionX, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 14
    titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local footerLabel = Instance.new("TextLabel")
    footerLabel.Name = "Footer"
    footerLabel.Size = UDim2.new(0, 120, 0, 20)
    footerLabel.Position = UDim2.new(0, 8, 1, -24)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Text = footer
    footerLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    footerLabel.TextSize = 11
    footerLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    footerLabel.TextXAlignment = Enum.TextXAlignment.Left
    footerLabel.ZIndex = 5
    footerLabel.Parent = main

    -- Drag logic
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    self:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    self:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Sidebar (tab buttons)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, -38)
    sidebar.Position = UDim2.new(0, 0, 0, 36)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = main

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.FillDirection = Enum.FillDirection.Vertical
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 2)
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 6)
    sidebarPadding.PaddingLeft = UDim.new(0, 6)
    sidebarPadding.PaddingRight = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    -- Tab content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -142, 1, -38)
    contentArea.Position = UDim2.new(0, 141, 0, 36)
    contentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contentArea.BorderSizePixel = 0
    contentArea.ClipsDescendants = true
    contentArea.Parent = main

    -- Divider line between sidebar and content
    local dividerLine = Instance.new("Frame")
    dividerLine.Size = UDim2.new(0, 1, 1, -38)
    dividerLine.Position = UDim2.new(0, 140, 0, 36)
    dividerLine.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dividerLine.BorderSizePixel = 0
    dividerLine.Parent = main

    -- Minimize Button (-)
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, 36, 1, 0)
    minBtn.Position = UDim2.new(1, -72, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = ""
    minBtn.ZIndex = 11
    minBtn.Parent = titleBar

    local minIconImg = Instance.new("ImageLabel")
    minIconImg.Name = "Icon"
    minIconImg.Size = UDim2.new(0, 20, 0, 20)
    minIconImg.AnchorPoint = Vector2.new(0.5, 0.5)
    minIconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    minIconImg.BackgroundTransparency = 1
    minIconImg.ImageColor3 = Color3.fromRGB(150, 150, 150)
    minIconImg.ZIndex = 12
    minIconImg.Parent = minBtn

    local minIcon = Library:GetIcon("minus")
    if minIcon then
        minIconImg.Image = minIcon.Url
        minIconImg.ImageRectOffset = minIcon.ImageRectOffset
        minIconImg.ImageRectSize = minIcon.ImageRectSize
    else
        minIconImg.Image = "rbxassetid://9886659406"
    end

    self:Connect(minBtn.MouseEnter, function() minIconImg.ImageColor3 = Color3.fromRGB(200, 200, 200) end)
    self:Connect(minBtn.MouseLeave, function() minIconImg.ImageColor3 = Color3.fromRGB(150, 150, 150) end)

    -- Close Button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 36, 1, 0)
    closeBtn.Position = UDim2.new(1, -36, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.ZIndex = 11
    closeBtn.Parent = titleBar

    local closeIconImg = Instance.new("ImageLabel")
    closeIconImg.Name = "Icon"
    closeIconImg.Size = UDim2.new(0, 20, 0, 20)
    closeIconImg.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIconImg.BackgroundTransparency = 1
    closeIconImg.ImageColor3 = Color3.fromRGB(150, 150, 150)
    closeIconImg.ZIndex = 12
    closeIconImg.Parent = closeBtn

    local closeIcon = Library:GetIcon("x")
    if closeIcon then
        closeIconImg.Image = closeIcon.Url
        closeIconImg.ImageRectOffset = closeIcon.ImageRectOffset
        closeIconImg.ImageRectSize = closeIcon.ImageRectSize
    else
        closeIconImg.Image = "rbxassetid://9886659671"
    end

    self:Connect(closeBtn.MouseEnter, function() closeIconImg.ImageColor3 = Color3.fromRGB(255, 80, 80) end)
    self:Connect(closeBtn.MouseLeave, function() closeIconImg.ImageColor3 = Color3.fromRGB(150, 150, 150) end)

    minBtn.MouseButton1Click:Connect(function()
        Window:Toggle(false)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Library:Unload()
    end)

    -- Floating Open Button (Right center of screen)
    local openBtn = Instance.new("TextButton") -- Changed to TextButton to be container
    openBtn.Name = "OpenButton"
    openBtn.Text = ""
    openBtn.Size = UDim2.new(0, 50, 0, 50)
    openBtn.Position = UDim2.new(1, -60, 0.5, -25)
    openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    openBtn.BackgroundTransparency = 0.2
    openBtn.Visible = false
    openBtn.Parent = screenGui
    
    local openCorner = Instance.new("UICorner")
    openCorner.CornerRadius = UDim.new(1, 0) -- Circle
    openCorner.Parent = openBtn
    
    local openStroke = Instance.new("UIStroke")
    openStroke.Color = Color3.fromRGB(60, 60, 60)
    openStroke.Thickness = 1
    openStroke.Parent = openBtn

    local openIcon = Instance.new("ImageLabel")
    openIcon.Name = "Icon"
    openIcon.Size = UDim2.new(1, 0, 1, 0) -- Full size
    openIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    openIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    openIcon.BackgroundTransparency = 1
    openIcon.Parent = openBtn
    
    local openImageId = config.OpenImageId or config.Icon
    if openImageId then
        if type(openImageId) == "number" then
            openIcon.Image = string.format("rbxassetid://%.0f", openImageId)
        else
            openIcon.Image = "rbxassetid://" .. tostring(openImageId)
        end
    end
    
    -- Draggable Floating Button
    local draggingOpen, dragStartOpen, startPosOpen
    openBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingOpen = true
            dragStartOpen = input.Position
            startPosOpen = openBtn.Position
        end
    end)
    self:Connect(UserInputService.InputChanged, function(input)
        if draggingOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartOpen
            openBtn.Position = UDim2.new(startPosOpen.X.Scale, startPosOpen.X.Offset + delta.X, startPosOpen.Y.Scale, startPosOpen.Y.Offset + delta.Y)
        end
    end)
    self:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingOpen = false
        end
    end)

    -- Toggle Logic
    local function setVisible(vis)
        main.Visible = vis
        openBtn.Visible = not vis
    end
    
    openBtn.MouseButton1Click:Connect(function()
        setVisible(true)
    end)
    
    minBtn.MouseButton1Click:Connect(function()
        setVisible(false)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Unload()
    end)

    -- Resize Handle (Bottom Right)
    local resizeHandle = Instance.new("ImageButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.Position = UDim2.new(1, -16, 1, -16)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Image = "rbxassetid://10656726569" -- Resize corner icon
    resizeHandle.ImageColor3 = Color3.fromRGB(150, 150, 150)
    resizeHandle.ImageTransparency = 0.5
    resizeHandle.Parent = main

    local resizing, resizeStart, startSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = main.AbsoluteSize
        end
    end)

    self:Connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newX = math.max(300, startSize.X + delta.X)
            local newY = math.max(200, startSize.Y + delta.Y)
            main.Size = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    self:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    -- Toggle keybind
    self.ToggleKeybind = toggleKey
    self:Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKeybind then
            setVisible(not main.Visible)
        end
    end)

    -- Initial state
    if not autoShow then setVisible(false) end

    local w = setmetatable({
        _library = self,
        _main = main,
        _sidebar = sidebar,
        _contentArea = contentArea,
        _titleLabel = titleLabel,
        _footerLabel = footerLabel,
        _tabs = {},
        _activeTab = nil,
    }, Window)

    table.insert(self._windows, w)
    return w
end

function Window:SetTitle(t) self._titleLabel.Text = t end
function Window:GetTitle() return self._titleLabel.Text end

function Window:AddTab(name, icon)
    local tab = Tab.new(self, name, icon)
    table.insert(self._tabs, tab)

    if #self._tabs == 1 then
        self:_switchTab(tab)
    end

    return tab
end

function Window:_switchTab(tab)
    if self._activeTab == tab then return end

    for _, t in ipairs(self._tabs) do
        t._contentFrame.Visible = (t == tab)
        t._tabButton.BackgroundColor3 = (t == tab)
            and Color3.fromRGB(40, 40, 40)
            or Color3.fromRGB(20, 20, 20)
        t._tabButton.TextColor3 = (t == tab)
            and Color3.fromRGB(240, 240, 240)
            or Color3.fromRGB(140, 140, 140)
    end

    self._activeTab = tab
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------
Tab = {}
Tab.__index = Tab

function Tab.new(window, name, icon)
    local self = setmetatable({}, Tab)
    self._window = window
    self._name = name

    -- Tab button in sidebar
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    tabBtn.TextSize = 12
    tabBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.AutoButtonColor = false
    tabBtn.LayoutOrder = #window._tabs + 1
    tabBtn.Parent = window._sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 10)
    btnPad.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        window:_switchTab(self)
    end)

    -- Content frame (single column)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "TabContent_" .. name
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 3
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Visible = false
    contentFrame.Parent = window._contentArea

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = contentFrame

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingTop = UDim.new(0, 10)
    contentPad.PaddingLeft = UDim.new(0, 10)
    contentPad.PaddingRight = UDim.new(0, 10)
    contentPad.PaddingBottom = UDim.new(0, 10)
    contentPad.Parent = contentFrame

    self._tabButton = tabBtn
    self._contentFrame = contentFrame

    return self
end

function Tab:AddGroupbox(title)
    return Groupbox.new(self._contentFrame, title, self._window._library)
end

function Tab:AddLeftGroupbox(title) return self:AddGroupbox(title) end
function Tab:AddRightGroupbox(title) return self:AddGroupbox(title) end
function Tab:AddTabbox(title) return Tabbox.new(self._contentFrame, title, self._window._library) end
function Tab:AddLeftTabbox(title) return self:AddTabbox(title) end
function Tab:AddRightTabbox(title) return self:AddTabbox(title) end

--------------------------------------------------------------------------------
-- Groupbox
--------------------------------------------------------------------------------
Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox.new(parent, title, library)
    local self = setmetatable({}, Groupbox)
    self._library = library
    self._title = title

    local container = Instance.new("Frame")
    container.Name = "Groupbox_" .. (title or "")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 45, 45)
    stroke.Thickness = 1
    stroke.Parent = container

    -- Title
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -16, 0, 22)
        titleLabel.Position = UDim2.new(0, 8, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        titleLabel.TextSize = 12
        titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.LayoutOrder = 0
        titleLabel.Parent = container
    end

    -- Content within groupbox
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 0, 0)
    content.Position = UDim2.new(0, 8, 0, title and 28 or 8)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.Parent = container

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = content

    local bottomPad = Instance.new("UIPadding")
    bottomPad.PaddingBottom = UDim.new(0, 8)
    bottomPad.Parent = content

    self._container = container
    self._content = content
    self._elementCount = 0

    return self
end

function Groupbox:_nextOrder()
    self._elementCount = self._elementCount + 1
    return self._elementCount
end

--------------------------------------------------------------------------------
-- Element: Toggle
--------------------------------------------------------------------------------
local ToggleClass = {}
ToggleClass.__index = ToggleClass

function Groupbox:AddToggle(flag, config)
    config = config or {}
    local text = config.Text or flag
    local default = config.Default or false
    local callback = config.Callback
    local order = self:_nextOrder()

    local toggle = setmetatable({}, ToggleClass)
    toggle.Value = default
    toggle.OnChanged = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. flag
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = container

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -50, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    textLabel.TextSize = 12
    textLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 36, 0, 18)
    track.Position = UDim2.new(1, -40, 0.5, -9)
    track.BackgroundColor3 = default and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(50, 50, 50) -- Blue / Dark Grey
    track.BorderSizePixel = 0
    track.Parent = container

    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function updateVisual(val, animate)
        -- High contrast colors: Bright Blue for ON, Dark Grey for OFF
        local targetTrack = val and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(50, 50, 50)
        local targetKnob = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        
        if animate then
            TweenService:Create(track, TWEEN_FAST, { BackgroundColor3 = targetTrack }):Play()
            TweenService:Create(knob, TWEEN_FAST, { Position = targetKnob }):Play()
        else
            track.BackgroundColor3 = targetTrack
            knob.Position = targetKnob
        end
    end

    function toggle:SetValue(val)
        if toggle.Value == val then return end
        toggle.Value = val
        updateVisual(val, true)
        toggle.OnChanged:Fire(val)
        if callback then Library:SafeCallback(callback, val) end
    end

    function toggle:GetValue() return toggle.Value end

    clickArea.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)

    toggle._container = container
    toggle._textLabel = textLabel
    toggle._track = track
    toggle._knob = knob

    -- Register
    if flag and flag ~= "" then
        self._library.Toggles[flag] = toggle
    end

    return toggle
end

--------------------------------------------------------------------------------
-- Element: Slider
--------------------------------------------------------------------------------
local SliderClass = {}
SliderClass.__index = SliderClass

function Groupbox:AddSlider(flag, config)
    config = config or {}
    local text = config.Text or flag
    local min = config.Min or 0
    local max = config.Max or 100
    local default = clamp(config.Default or min, min, max)
    local rounding = config.Rounding or 0
    local suffix = config.Suffix or ""
    local callback = config.Callback
    local order = self:_nextOrder()

    local slider = setmetatable({}, SliderClass)
    slider.Value = default
    slider.Min = min
    slider.Max = max
    slider.OnChanged = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. flag
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 16)
    header.BackgroundTransparency = 1
    header.Parent = container

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.7, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    textLabel.TextSize = 12
    textLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = header

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    valueLabel.TextSize = 12
    valueLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = header

    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.new(1, 0, 0, 6)
    trackFrame.Position = UDim2.new(0, 0, 0, 22)
    trackFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    trackFrame.BorderSizePixel = 0
    trackFrame.Parent = container
    Instance.new("UICorner", trackFrame).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(96, 130, 255)
    fill.BorderSizePixel = 0
    fill.Parent = trackFrame
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 0, 20)
    clickArea.Position = UDim2.new(0, 0, 0, 14)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 3
    clickArea.Parent = container

    local function formatVal(v)
        if rounding == 0 then return tostring(math.floor(v)) .. suffix end
        return string.format("%." .. rounding .. "f", v) .. suffix
    end

    local function updateVisual(v)
        local pct = (v - min) / math.max(max - min, 0.001)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = formatVal(v)
    end

    function slider:SetValue(v)
        v = clamp(v, min, max)
        if rounding == 0 then v = math.floor(v + 0.5) else v = roundTo(v, 10 ^ -rounding) end
        if slider.Value == v then return end
        slider.Value = v
        updateVisual(v)
        slider.OnChanged:Fire(v)
        if callback then Library:SafeCallback(callback, v) end
    end
    function slider:GetValue() return slider.Value end

    local isDragging = false
    local function update(inputPos)
        local absX = trackFrame.AbsolutePosition.X
        local absW = trackFrame.AbsoluteSize.X
        if absW == 0 then return end
        local pct = clamp((inputPos.X - absX) / absW, 0, 1)
        local raw = lerp(min, max, pct)
        slider:SetValue(raw)
    end

    clickArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            update(input.Position)
        end
    end)
    self._library:Connect(UserInputService.InputChanged, function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)
    self._library:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    updateVisual(default)

    if flag and flag ~= "" then self._library.Options[flag] = slider end
    return slider
end

--------------------------------------------------------------------------------
-- Element: Dropdown
--------------------------------------------------------------------------------
local DropdownClass = {}
DropdownClass.__index = DropdownClass

function Groupbox:AddDropdown(flag, config)
    config = config or {}
    local text = config.Text or flag
    local options = config.Values or config.Options or {}
    local default = config.Default
    local multi = config.Multi or false
    local callback = config.Callback
    local order = self:_nextOrder()

    local dropdown = setmetatable({}, DropdownClass)
    dropdown.Value = multi and (default or {}) or default
    dropdown.Options = options
    dropdown.OnChanged = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. flag
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1
    label.Parent = container

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 28)
    mainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainBtn.BorderSizePixel = 0
    mainBtn.Text = "" -- Handled by child label
    mainBtn.AutoButtonColor = false
    mainBtn.LayoutOrder = 2
    mainBtn.Parent = container

    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)
    local btnStroke = Instance.new("UIStroke", mainBtn)
    btnStroke.Color = Color3.fromRGB(60, 60, 60); btnStroke.Thickness = 1
    
    -- Value Display Label (Truncates correctly)
    local valLabel = Instance.new("TextLabel")
    valLabel.Name = "Value"
    valLabel.Size = UDim2.new(1, -44, 1, 0) -- Leave room for chevron (was -32)
    valLabel.Position = UDim2.new(0, 8, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = ""
    valLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    valLabel.TextSize = 12
    valLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    valLabel.TextXAlignment = Enum.TextXAlignment.Left
    valLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valLabel.Parent = mainBtn

    -- Chevron Icon
    local chevIcon = Library:GetIcon("chevron-down")
    local chevImg = Instance.new("ImageLabel")
    chevImg.Name = "Chevron"
    chevImg.Size = UDim2.new(0, 16, 0, 16)
    chevImg.Position = UDim2.new(1, -24, 0.5, -8)
    chevImg.BackgroundTransparency = 1
    chevImg.ImageColor3 = Color3.fromRGB(150, 150, 150)
    if chevIcon then
        chevImg.Image = chevIcon.Url
        chevImg.ImageRectOffset = chevIcon.ImageRectOffset
        chevImg.ImageRectSize = chevIcon.ImageRectSize
    else
        chevImg.Image = "rbxassetid://6031091004"
    end
    chevImg.Parent = mainBtn

    local optFrame = Instance.new("Frame")
    optFrame.Size = UDim2.new(1, 0, 0, 0)
    optFrame.AutomaticSize = Enum.AutomaticSize.Y
    optFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    optFrame.BorderSizePixel = 0
    optFrame.Visible = false
    optFrame.LayoutOrder = 3
    optFrame.ClipsDescendants = true
    optFrame.Parent = container
    
    Instance.new("UICorner", optFrame).CornerRadius = UDim.new(0, 4)
    local optStroke = Instance.new("UIStroke", optFrame)
    optStroke.Color = Color3.fromRGB(55, 55, 55); optStroke.Thickness = 1
    
    local optList = Instance.new("UIListLayout", optFrame)
    optList.Padding = UDim.new(0, 1)
    optList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Search Bar
    local searchBar = Instance.new("TextBox")
    searchBar.Name = "Search"
    searchBar.Size = UDim2.new(1, -8, 0, 24)
    searchBar.Position = UDim2.new(0, 4, 0, 2)
    searchBar.BackgroundTransparency = 1
    searchBar.PlaceholderText = "Search..."
    searchBar.Text = ""
    searchBar.TextColor3 = Color3.fromRGB(200, 200, 200)
    searchBar.TextSize = 12
    searchBar.TextXAlignment = Enum.TextXAlignment.Left
    searchBar.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    searchBar.LayoutOrder = 0
    searchBar.Parent = optFrame
    
    local searchPad = Instance.new("UIPadding", searchBar)
    searchPad.PaddingLeft = UDim.new(0, 4)
    
    local searchDiv = Instance.new("Frame")
    searchDiv.Name = "Divider"
    searchDiv.Size = UDim2.new(1, 0, 0, 1)
    searchDiv.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    searchDiv.BorderSizePixel = 0
    searchDiv.LayoutOrder = 1
    searchDiv.Parent = optFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.Size = UDim2.new(1, 0, 0, 0) -- Height set dynamically
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.LayoutOrder = 2
    scroll.Parent = optFrame
    
    local scrollList = Instance.new("UIListLayout", scroll)
    scrollList.Padding = UDim.new(0, 1)
    scrollList.SortOrder = Enum.SortOrder.LayoutOrder

    local isOpen = false

    local function updateDisplay()
        local v = dropdown.Value
        if multi then
            if type(v) == "table" and #v > 0 then 
                valLabel.Text = table.concat(v, ", ") 
                valLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
            else 
                valLabel.Text = "None"
                valLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        else
            valLabel.Text = v and tostring(v) or "Select..."
            valLabel.TextColor3 = v and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(180, 180, 180)
        end
    end

    local function buildOptions(filter)
        for _, c in ipairs(scroll:GetChildren()) do 
            if c:IsA("TextButton") then c:Destroy() end 
        end
        
        local count = 0
        for i, opt in ipairs(dropdown.Options) do
            local strOpt = tostring(opt)
            if filter and filter ~= "" and not string.find(string.lower(strOpt), string.lower(filter)) then
                continue
            end
            
            count = count + 1
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, 24)
            ob.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            ob.BackgroundTransparency = 1
            ob.BorderSizePixel = 0
            ob.Text = "  " .. strOpt
            ob.TextColor3 = Color3.fromRGB(180, 180, 180)
            ob.TextSize = 11
            ob.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.AutoButtonColor = false
            ob.Parent = scroll
            
            -- Highlight logic
            local isSelected = false
            if multi then
                if type(dropdown.Value) == "table" and table.find(dropdown.Value, opt) then isSelected = true end
            else
                if dropdown.Value == opt then isSelected = true end
            end
            
            if isSelected then
                ob.TextColor3 = Color3.fromRGB(255, 255, 255)
                ob.BackgroundTransparency = 0.8
                ob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            end

            ob.MouseButton1Click:Connect(function()
                if multi then
                    local idx = table.find(dropdown.Value, opt)
                    if idx then 
                        table.remove(dropdown.Value, idx)
                    else 
                        table.insert(dropdown.Value, opt) 
                    end
                    buildOptions(searchBar.Text) -- Refresh to show selection
                else
                    dropdown.Value = opt
                    isOpen = false
                    optFrame.Visible = false
                    chevImg.Rotation = 0
                end
                updateDisplay()
                dropdown.OnChanged:Fire(dropdown.Value)
                if callback then Library:SafeCallback(callback, dropdown.Value) end
            end)
        end
        
        -- Resize scroll/frame
        local itemHeight = 24
        local totalHeight = math.min(count * (itemHeight + 1), 150) -- Max height 150px
        scroll.Size = UDim2.new(1, 0, 0, totalHeight)
        
        -- Resize optFrame (Search(24) + Divider(1) + Scroll(totalHeight))
        -- But optFrame is AutomaticSize.Y, usually works best if we enforce size for scroll
        -- Actually, we can just set optFrame height manually if needed, or let auto handle it.
        -- AutomaticSize works if children have size.
    end

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        buildOptions(searchBar.Text)
    end)

    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optFrame.Visible = isOpen
        chevImg.Rotation = isOpen and 180 or 0
        if isOpen then
            searchBar.Text = ""
            buildOptions()
        end
    end)

    function dropdown:SetValue(v) dropdown.Value = v; updateDisplay() end
    function dropdown:GetValue() return dropdown.Value end
    function dropdown:SetValues(list) dropdown.Options = list; buildOptions() end
    function dropdown:Refresh(options, keepValue) 
        dropdown.Options = options
        if not keepValue then dropdown.Value = multi and {} or nil end
        buildOptions()
        updateDisplay()
    end

    buildOptions()
    updateDisplay()

    if flag and flag ~= "" then self._library.Options[flag] = dropdown end
    return dropdown
end

--------------------------------------------------------------------------------
-- Element: Input (TextInput)
--------------------------------------------------------------------------------
local InputClass = {}
InputClass.__index = InputClass

function Groupbox:AddInput(flag, config)
    config = config or {}
    local text = config.Text or flag
    local default = config.Default or ""
    local placeholder = config.Placeholder or "Type..."
    local callback = config.Callback
    local order = self:_nextOrder()

    local input = setmetatable({}, InputClass)
    input.Value = default
    input.OnChanged = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "Input_" .. flag
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 26)
    inputFrame.Position = UDim2.new(0, 0, 0, 20)
    inputFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = container
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 4)
    local iStroke = Instance.new("UIStroke", inputFrame)
    iStroke.Color = Color3.fromRGB(60, 60, 60); iStroke.Thickness = 1
    local iPad = Instance.new("UIPadding", inputFrame)
    iPad.PaddingLeft = UDim.new(0, 6); iPad.PaddingRight = UDim.new(0, 6)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 1, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = default
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    textBox.TextSize = 12
    textBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame

    textBox.Focused:Connect(function() iStroke.Color = Color3.fromRGB(96, 130, 255) end)
    textBox.FocusLost:Connect(function()
        iStroke.Color = Color3.fromRGB(60, 60, 60)
        input.Value = textBox.Text
        input.OnChanged:Fire(input.Value)
        if callback then Library:SafeCallback(callback, input.Value) end
    end)

    function input:SetValue(v) input.Value = v; textBox.Text = v end
    function input:GetValue() return input.Value end

    if flag and flag ~= "" then self._library.Options[flag] = input end
    return input
end

--------------------------------------------------------------------------------
-- Element: Keybind
--------------------------------------------------------------------------------
local KeybindClass = {}
KeybindClass.__index = KeybindClass

function Groupbox:AddKeybind(flag, config)
    config = config or {}
    local text = config.Text or flag
    local default = config.Default or Enum.KeyCode.Unknown
    local callback = config.Callback
    local order = self:_nextOrder()

    local keybind = setmetatable({}, KeybindClass)
    keybind.Value = default
    keybind.OnChanged = Signal.new()
    keybind.OnPressed = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "Keybind_" .. flag
    container.Size = UDim2.new(1, 0, 0, 28)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -80, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    textLabel.TextSize = 12
    textLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = container

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 70, 0, 22)
    keyBtn.Position = UDim2.new(1, -72, 0.5, -11)
    keyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyBtn.BorderSizePixel = 0
    keyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    keyBtn.TextSize = 11
    keyBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = container
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)
    local kStroke = Instance.new("UIStroke", keyBtn)
    kStroke.Color = Color3.fromRGB(60, 60, 60); kStroke.Thickness = 1

    local listening = false
    local function display()
        keyBtn.Text = keybind.Value == Enum.KeyCode.Unknown and "None" or keyCodeToString(keybind.Value)
    end

    keyBtn.MouseButton1Click:Connect(function()
        listening = true; keyBtn.Text = "..."; kStroke.Color = Color3.fromRGB(96, 130, 255)
    end)

    self._library:Connect(UserInputService.InputBegan, function(inp, gpe)
        if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode == Enum.KeyCode.Escape then keybind.Value = Enum.KeyCode.Unknown
            else keybind.Value = inp.KeyCode end
            listening = false; display(); kStroke.Color = Color3.fromRGB(60, 60, 60)
            keybind.OnChanged:Fire(keybind.Value)
            return
        end
        if not gpe and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == keybind.Value and keybind.Value ~= Enum.KeyCode.Unknown then
            keybind.OnPressed:Fire()
            if callback then Library:SafeCallback(callback) end
        end
    end)

    function keybind:SetValue(v) keybind.Value = v; display() end
    function keybind:GetValue() return keybind.Value end

    display()
    if flag and flag ~= "" then self._library.Options[flag] = keybind end
    return keybind
end

--------------------------------------------------------------------------------
-- Element: Label, Button, Divider (simple)
--------------------------------------------------------------------------------
function Groupbox:AddLabel(text)
    local order = self:_nextOrder()
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = type(text) == "table" and (text.Text or "") or tostring(text)
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 12
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.LayoutOrder = order
    label.Parent = self._content
    local obj = { _label = label }
    function obj:SetText(t) label.Text = t end
    return obj
end

function Groupbox:AddButton(config)
    config = config or {}
    local text = config.Text or "Button"
    local callback = config.Callback or config.Func
    local order = self:_nextOrder()

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 12
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = self._content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end)
    btn.MouseButton1Click:Connect(function()
        if callback then Library:SafeCallback(callback) end
    end)

    local obj = {}
    function obj:SetText(t) btn.Text = t end
    return obj
end

function Groupbox:AddDivider()
    local order = self:_nextOrder()
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, 0, 0, 7)
    div.BackgroundTransparency = 1
    div.LayoutOrder = order
    div.Parent = self._content
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    line.BorderSizePixel = 0
    line.Parent = div
    return div
end

--------------------------------------------------------------------------------
-- Element: ColorPicker (compact inline version)
--------------------------------------------------------------------------------
local ColorPickerClass = {}
ColorPickerClass.__index = ColorPickerClass

function Groupbox:AddColorPicker(flag, config)
    config = config or {}
    local text = config.Text or flag
    local default = config.Default or Color3.new(1, 1, 1)
    local callback = config.Callback
    local order = self:_nextOrder()

    local picker = setmetatable({}, ColorPickerClass)
    picker.Value = default
    picker.OnChanged = Signal.new()

    local container = Instance.new("Frame")
    container.Name = "ColorPicker_" .. flag
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = self._content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -36, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 28, 0, 18)
    swatch.Position = UDim2.new(1, -30, 0.5, -9)
    swatch.BackgroundColor3 = default
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = container
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)
    local swStroke = Instance.new("UIStroke", swatch)
    swStroke.Color = Color3.fromRGB(70, 70, 70); swStroke.Thickness = 1

    function picker:SetValue(c) picker.Value = c; swatch.BackgroundColor3 = c end
    function picker:GetValue() return picker.Value end

    -- Simple click to cycle hue (basic picker, full picker can be added later)
    local h, s, v = Color3.toHSV(default)
    swatch.MouseButton1Click:Connect(function()
        h = (h + 0.1) % 1
        local c = Color3.fromHSV(h, s, v)
        picker.Value = c
        swatch.BackgroundColor3 = c
        picker.OnChanged:Fire(c)
        if callback then Library:SafeCallback(callback, c) end
    end)

    if flag and flag ~= "" then self._library.Options[flag] = picker end
    return picker
end

--------------------------------------------------------------------------------
-- Tabbox
--------------------------------------------------------------------------------
Tabbox = {}
Tabbox.__index = Tabbox

function Tabbox.new(parent, title, library)
    local self = setmetatable({}, Tabbox)
    self._library = library
    self._tabs = {}
    self._activeSubTab = nil

    local container = Instance.new("Frame")
    container.Name = "Tabbox_" .. (title or "")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BorderSizePixel = 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    local tbStroke = Instance.new("UIStroke", container)
    tbStroke.Color = Color3.fromRGB(45, 45, 45); tbStroke.Thickness = 1

    -- Tab header bar
    local headerBar = Instance.new("Frame")
    headerBar.Name = "Header"
    headerBar.Size = UDim2.new(1, 0, 0, 28)
    headerBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    headerBar.BorderSizePixel = 0
    headerBar.ClipsDescendants = true
    headerBar.Parent = container
    Instance.new("UICorner", headerBar).CornerRadius = UDim.new(0, 6)
    local hfix = Instance.new("Frame")
    hfix.Size = UDim2.new(1, 0, 0, 8); hfix.Position = UDim2.new(0, 0, 1, -8)
    hfix.BackgroundColor3 = Color3.fromRGB(20, 20, 20); hfix.BorderSizePixel = 0; hfix.Parent = headerBar

    local headerLayout = Instance.new("UIListLayout")
    headerLayout.FillDirection = Enum.FillDirection.Horizontal
    headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    headerLayout.Parent = headerBar

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -16, 0, 0)
    contentArea.Position = UDim2.new(0, 8, 0, 30)
    contentArea.AutomaticSize = Enum.AutomaticSize.Y
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = container

    local bottomPad = Instance.new("UIPadding", contentArea)
    bottomPad.PaddingBottom = UDim.new(0, 8)

    self._container = container
    self._headerBar = headerBar
    self._contentArea = contentArea

    return self
end

function Tabbox:AddTab(name)
    local tabData = {}
    tabData._name = name

    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 80, 1, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    tabBtn.TextSize = 11
    tabBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    tabBtn.AutoButtonColor = false
    tabBtn.LayoutOrder = #self._tabs + 1
    tabBtn.Parent = self._headerBar

    -- Create groupbox-like content for this sub-tab
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "SubTab_" .. name
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.AutomaticSize = Enum.AutomaticSize.Y
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = self._contentArea

    local subLayout = Instance.new("UIListLayout")
    subLayout.Padding = UDim.new(0, 5)
    subLayout.SortOrder = Enum.SortOrder.LayoutOrder
    subLayout.Parent = contentFrame

    -- Create a pseudo-Groupbox that adds elements to contentFrame
    local subGroup = setmetatable({
        _library = self._library,
        _content = contentFrame,
        _elementCount = 0,
    }, Groupbox)

    tabData._btn = tabBtn
    tabData._content = contentFrame
    tabData._groupbox = subGroup
    table.insert(self._tabs, tabData)

    tabBtn.MouseButton1Click:Connect(function()
        self:_switchSubTab(tabData)
    end)

    if #self._tabs == 1 then self:_switchSubTab(tabData) end

    return subGroup
end

function Tabbox:_switchSubTab(tab)
    for _, t in ipairs(self._tabs) do
        t._content.Visible = (t == tab)
        t._btn.TextColor3 = (t == tab) and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(120, 120, 120)
        t._btn.BackgroundColor3 = (t == tab) and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(20, 20, 20)
    end
    self._activeSubTab = tab
end

--------------------------------------------------------------------------------
-- Checkbox (alias for toggle with checkbox visual)
--------------------------------------------------------------------------------
function Groupbox:AddCheckbox(flag, config)
    return self:AddToggle(flag, config) -- same behavior, different name
end

--------------------------------------------------------------------------------
-- Return Library
--------------------------------------------------------------------------------
return Library
