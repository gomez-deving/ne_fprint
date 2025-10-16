--[[Event to integrate into another script
TriggerEvent("fingerprint:openTablet")
]]

Config = {}

-- Framework detection: "auto", "esx", "nd", "standalone"
Config.Framework = "auto"

--Prop settings
Config.PropModel = "prop_police_phone" -- can still change model if needed

-- Discord webhook for fingerprint logs
Config.WebhookURL = "https://discord.com/api/webhooks/1424493328979722320/_zKlqE9CGhbscybkXUVEnq9aHY1YZjhbudPPA97Vmw23OOXvH1AkdvO8a472-j1usVWF" -- replace with your webhook
Config.WebhookName = "Fingerprint Scanner"
Config.WebhookAvatar = "https://cdn.discordapp.com/attachments/1264478027585290383/1426066248407449700/FDCBFE76-C57C-4F91-B491-1B7D9E7D1A19.png?ex=68f1c830&is=68f076b0&hm=228af79c860ce70c7e534a60a372b7c88e784e8ddb5375500a3ee878419e2f1a&"

-- UI behavior
Config.UI = {}
Config.UI.AutoClose = true
Config.UI.AutoCloseTime = 10
Config.UI.PlaySounds = true
Config.UI.AllowCloseKey = true

-- Output options
Config.UseChatOutput = false
Config.UseNotificationOutput = false

-- Who can use scanner
Config.AllowedJobs = {"LSPD", "BCSO", "SAHP"}

-- Messages
Config.Messages = {
    NoPlayer = "No player nearby to scan.",
    NoAccess = "You are not authorized to use the fingerprint scanner.",
    ScanStart = "Starting fingerprint scan...",
    ScanFailed = "Unable to retrieve player information.",
    ScanSuccess = "Fingerprint match found!"
}

-- Debug and testing
Config.Debug = false         -- shows ND_Core info in console
Config.TestMode = false      -- allows scanning yourself and ignores job checks