--[[
    Valincia UI — Example Script
    
    Usage in executor:
    loadstring(game:HttpGet("YOUR_RAW_URL/Example.lua"))()
]]

-- Load library and addons
local repo = "https://raw.githubusercontent.com/valinciaeunha/valincia-ui-rblx/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

-- Unload previous instance
if getgenv().ValinciaUI then
    getgenv().ValinciaUI:Unload()
end
getgenv().ValinciaUI = Library

-- Create window
local Window = Library:CreateWindow({
    Title = "Valincia Example",
    Footer = "v1.0.0",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    OpenImageId = 139563907510631,
    Icon = 139563907510631, -- Header Icon
})

-- Create tabs
local Tabs = {
    Main = Window:AddTab("Main"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings"),
}

-- ═══════════════════════════════════════
--  MAIN TAB
-- ═══════════════════════════════════════
local MainGroup = Tabs.Main:AddGroupbox("General")

MainGroup:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end,
})

MainGroup:AddSlider("Speed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        print("Speed:", value)
    end,
})

MainGroup:AddDropdown("Mode", {
    Text = "Farm Mode",
    Values = { "Closest", "Highest HP", "Lowest HP", "Random" },
    Default = "Closest",
    Callback = function(value)
        print("Mode:", value)
    end,
})

local MainInfo = Tabs.Main:AddGroupbox("Info")
MainInfo:AddLabel("Welcome to Valincia UI!")
MainInfo:AddDivider()
MainInfo:AddLabel("Press RightCtrl to toggle menu")
MainInfo:AddLabel("Drag bottom-right corner to resize!")

MainInfo:AddButton({
    Text = "Print Hello",
    Callback = function()
        print("Hello from Valincia!")
        Library:Notify({ Text = "Hello!", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════
--  COMBAT TAB
-- ═══════════════════════════════════════
local CombatGroup = Tabs.Combat:AddGroupbox("Aimbot & Reach")

CombatGroup:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot",
    Default = false,
})

CombatGroup:AddSlider("AimbotFOV", {
    Text = "FOV",
    Default = 90,
    Min = 10,
    Max = 360,
    Rounding = 0,
    Suffix = "°",
})

CombatGroup:AddKeybind("AimbotKey", {
    Text = "Aim Key",
    Default = Enum.KeyCode.E,
    Callback = function()
        print("Aim key pressed!")
    end,
})

CombatGroup:AddDropdown("AimbotTarget", {
    Text = "Target Part",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
})

CombatGroup:AddDivider()

CombatGroup:AddToggle("ReachEnabled", {
    Text = "Enable Reach",
    Default = false,
})

CombatGroup:AddSlider("ReachDistance", {
    Text = "Distance",
    Default = 10,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Suffix = " studs",
})

-- ═══════════════════════════════════════
--  VISUALS TAB
-- ═══════════════════════════════════════
local VisGroup = Tabs.Visuals:AddGroupbox("ESP Settings")

VisGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
})

VisGroup:AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = Color3.fromRGB(255, 50, 50),
})

VisGroup:AddToggle("ESPNames", {
    Text = "Show Names",
    Default = true,
})

VisGroup:AddToggle("ESPBoxes", {
    Text = "Show Boxes",
    Default = true,
})

VisGroup:AddSlider("ESPDistance", {
    Text = "Max Distance",
    Default = 500,
    Min = 100,
    Max = 2000,
    Rounding = 0,
    Suffix = " studs",
})

VisGroup:AddDivider()

VisGroup:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
})

VisGroup:AddToggle("NoFog", {
    Text = "Remove Fog",
    Default = false,
})

-- Tabbox example
local VisTabbox = Tabs.Visuals:AddTabbox("Chams")

local ChamsGeneral = VisTabbox:AddTab("General")
local ChamsSettings = VisTabbox:AddTab("Settings")

ChamsGeneral:AddToggle("ChamsEnabled", {
    Text = "Enable Chams",
    Default = false,
})

ChamsSettings:AddColorPicker("ChamsColor", {
    Text = "Chams Color",
    Default = Color3.fromRGB(100, 200, 255),
})

ChamsSettings:AddSlider("ChamsTransparency", {
    Text = "Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
})

-- ═══════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════

-- Hook managers
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("ValinciaExample/game-name")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("ValinciaExample")
ThemeManager:ApplyToTab(Tabs.Settings)

-- Load autoload config (if any)
SaveManager:LoadAutoloadConfig()
