--[[
    Valincia UI — Key System Example (API + Auto-Save)
    
    Usage in executor:
    loadstring(game:HttpGet("YOUR_RAW_URL/KeySystemExample.lua"))()
    
    Features:
    - API-based key validation (GET request)
    - Auto-save validated key locally
    - Configurable expiry time (in hours)
    - Auto-skip key entry if saved key is still valid
    
    Expected API Response (JSON):
    Success: {"valid": true}
    Failure: {"valid": false, "message": "Key expired"}
]]

local HttpService = game:GetService("HttpService")

-- Load library
local repo = "https://raw.githubusercontent.com/valinciaeunha/valincia-ui-rblx/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- Unload previous instance
if typeof(getgenv) == "function" and getgenv().ValinciaKeySystem then
    getgenv().ValinciaKeySystem:Unload()
end
if typeof(getgenv) == "function" then
    getgenv().ValinciaKeySystem = Library
end

--------------------------------------------------------------------------------
-- Configuration — Change these for your script
--------------------------------------------------------------------------------
local CONFIG = {
    -- URL for key validation. Supports multiple formats:
    --   1. JSON API:   Returns {"valid": true/false, "message": "..."}
    --   2. Key List:   Plain text with one valid key per line
    --   3. Leave empty ("") to use only local VALID_KEYS below
    API_URL = "https://file.vinzhub.com/f/Uka1zW",

    -- Hardcoded valid keys (always checked first, before API)
    -- Leave empty {} if you only want API validation
    VALID_KEYS = {
        "VALINCIA-XXXX-YYYY-ZZZZ",
        "TEST-KEY-1234",
    },

    -- Link where users can obtain a key
    KEY_URL = "https://linkvertise.com/YOUR_LINK_HERE",

    -- Discord invite link
    DISCORD_INVITE = "https://discord.gg/your-server",

    -- Key expiry time in hours (set to 24 for daily keys, 1 for hourly, etc.)
    EXPIRY_HOURS = 24,

    -- Local save file name (stored in executor's workspace folder)
    SAVE_FOLDER = "Valincia",
    SAVE_FILE = "key_data.json",
}

--------------------------------------------------------------------------------
-- Key Storage (Local File System)
--------------------------------------------------------------------------------
local KeyStorage = {}

function KeyStorage:_getPath()
    return CONFIG.SAVE_FOLDER .. "/" .. CONFIG.SAVE_FILE
end

function KeyStorage:_ensureFolder()
    if isfolder and not isfolder(CONFIG.SAVE_FOLDER) then
        makefolder(CONFIG.SAVE_FOLDER)
    end
end

function KeyStorage:Save(key)
    self:_ensureFolder()
    local data = {
        key = key,
        timestamp = os.time(),
        expiry_hours = CONFIG.EXPIRY_HOURS,
    }
    local json = HttpService:JSONEncode(data)
    if writefile then
        writefile(self:_getPath(), json)
    end
end

function KeyStorage:Load()
    local path = self:_getPath()
    if not isfile or not isfile(path) then
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok or not data or not data.key or not data.timestamp then
        return nil
    end

    return data
end

function KeyStorage:IsExpired(data)
    if not data or not data.timestamp then return true end
    local elapsed = os.time() - data.timestamp
    local maxSeconds = CONFIG.EXPIRY_HOURS * 3600
    return elapsed >= maxSeconds
end

function KeyStorage:GetRemainingTime(data)
    if not data or not data.timestamp then return 0 end
    local elapsed = os.time() - data.timestamp
    local maxSeconds = CONFIG.EXPIRY_HOURS * 3600
    local remaining = maxSeconds - elapsed
    if remaining < 0 then remaining = 0 end
    return remaining
end

function KeyStorage:FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

function KeyStorage:Clear()
    local path = self:_getPath()
    if isfile and isfile(path) and delfile then
        delfile(path)
    end
end

--------------------------------------------------------------------------------
-- Key Validation (Flexible: Local Keys + JSON API + Plain Text Key List)
--------------------------------------------------------------------------------
local function checkLocalKeys(key)
    for _, validKey in ipairs(CONFIG.VALID_KEYS) do
        if string.upper(key) == string.upper(validKey) then
            return true
        end
    end
    return false
end

local function validateKey(key)
    -- Step 1: Check local hardcoded keys first
    if #CONFIG.VALID_KEYS > 0 and checkLocalKeys(key) then
        return true, "Key validated (local)"
    end

    -- Step 2: If API_URL is configured, validate via remote
    if CONFIG.API_URL == "" then
        return false, "Invalid key"
    end

    local ok, response = pcall(function()
        return game:HttpGet(CONFIG.API_URL)
    end)

    if not ok or not response then
        return false, "Failed to connect to server"
    end

    -- Try parsing as JSON first
    local parseOk, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if parseOk and type(data) == "table" then
        -- Format A: JSON API response {"valid": true/false}
        if data.valid ~= nil then
            if data.valid == true then
                return true, data.message or "Key validated"
            else
                return false, data.message or "Invalid key"
            end
        end

        -- Format B: JSON array of valid keys ["KEY1", "KEY2", ...]
        if #data > 0 then
            for _, validKey in ipairs(data) do
                if type(validKey) == "string" and string.upper(key) == string.upper(validKey) then
                    return true, "Key validated"
                end
            end
            return false, "Invalid key"
        end
    end

    -- Format C: Plain text key list (one key per line)
    if type(response) == "string" and #response > 0 then
        for line in response:gmatch("[^\r\n]+") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed and #trimmed > 0 and string.upper(key) == string.upper(trimmed) then
                return true, "Key validated"
            end
        end
        return false, "Invalid key"
    end

    return false, "Could not validate key"
end

--------------------------------------------------------------------------------
-- Main Script Loader (called after successful validation)
--------------------------------------------------------------------------------
local function loadMainScript()
    Library:Unload()
    if typeof(getgenv) == "function" then
        getgenv().ValinciaKeySystem = nil
    end

    -- Load main script after key validation
    print("[Valincia] Key validated! Loading main script...")
    loadstring(game:HttpGet(repo .. "Example.lua"))()
end

--------------------------------------------------------------------------------
-- Check Saved Key on Startup
--------------------------------------------------------------------------------
local savedData = KeyStorage:Load()

if savedData and not KeyStorage:IsExpired(savedData) then
    -- Saved key is still valid, verify with API one more time
    local remaining = KeyStorage:GetRemainingTime(savedData)
    local isValid, msg = validateKey(savedData.key)

    if isValid then
        Library:Notify({
            Text = "Key auto-loaded! Expires in " .. KeyStorage:FormatTime(remaining),
            Duration = 3,
        })
        task.delay(1.5, loadMainScript)
        return -- Skip UI entirely
    else
        -- API rejected the saved key, clear it
        KeyStorage:Clear()
        Library:Notify({
            Text = "Saved key rejected: " .. msg,
            Duration = 3,
        })
    end
end

--------------------------------------------------------------------------------
-- Key System Window (shown only if no valid saved key)
--------------------------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "Valincia | Key System",
    Footer = "v1.0.0",
    Center = true,
    AutoShow = true,
    Size = UDim2.new(0, 460, 0, 320),
    Icon = 139563907510631,
    OpenImageId = 139563907510631,
})

