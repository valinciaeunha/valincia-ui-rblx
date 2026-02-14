# Valincia UI -- API Documentation

Complete reference for all UI elements, addons, and features.

For project overview and quick start, see [README.md](README.md).

---

## Table of Contents

- [Creating a Window](#creating-a-window)
- [Tabs](#tabs)
- [Groupbox](#groupbox)
- [Elements](#elements)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Input](#input-text-field)
  - [Keybind](#keybind)
  - [Button](#button)
  - [Button Row](#button-row)
  - [Label](#label)
  - [Divider](#divider)
  - [ColorPicker](#colorpicker)
  - [Checkbox](#checkbox)
  - [Image](#image)
  - [Video](#video)
  - [Viewport](#viewport-3d-model)
- [Dependency](#dependency)
- [Tabbox](#tabbox-nested-tabs)
- [Notifications](#notifications)
- [Addons](#addons)
  - [SaveManager](#savemanager)
  - [ThemeManager](#thememanager)
- [Key System](#key-system)
- [Unload / Cleanup](#unload--cleanup)

---

## Creating a Window

```lua
local Window = Library:CreateWindow({
    Title = "My Script",           -- Window title
    Footer = "v1.0.0",            -- Bottom-left text
    Center = true,                 -- Center on screen (default: true)
    AutoShow = true,               -- Show immediately (default: true)
    Size = UDim2.new(0, 550, 0, 380), -- Window size
    ToggleKeybind = Enum.KeyCode.RightControl, -- Key to toggle visibility
    Icon = 139563907510631,        -- Header icon (asset ID)
    OpenImageId = 139563907510631, -- Floating open button icon
})
```

**Window Methods:**
| Method | Description |
|--------|-------------|
| `Window:SetTitle(text)` | Change window title |
| `Window:GetTitle()` | Get current title |
| `Window:AddTab(name, icon?)` | Add a new tab |

---

## Tabs

```lua
local Tabs = {
    Main = Window:AddTab("Main"),
    Combat = Window:AddTab("Combat"),
    Settings = Window:AddTab("Settings"),
}
```

**Tab Methods:**
| Method | Description |
|--------|-------------|
| `Tab:AddGroupbox(title)` | Add a groupbox |
| `Tab:AddLeftGroupbox(title)` | Alias for AddGroupbox |
| `Tab:AddRightGroupbox(title)` | Alias for AddGroupbox |
| `Tab:AddTabbox(title)` | Add a nested tabbox |
| `Tab:AddLeftTabbox(title)` | Alias for AddTabbox |
| `Tab:AddRightTabbox(title)` | Alias for AddTabbox |

---

## Groupbox

Container for UI elements. All elements below are added to a groupbox.

```lua
local MyGroup = Tabs.Main:AddGroupbox("Group Title")
```

---

## Elements

### Toggle

```lua
local toggle = MyGroup:AddToggle("UniqueFlag", {
    Text = "Enable Feature",
    Default = false,
    Callback = function(value)
        print("Toggled:", value)
    end,
})

-- Access later
toggle:SetValue(true)
toggle:GetValue()
Library.Toggles["UniqueFlag"]  -- reference by flag
```

### Slider

```lua
local slider = MyGroup:AddSlider("SpeedFlag", {
    Text = "Walk Speed",
    Default = 16,
    Min = 0,
    Max = 200,
    Rounding = 0,       -- 0 = integer, 1 = one decimal, etc.
    Suffix = " studs",  -- displayed after value
    Callback = function(value)
        print("Speed:", value)
    end,
})

slider:SetValue(50)
slider:GetValue()
Library.Options["SpeedFlag"]
```

### Dropdown

**Single select:**
```lua
MyGroup:AddDropdown("ModeFlag", {
    Text = "Farm Mode",
    Values = { "Closest", "Highest HP", "Lowest HP", "Random" },
    Default = "Closest",
    Callback = function(value)
        print("Selected:", value)
    end,
})
```

**Multi select:**
```lua
MyGroup:AddDropdown("FruitsFlag", {
    Text = "Select Fruits",
    Values = { "Apple", "Banana", "Cherry", "Date" },
    Default = { "Apple", "Cherry" },
    Multi = true,
    Callback = function(values)
        print("Selected:", table.concat(values, ", "))
    end,
})
```

**Dropdown Methods:**
| Method | Description |
|--------|-------------|
| `dropdown:SetValue(val)` | Set selected value |
| `dropdown:GetValue()` | Get current value |
| `dropdown:SetValues(list)` | Replace options list |
| `dropdown:Refresh(options, keepValue?)` | Replace options and optionally reset |

### Input (Text Field)

```lua
MyGroup:AddInput("NameFlag", {
    Text = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
    Callback = function(value)
        print("Input:", value)
    end,
})

Library.Options["NameFlag"]:SetValue("NewValue")
```

### Keybind

```lua
MyGroup:AddKeybind("AimKeyFlag", {
    Text = "Aim Key",
    Default = Enum.KeyCode.E,
    Callback = function()
        print("Key pressed!")
    end,
})
```

### Button

```lua
MyGroup:AddButton({
    Text = "Click Me",
    Callback = function()
        print("Button clicked!")
    end,
})
```

### Button Row

Multiple buttons in a single horizontal row.

```lua
MyGroup:AddButtonRow({
    {
        Text = "Option A",
        Callback = function() print("A") end,
    },
    {
        Text = "Option B",
        Callback = function() print("B") end,
    },
})
```

### Label

```lua
MyGroup:AddLabel("This is informational text.")

-- With SetText support
local label = MyGroup:AddLabel("Initial text")
label:SetText("Updated text")
```

### Divider

```lua
MyGroup:AddDivider()
```

### ColorPicker

```lua
MyGroup:AddColorPicker("ColorFlag", {
    Text = "ESP Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(color)
        print("Color:", color)
    end,
})
```

### Checkbox

Alias for Toggle with identical behavior.

```lua
MyGroup:AddCheckbox("CheckFlag", {
    Text = "Accept Terms",
    Default = false,
})
```

### Image

```lua
MyGroup:AddImage({
    Image = 6015897843,  -- Roblox asset ID
    Size = UDim2.new(1, 0, 0, 100),
})
```

### Video

```lua
MyGroup:AddVideo({
    Video = 123456789,  -- Roblox video asset ID
    Size = UDim2.new(1, 0, 0, 150),
})
```

### Viewport (3D Model)

```lua
local model = workspace:FindFirstChildOfClass("Model")

MyGroup:AddViewport({
    Model = model,
    Size = UDim2.new(1, 0, 0, 150),
    CameraDistance = 10,
})
```

---

## Dependency

Show/hide all elements in a groupbox based on a toggle's value.

```lua
local SecretGroup = Tabs.Main:AddGroupbox("Secret")

SecretGroup:AddDependency({
    flag = "MasterSwitch",  -- flag name of a Toggle
    value = true,           -- show when this value matches
})

SecretGroup:AddButton({
    Text = "Secret Action",
    Callback = function() print("Secret!") end,
})
```

> **Note:** `AddDependency` controls the entire groupbox content. Create a separate groupbox for elements that should have conditional visibility.

---

## Tabbox (Nested Tabs)

Sub-tabs inside a single tab, useful for organizing related settings.

```lua
local MyTabbox = Tabs.Visuals:AddTabbox("Chams")

local General = MyTabbox:AddTab("General")
local Settings = MyTabbox:AddTab("Settings")

-- Add elements to sub-tabs (same API as Groupbox)
General:AddToggle("ChamsOn", { Text = "Enable Chams", Default = false })
Settings:AddColorPicker("ChamsColor", { Text = "Color", Default = Color3.fromRGB(100, 200, 255) })
```

---

## Notifications

```lua
Library:Notify({
    Text = "Hello from Valincia!",
    Duration = 3, -- seconds
})
```

---

## Addons

### SaveManager

Saves and loads all flagged element values (Toggles + Options) to JSON files.

```lua
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript/game-name")
SaveManager:IgnoreThemeSettings()                -- exclude theme flags from saves
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })  -- exclude specific flags
SaveManager:BuildConfigSection(Tabs.Settings)    -- adds config UI to a tab

-- Auto-load saved config on startup
SaveManager:LoadAutoloadConfig()
```

**Manual usage:**
```lua
SaveManager:Save("config-name")
SaveManager:Load("config-name")
SaveManager:Delete("config-name")
SaveManager:GetConfigs()          -- returns list of saved config names
SaveManager:SetAutoload("name")   -- set a config to auto-load on startup
```

### ThemeManager

Built-in themes: **Dark**, **Light**, **Mocha**, **Ocean**. Supports custom themes.

```lua
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyScript")
ThemeManager:ApplyToTab(Tabs.Settings)  -- adds theme UI to a tab
```

**Manual usage:**
```lua
ThemeManager:SetTheme("Mocha")
ThemeManager:GetTheme()                          -- returns current theme name
ThemeManager:GetColor("Accent")                  -- get a specific color
ThemeManager:GetThemes()                         -- list all available themes
ThemeManager:SaveCustomTheme("MyTheme", data)    -- save a custom theme
ThemeManager:LoadDefault()                       -- reset to Dark theme
```

**Theme color keys:**
`Background`, `Surface`, `SurfaceAlt`, `Accent`, `Text`, `TextDimmed`, `Border`, `Divider`, `Toggle_On`, `Toggle_Off`, `Slider_Fill`, `Slider_Track`, `Checkbox_Check`, `Dropdown_Bg`

---

## Key System

Built-in key validation with **auto-save** and **configurable expiry**. See `KeySystemExample.lua` for the full implementation.

**Supported key source formats:**
| Format | Description | Example |
|--------|-------------|---------|
| Local hardcoded | Keys defined directly in script | `VALID_KEYS = { "KEY-1234" }` |
| JSON API | Server returns validation result | `{"valid": true, "message": "OK"}` |
| JSON array | Server returns list of valid keys | `["KEY-1234", "KEY-5678"]` |
| Plain text | One valid key per line | `KEY-1234\nKEY-5678` |

```lua
local CONFIG = {
    API_URL = "https://your-api.com/keys.txt",   -- any format above
    VALID_KEYS = { "TEST-KEY-1234" },            -- local fallback (checked first)
    EXPIRY_HOURS = 24,                           -- how long a validated key stays valid
}
```

**Validation flow:**
1. Check local hardcoded `VALID_KEYS` first (instant, no network)
2. If no match, fetch from `API_URL` and auto-detect format
3. All comparisons are **case-insensitive**

**Auto-save flow:**
1. On startup, check locally saved key file
2. If saved key exists and not expired, validate and auto-load script
3. If expired or no saved key, show key system UI
4. After successful validation, key + timestamp saved locally

---

## Unload / Cleanup

```lua
Library:Unload()  -- destroys all UI and disconnects all events
-- or
Library:Destroy() -- alias for Unload
```

**Prevent duplicate instances:**
```lua
if getgenv().MyScript then
    getgenv().MyScript:Unload()
end
getgenv().MyScript = Library
```
