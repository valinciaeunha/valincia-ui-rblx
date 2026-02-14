--[[
    Valincia UI — SaveManager Addon
    Usage: local SaveManager = loadstring(game:HttpGet("url/addons/SaveManager.lua"))()
    
    Saves/loads all flagged element values (Toggles + Options) to JSON files
    via executor globals: writefile, readfile, isfile, listfiles, makefolder, isfolder.
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {
    _library = nil,
    _folder = "Valincia",
    _subfolder = nil,
    _ignoreIndexes = {},
    _ignoreThemeSettings = false,
    _autoloadFile = nil,
}

function SaveManager:SetLibrary(lib)
    self._library = lib
end

function SaveManager:SetFolder(folder)
    self._folder = folder
end

function SaveManager:SetSubFolder(subfolder)
    self._subfolder = subfolder
end

function SaveManager:SetIgnoreIndexes(list)
    for _, v in ipairs(list) do
        self._ignoreIndexes[v] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    self._ignoreThemeSettings = true
end

function SaveManager:_getBasePath()
    local path = self._folder
    if self._subfolder then
        path = path .. "/" .. self._subfolder
    end
    return path
end

function SaveManager:_getConfigPath()
    return self:_getBasePath() .. "/settings"
end

function SaveManager:_ensureFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

function SaveManager:_isIgnored(flag)
    if self._ignoreIndexes[flag] then return true end
    if self._ignoreThemeSettings then
        -- Ignore common theme-related flags
        local themeFlags = { "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor" }
        for _, tf in ipairs(themeFlags) do
            if flag == tf then return true end
        end
    end
    return false
end

function SaveManager:Save(name)
    if not self._library then warn("[Valincia] SaveManager: No library set") return end

    local data = { Toggles = {}, Options = {} }

    for flag, toggle in pairs(self._library.Toggles) do
        if not self:_isIgnored(flag) then
            data.Toggles[flag] = toggle.Value
        end
    end

    for flag, option in pairs(self._library.Options) do
        if not self:_isIgnored(flag) then
            local val = option.Value
            if typeof(val) == "Color3" then
                data.Options[flag] = { _type = "Color3", R = val.R, G = val.G, B = val.B }
            elseif typeof(val) == "EnumItem" then
                data.Options[flag] = { _type = "EnumItem", Enum = tostring(val.EnumType), Value = val.Name }
            else
                data.Options[flag] = val
            end
        end
    end

    local json = HttpService:JSONEncode(data)
    local path = self:_getConfigPath()
    self:_ensureFolder(self:_getBasePath())
    self:_ensureFolder(path)
    writefile(path .. "/" .. name .. ".json", json)
end

function SaveManager:Load(name)
    if not self._library then warn("[Valincia] SaveManager: No library set") return end

    local path = self:_getConfigPath() .. "/" .. name .. ".json"
    if not isfile(path) then
        warn("[Valincia] SaveManager: Config not found:", name)
        return
    end

    local json = readfile(path)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or not data then
        warn("[Valincia] SaveManager: Failed to decode config:", name)
        return
    end

    -- Apply toggles
    if data.Toggles then
        for flag, val in pairs(data.Toggles) do
            local toggle = self._library.Toggles[flag]
            if toggle then
                toggle:SetValue(val)
            end
        end
    end

    -- Apply options
    if data.Options then
        for flag, val in pairs(data.Options) do
            local option = self._library.Options[flag]
            if option then
                if type(val) == "table" and val._type == "Color3" then
                    option:SetValue(Color3.new(val.R, val.G, val.B))
                elseif type(val) == "table" and val._type == "EnumItem" then
                    local enumType = Enum[val.Enum]
                    if enumType then
                        local enumVal = enumType[val.Value]
                        if enumVal then option:SetValue(enumVal) end
                    end
                else
                    option:SetValue(val)
                end
            end
        end
    end
end

function SaveManager:Delete(name)
    local path = self:_getConfigPath() .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
    end
end

function SaveManager:GetConfigs()
    local path = self:_getConfigPath()
    if not isfolder(path) then return {} end

    local files = listfiles(path)
    local configs = {}
    for _, file in ipairs(files) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(configs, name)
        end
    end
    return configs
end

function SaveManager:SetAutoload(name)
    local path = self:_getBasePath()
    self:_ensureFolder(path)
    writefile(path .. "/autoload.txt", name)
    self._autoloadFile = name
end

function SaveManager:LoadAutoloadConfig()
    local path = self:_getBasePath() .. "/autoload.txt"
    if isfile(path) then
        local name = readfile(path):gsub("%s+", "")
        if name ~= "" then
            self:Load(name)
        end
    end
end

function SaveManager:BuildConfigSection(tab)
    if not self._library then return end

    local groupbox = tab:AddRightGroupbox("Configuration")

    -- Config name input
    groupbox:AddInput("SaveManager_ConfigName", {
        Text = "Config Name",
        Default = "default",
        Placeholder = "Config name...",
    })

    -- Save button
    groupbox:AddButton({
        Text = "Save Config",
        Callback = function()
            local name = self._library.Options["SaveManager_ConfigName"]
            if name then
                self:Save(name.Value)
                self._library:Notify({ Text = "Config saved: " .. name.Value })
            end
        end,
    })

    -- Load button
    groupbox:AddButton({
        Text = "Load Config",
        Callback = function()
            local name = self._library.Options["SaveManager_ConfigName"]
            if name then
                self:Load(name.Value)
                self._library:Notify({ Text = "Config loaded: " .. name.Value })
            end
        end,
    })

    -- Delete button
    groupbox:AddButton({
        Text = "Delete Config",
        Callback = function()
            local name = self._library.Options["SaveManager_ConfigName"]
            if name then
                self:Delete(name.Value)
                self._library:Notify({ Text = "Config deleted: " .. name.Value })
            end
        end,
    })

    groupbox:AddDivider()

    -- Set autoload
    groupbox:AddButton({
        Text = "Set as Autoload",
        Callback = function()
            local name = self._library.Options["SaveManager_ConfigName"]
            if name then
                self:SetAutoload(name.Value)
                self._library:Notify({ Text = "Autoload set: " .. name.Value })
            end
        end,
    })

    -- Config list dropdown
    groupbox:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved Configs",
        Values = self:GetConfigs(),
        Callback = function(val)
            local nameInput = self._library.Options["SaveManager_ConfigName"]
            if nameInput and val then
                nameInput:SetValue(val)
            end
        end,
    })

    -- Refresh configs button
    groupbox:AddButton({
        Text = "Refresh Config List",
        Callback = function()
            local dd = self._library.Options["SaveManager_ConfigList"]
            if dd then
                dd:SetValues(self:GetConfigs())
            end
        end,
    })
end

return SaveManager