-- Tabs
local Tabs = {
    KeySystem = Window:AddTab("Key System"),
    Info = Window:AddTab("Info"),
}

-- ===========================================
--  KEY SYSTEM TAB
-- ===========================================
local KeyGroup = Tabs.KeySystem:AddGroupbox("Enter Your Key")

KeyGroup:AddLabel("Paste your key below to unlock the script.")

KeyGroup:AddInput("KeyInput", {
    Text = "Key",
    Default = "",
    Placeholder = "VALINCIA-XXXX-YYYY-ZZZZ",
})

KeyGroup:AddDivider()

KeyGroup:AddButtonRow({
    {
        Text = "Get Key",
        Callback = function()
            if setclipboard then
                setclipboard(CONFIG.KEY_URL)
                Library:Notify({
                    Text = "Key link copied to clipboard!",
                    Duration = 3,
                })
            else
                Library:Notify({
                    Text = "Go to: " .. CONFIG.KEY_URL,
                    Duration = 5,
                })
            end
        end,
    },
    {
        Text = "Validate",
        Callback = function()
            local keyInput = Library.Options["KeyInput"]
            if not keyInput then return end

            local enteredKey = keyInput.Value
            if enteredKey == "" or enteredKey == nil then
                Library:Notify({
                    Text = "Please enter a key first!",
                    Duration = 3,
                })
                return
            end

            Library:Notify({
                Text = "Validating key...",
                Duration = 2,
            })

            -- Validate via API
            task.spawn(function()
                local isValid, msg = validateKey(enteredKey)

                if isValid then
                    -- Save key locally with timestamp
                    KeyStorage:Save(enteredKey)
                    local remaining = CONFIG.EXPIRY_HOURS * 3600

                    Library:Notify({
                        Text = "Key valid! Expires in " .. KeyStorage:FormatTime(remaining),
                        Duration = 3,
                    })

                    task.delay(1.5, loadMainScript)
                else
                    Library:Notify({
                        Text = msg or "Invalid key! Try again.",
                        Duration = 3,
                    })
                end
            end)
        end,
    },
})

