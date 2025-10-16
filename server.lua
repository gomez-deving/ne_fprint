local Framework = nil
local usingFramework = "standalone"

-- Detect framework
CreateThread(function()
    if Config.Framework == "esx" or (Config.Framework == "auto" and GetResourceState('es_extended') == 'started') then
        Framework = exports['es_extended']:getSharedObject()
        usingFramework = "esx"
        print("[fingerprint] Using ESX Legacy")
    elseif Config.Framework == "nd" or (Config.Framework == "auto" and GetResourceState('ND_Core') == 'started') then
        Framework = exports['ND_Core']
        usingFramework = "nd"
        print("[fingerprint] Using ND_Core")
    else
        print("[fingerprint] Using Standalone mode")
    end
end)

-- Discord logging function
local function SendDiscordLog(title, description)
    if not Config.WebhookURL or Config.WebhookURL == "" then return end

    local data = {
        username = Config.WebhookName,
        avatar_url = Config.WebhookAvatar,
        embeds = {{
            title = title,
            description = description,
            color = 3447003, -- blue
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, "POST", json.encode(data), {["Content-Type"] = "application/json"})
end

-- Get player info
local function GetPlayerInfo(targetId)
    if usingFramework == "esx" then
        local xPlayer = Framework.GetPlayerFromId(targetId)
        if xPlayer then
            local firstName = xPlayer.get("firstName") or "Unknown"
            local lastName = xPlayer.get("lastName") or ""
            local dob = xPlayer.get("dateofbirth") or xPlayer.get("dob") or "Unknown"
            return {
                name = firstName .. " " .. lastName,
                dob = dob,
                identifier = xPlayer.identifier or "Unknown",
                id = targetId
            }
        end

    elseif usingFramework == "nd" then
        local allPlayers = Framework.getPlayers(nil, nil, true)
        if not allPlayers then
            print("[fingerprint] ND_Core: no players returned by getPlayers()")
            return { name = "Unknown", dob = "Unknown", identifier = targetId, id = targetId }
        end

        for _, ply in ipairs(allPlayers) do
            if ply.source == targetId then
                local fullname = ply.fullname or ply.name or "Unknown"
                local dob = ply.dob or ply.dateOfBirth or "Unknown"

                return { name = fullname, dob = dob, identifier = targetId, id = targetId }
            end
        end

        print("[fingerprint] ND_Core: player not found in getPlayers() for ID " .. targetId)
        return { name = "Unknown", dob = "Unknown", identifier = targetId, id = targetId }

    else
        -- Standalone
        local name = GetPlayerName(targetId) or "John Doe"
        local dob = "N/A"
        return { name = name, dob = dob, identifier = "N/A", id = targetId }
    end

    return { name = "Unknown", dob = "Unknown", identifier = targetId, id = targetId }
end

-- Permission check
local function HasAccess(src)
    if Config.TestMode then return true end
    if #Config.AllowedJobs == 0 then return true end

    if usingFramework == "esx" then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            for _, job in ipairs(Config.AllowedJobs) do
                if xPlayer.job.name == job then return true end
            end
        end

    elseif usingFramework == "nd" then
        local allPlayers = Framework.getPlayers(nil, nil, true)
        if not allPlayers then return false end

        for _, ply in ipairs(allPlayers) do
            if ply.source == src then
                local jobName = nil
                if ply.job then
                    if type(ply.job) == "table" then
                        jobName = ply.job.name
                    elseif type(ply.job) == "string" then
                        jobName = ply.job
                    end
                end
                for _, allowed in ipairs(Config.AllowedJobs) do
                    if jobName == allowed then return true end
                end
            end
        end

    else
        return true
    end

    return false
end

-- Scan player
RegisterNetEvent("fingerprint:scanPlayer", function(targetServerId)
    local src = source

    if not HasAccess(src) then
        TriggerClientEvent("fingerprint:scanDenied", src, Config.Messages.NoAccess)
        return
    end

    local target = tonumber(targetServerId)
    if not target then
        TriggerClientEvent("fingerprint:scanFailed", src, Config.Messages.NoPlayer)
        return
    end

    local info = GetPlayerInfo(target)
    if info then
        -- Send data to scanning client
        TriggerClientEvent("fingerprint:showResult", src, info)

        -- Discord logging
        local officer = GetPlayerName(src) or "Unknown Officer"
        local targetName = info.name or "Unknown"
        local targetDOB = info.dob or "Unknown"
        local message = string.format("**%s** scanned **%s** (DOB: %s)", officer, targetName, targetDOB)
        SendDiscordLog("Fingerprint Scan", message)
    else
        TriggerClientEvent("fingerprint:scanFailed", src, Config.Messages.ScanFailed)
    end
end)