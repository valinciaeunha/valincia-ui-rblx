--[[
    Valincia UI — ThemeManager Addon
    Usage: local ThemeManager = loadstring(game:HttpGet("url/addons/ThemeManager.lua"))()
    
    Provides built-in themes + custom theme creation/import.
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {
    _library = nil,
    _folder = "Valincia",
    _currentTheme = "Dark",
    _themes = {},
    _customThemes = {},
    _themeKeys = {
        "Background", "Surface", "SurfaceAlt", "Accent",
        "Text", "TextDimmed", "Border", "Divider",
        "Toggle_On", "Toggle_Off", "Slider_Fill", "Slider_Track",
        "Checkbox_Check", "Dropdown_Bg",
    },
}

-- Built-in themes
ThemeManager._themes["Dark"] = {
    Background = Color3.fromRGB(25, 25, 25),
    Surface = Color3.fromRGB(30, 30, 30),
    SurfaceAlt = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(96, 130, 255),
    Text = Color3.fromRGB(220, 220, 220),
    TextDimmed = Color3.fromRGB(140, 140, 140),
    Border = Color3.fromRGB(50, 50, 50),
    Divider = Color3.fromRGB(45, 45, 45),
    Toggle_On = Color3.fromRGB(96, 200, 130),
    Toggle_Off = Color3.fromRGB(70, 70, 70),
    Slider_Fill = Color3.fromRGB(96, 130, 255),
    Slider_Track = Color3.fromRGB(50, 50, 50),
    Checkbox_Check = Color3.fromRGB(96, 130, 255),
    Dropdown_Bg = Color3.fromRGB(30, 30, 30),
}

ThemeManager._themes["Light"] = {
    Background = Color3.fromRGB(240, 240, 240),
    Surface = Color3.fromRGB(250, 250, 250),
    SurfaceAlt = Color3.fromRGB(230, 230, 230),
    Accent = Color3.fromRGB(70, 100, 220),
    Text = Color3.fromRGB(30, 30, 30),
    TextDimmed = Color3.fromRGB(100, 100, 100),
    Border = Color3.fromRGB(200, 200, 200),
    Divider = Color3.fromRGB(210, 210, 210),
    Toggle_On = Color3.fromRGB(60, 180, 100),
    Toggle_Off = Color3.fromRGB(180, 180, 180),
    Slider_Fill = Color3.fromRGB(70, 100, 220),
    Slider_Track = Color3.fromRGB(200, 200, 200),
    Checkbox_Check = Color3.fromRGB(70, 100, 220),
    Dropdown_Bg = Color3.fromRGB(245, 245, 245),
}

ThemeManager._themes["Mocha"] = {
    Background = Color3.fromRGB(30, 30, 46),
    Surface = Color3.fromRGB(36, 36, 54),
    SurfaceAlt = Color3.fromRGB(49, 50, 68),
    Accent = Color3.fromRGB(137, 180, 250),
    Text = Color3.fromRGB(205, 214, 244),
    TextDimmed = Color3.fromRGB(147, 153, 178),
    Border = Color3.fromRGB(69, 71, 90),
    Divider = Color3.fromRGB(59, 60, 78),
    Toggle_On = Color3.fromRGB(166, 227, 161),
    Toggle_Off = Color3.fromRGB(69, 71, 90),
    Slider_Fill = Color3.fromRGB(137, 180, 250),
    Slider_Track = Color3.fromRGB(49, 50, 68),
    Checkbox_Check = Color3.fromRGB(137, 180, 250),
    Dropdown_Bg = Color3.fromRGB(36, 36, 54),
}

ThemeManager._themes["Ocean"] = {
    Background = Color3.fromRGB(15, 25, 40),
    Surface = Color3.fromRGB(20, 32, 50),
    SurfaceAlt = Color3.fromRGB(28, 42, 62),
    Accent = Color3.fromRGB(60, 160, 240),
    Text = Color3.fromRGB(200, 215, 230),
    TextDimmed = Color3.fromRGB(120, 140, 170),
    Border = Color3.fromRGB(40, 60, 85),
    Divider = Color3.fromRGB(35, 52, 75),
    Toggle_On = Color3.fromRGB(60, 200, 180),
    Toggle_Off = Color3.fromRGB(40, 60, 85),
    Slider_Fill = Color3.fromRGB(60, 160, 240),
    Slider_Track = Color3.fromRGB(28, 42, 62),
    Checkbox_Check = Color3.fromRGB(60, 160, 240),
    Dropdown_Bg = Color3.fromRGB(20, 32, 50),
}

function ThemeManager:SetLibrary(lib)
    self._library = lib
    self:LoadCustomThemes()
end

function ThemeManager:SetFolder(folder)
    self._folder = folder
end

function ThemeManager:GetThemes()
    local list = {}
    for name in pairs(self._themes) do table.insert(list, name) end
    -- Load custom themes
    for name in pairs(self._customThemes) do table.insert(list, name) end
    table.sort(list)
    return list
end

function ThemeManager:GetTheme()
    return self._currentTheme
end

function ThemeManager:GetColor(key)
    local theme = self._themes[self._currentTheme] or self._customThemes[self._currentTheme]
    return theme and theme[key]
end

function ThemeManager:SetTheme(name)
    local theme = self._themes[name] or self._customThemes[name]
    if not theme then warn("[Valincia] ThemeManager: Unknown theme:", name) return end
    self._currentTheme = name
    -- Theme application would require Library to track all elements
    -- For now, store the active theme for new elements to pick up
end

function ThemeManager:SaveCustomTheme(name, themeData)
    self._customThemes[name] = themeData
    local path = self._folder .. "/themes"
    if isfolder and not isfolder(path) then makefolder(path) end

    local data = {}
    for key, color in pairs(themeData) do
        data[key] = { R = color.R, G = color.G, B = color.B }
    end

    if writefile then
        writefile(path .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end
end

function ThemeManager:LoadCustomThemes()
    local path = self._folder .. "/themes"
    if not isfolder or not isfolder(path) then return end

    for _, file in ipairs(listfiles(path)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(file))
            end)
            if ok and data then
                local theme = {}
                for key, val in pairs(data) do
                    theme[key] = Color3.new(val.R, val.G, val.B)
                end
                self._customThemes[name] = theme
            end
        end
    end
end

function ThemeManager:LoadDefault()
    self:SetTheme("Dark")
end

function ThemeManager:ApplyToTab(tab)
    if not self._library then return end

    local groupbox = tab:AddLeftGroupbox("Theme Settings")

    groupbox:AddDropdown("ThemeManager_Theme", {
        Text = "Theme",
        Values = self:GetThemes(),
        Default = self._currentTheme,
        Callback = function(val)
            self:SetTheme(val)
            self._library:Notify({ Text = "Theme: " .. val })
        end,
    })

    -- Color pickers for each theme key
    local theme = self._themes[self._currentTheme]
    if theme then
        for _, key in ipairs(self._themeKeys) do
            groupbox:AddColorPicker("Theme_" .. key, {
                Text = key:gsub("_", " "),
                Default = theme[key] or Color3.new(1, 1, 1),
                Callback = function(color)
                    local current = self._themes[self._currentTheme] or self._customThemes[self._currentTheme]
                    if current then current[key] = color end
                end,
            })
        end
    end

    groupbox:AddDivider()

    groupbox:AddButton({
        Text = "Save Custom Theme",
        Callback = function()
            local current = self._themes[self._currentTheme] or self._customThemes[self._currentTheme]
            if current then
                self:SaveCustomTheme("Custom_" .. os.time(), current)
                self._library:Notify({ Text = "Custom theme saved!" })
            end
        end,
    })
end

return ThemeManager