-- Status info
local StatusGroup = Tabs.KeySystem:AddGroupbox("Status")

local savedInfo = KeyStorage:Load()
if savedInfo then
    if KeyStorage:IsExpired(savedInfo) then
        StatusGroup:AddLabel("Previous key has expired.")
        StatusGroup:AddLabel("Please enter a new key.")
    else
        local remaining = KeyStorage:GetRemainingTime(savedInfo)
        StatusGroup:AddLabel("Saved key found but API rejected it.")
        StatusGroup:AddLabel("Time was remaining: " .. KeyStorage:FormatTime(remaining))
    end
else
    StatusGroup:AddLabel("No saved key found.")
end

StatusGroup:AddLabel("Keys are valid for " .. CONFIG.EXPIRY_HOURS .. " hours.")

-- ===========================================
--  INFO TAB
-- ===========================================
local InfoGroup = Tabs.Info:AddGroupbox("How to Get a Key")

InfoGroup:AddLabel("1. Click the 'Get Key' button")
InfoGroup:AddLabel("2. Complete the link steps")
InfoGroup:AddLabel("3. Copy the key shown at the end")
InfoGroup:AddLabel("4. Paste it in the Key System tab")
InfoGroup:AddLabel("5. Click 'Validate' to unlock")

InfoGroup:AddDivider()

InfoGroup:AddLabel("Keys expire every " .. CONFIG.EXPIRY_HOURS .. " hours.")
InfoGroup:AddLabel("Key is auto-saved after validation.")
InfoGroup:AddLabel("On next run, valid keys load automatically.")

local LinksGroup = Tabs.Info:AddGroupbox("Links & Support")

LinksGroup:AddButton({
    Text = "Copy Discord Invite",
    Callback = function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD_INVITE)
            Library:Notify({
                Text = "Discord invite copied!",
                Duration = 2,
            })
        else
            Library:Notify({
                Text = CONFIG.DISCORD_INVITE,
                Duration = 5,
            })
        end
    end,
})

LinksGroup:AddButton({
    Text = "Copy Key Link",
    Callback = function()
        if setclipboard then
            setclipboard(CONFIG.KEY_URL)
            Library:Notify({
                Text = "Key link copied!",
                Duration = 2,
            })
        else
            Library:Notify({
                Text = CONFIG.KEY_URL,
                Duration = 5,
            })
        end
    end,
})

LinksGroup:AddDivider()

LinksGroup:AddLabel("Need help? Join our Discord!")
LinksGroup:AddLabel("Report bugs in #support channel.")
