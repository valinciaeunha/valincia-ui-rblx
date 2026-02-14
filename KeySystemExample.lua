--[[
    Valincia UI — Key System Example
    
    Usage in executor:
    loadstring(game:HttpGet("YOUR_RAW_URL/KeySystemExample.lua"))()
    
    This demonstrates a key system gate before loading your main script.
    Users must enter a valid key before the main UI unlocks.
]]

-- Load library
local repo = "https://raw.githubusercontent.com/valinciaeunha/valincia-ui-rblx/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- Unload previous instance
if getgenv().ValinciaKeySystem then
    getgenv().ValinciaKeySystem:Unload()
end
getgenv().ValinciaKeySystem = Library

--------------------------------------------------------------------------------
-- Configuration — Change these for your script
--------------------------------------------------------------------------------
local KEY_URL = "https://linkvertise.com/YOUR_LINK_HERE" -- Link to get key
local VALID_KEYS = {
    "VALINCIA-XXXX-YYYY-ZZZZ",  -- Example valid key
    "TEST-KEY-1234",             -- Another valid key
}
local DISCORD_INVITE = "https://discord.gg/your-server"

--------------------------------------------------------------------------------
-- Key System Window
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

-- ═══════════════════════════════════════
--  KEY SYSTEM TAB
-- ═══════════════════════════════════════
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
        Text = "🔑 Get Key",
        Callback = function()
            -- Open the key link
            if setclipboard then
                setclipboard(KEY_URL)
                Library:Notify({
                    Text = "Key link copied to clipboard!",
                    Duration = 3,
                })
            else
                Library:Notify({
                    Text = "Go to: " .. KEY_URL,
                    Duration = 5,
                })
            end
        end,
    },
    {
        Text = "✅ Validate",
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

            -- Check if key is valid
            local isValid = false
            for _, validKey in ipairs(VALID_KEYS) do
                if enteredKey == validKey then
                    isValid = true
                    break
                end
            end

            if isValid then
                Library:Notify({
                    Text = "Key valid! Loading script...",
                    Duration = 3,
                })

                -- Destroy the key system UI
                task.delay(1.5, function()
                    Library:Unload()
                    getgenv().ValinciaKeySystem = nil

                    -- ============================================
                    -- LOAD YOUR MAIN SCRIPT HERE
                    -- ============================================
                    -- Example:
                    -- loadstring(game:HttpGet(repo .. "Example.lua"))()
                    print("[Valincia] Key validated! Main script loading...")
                end)
            else
                Library:Notify({
                    Text = "Invalid key! Try again.",
                    Duration = 3,
                })
            end
        end,
    },
})

-- ═══════════════════════════════════════
--  INFO TAB
-- ═══════════════════════════════════════
local InfoGroup = Tabs.Info:AddGroupbox("How to Get a Key")

InfoGroup:AddLabel("1. Click the 'Get Key' button")
InfoGroup:AddLabel("2. Complete the link steps")
InfoGroup:AddLabel("3. Copy the key shown at the end")
InfoGroup:AddLabel("4. Paste it in the Key System tab")
InfoGroup:AddLabel("5. Click 'Validate' to unlock")

InfoGroup:AddDivider()

InfoGroup:AddLabel("Keys expire every 24 hours.")
InfoGroup:AddLabel("Get a new key daily to continue using.")

local LinksGroup = Tabs.Info:AddGroupbox("Links & Support")

LinksGroup:AddButton({
    Text = "📋 Copy Discord Invite",
    Callback = function()
        if setclipboard then
            setclipboard(DISCORD_INVITE)
            Library:Notify({
                Text = "Discord invite copied!",
                Duration = 2,
            })
        else
            Library:Notify({
                Text = DISCORD_INVITE,
                Duration = 5,
            })
        end
    end,
})

LinksGroup:AddButton({
    Text = "📋 Copy Key Link",
    Callback = function()
        if setclipboard then
            setclipboard(KEY_URL)
            Library:Notify({
                Text = "Key link copied!",
                Duration = 2,
            })
        else
            Library:Notify({
                Text = KEY_URL,
                Duration = 5,
            })
        end
    end,
})

LinksGroup:AddDivider()

LinksGroup:AddLabel("Need help? Join our Discord!")
LinksGroup:AddLabel("Report bugs in #support channel.")
