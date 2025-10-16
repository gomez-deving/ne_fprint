local phoneProp = nil
local hasNuiOpen = false
local currentTarget = nil
local myPedId = nil
local currentStatus = 'out'
local lastDict = nil
local lastAnim = nil

-- Framework detection
local usingFramework = "standalone"
CreateThread(function()
    if Config.Framework == "esx" or (Config.Framework == "auto" and GetResourceState('es_extended') == 'started') then
        usingFramework = "esx"
    elseif Config.Framework == "nd" or (Config.Framework == "auto" and GetResourceState('ND_Core') == 'started') then
        usingFramework = "nd"
    end
end)

-- Notification helper
local function ShowNotification(msg, type)
    if Config.UseChatOutput then
        TriggerEvent('chat:addMessage', { args = {"Fingerprint", msg} })
    elseif Config.UseNotificationOutput then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, false)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end

-- Draw 3D text
local function Draw3DText(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Closest player
local function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance, closestPlayer = -1, -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, v in pairs(players) do
        if v ~= PlayerId() then
            local targetPed = GetPlayerPed(v)
            local dist = #(playerCoords - GetEntityCoords(targetPed))
            if closestDistance == -1 or dist < closestDistance then
                closestPlayer = v
                closestDistance = dist
            end
        end
    end
    return closestPlayer, closestDistance
end

-- Spawn handheld prop
local function SpawnPhoneProp()
    myPedId = PlayerPedId()
    local model = GetHashKey(Config.PropModel)

    RequestModel(model)
    local timeout = 5000
    while not HasModelLoaded(model) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end

    if not HasModelLoaded(model) then
        print("[fingerprint] Failed to load prop model: " .. tostring(Config.PropModel))
        return
    end

    local playerCoords = GetEntityCoords(myPedId)
    phoneProp = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    local bone = GetPedBoneIndex(myPedId, 28422) -- right hand
    AttachEntityToEntity(phoneProp, myPedId, bone,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )

    PhonePlayText()
end

-- Delete prop
local function DeletePhoneProp()
    if phoneProp then
        DeleteObject(phoneProp)
        phoneProp = nil
        PhonePlayOut()
    end
end


local ANIMS = {
    ['cellphone@'] = {
        ['out'] = { ['text'] = 'cellphone_text_in', ['call'] = 'cellphone_call_listen_base' },
        ['text'] = { ['out'] = 'cellphone_text_out', ['text'] = 'cellphone_text_in', ['call'] = 'cellphone_text_to_call' },
        ['call'] = { ['out'] = 'cellphone_call_out', ['text'] = 'cellphone_call_to_text', ['call'] = 'cellphone_text_to_call' }
    }
}

function PhonePlayAnim(status, force)
    if currentStatus == status and force ~= true then return end
    myPedId = PlayerPedId()
    local dict = "cellphone@"
    loadAnimDict(dict)
    local anim = ANIMS[dict][currentStatus][status]
    if currentStatus ~= 'out' then StopAnimTask(myPedId, lastDict, lastAnim, 1.0) end
    TaskPlayAnim(myPedId, dict, anim, 3.0, -1, -1, 50, 0, false, false, false)
    lastDict = dict
    lastAnim = anim
    currentStatus = status
end

function PhonePlayOut() PhonePlayAnim('out') end
function PhonePlayText() PhonePlayAnim('text') end
function loadAnimDict(dict) RequestAnimDict(dict); while not HasAnimDictLoaded(dict) do Wait(1) end end

-- NUI
local function OpenTablet()
    if hasNuiOpen then return end
    hasNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", autoClose = Config.UI.AutoClose, autoCloseTime = Config.UI.AutoCloseTime, playSounds = Config.UI.PlaySounds })
end

local function CloseTablet()
    if not hasNuiOpen then return end
    hasNuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    DeletePhoneProp()
end

RegisterNUICallback("close", function(_, cb)
    CloseTablet()
    cb("ok")
end)

-- Scanner event
RegisterNetEvent("fingerprint:openTablet", function()
    local target, tdist = GetClosestPlayer()
    local targetServerId

    if (target == -1 or tdist > Config.ScanRange) and Config.TestMode then
        targetServerId = GetPlayerServerId(PlayerId())
        ShowNotification("🧪 Test Mode: Scanning yourself.")
    elseif target ~= -1 and tdist < Config.ScanRange then
        targetServerId = GetPlayerServerId(target)
    else
        ShowNotification(Config.Messages.NoPlayer, "error")
        return
    end

    SpawnPhoneProp()
    OpenTablet()
    TriggerServerEvent("fingerprint:scanPlayer", targetServerId)
    ShowNotification(Config.Messages.ScanStart)
end)

-- Server events
RegisterNetEvent("fingerprint:scanFailed", function(msg) ShowNotification(msg); CloseTablet() end)
RegisterNetEvent("fingerprint:scanDenied", function(msg) ShowNotification(msg); CloseTablet() end)
RegisterNetEvent("fingerprint:showResult", function(info)
    SendNUIMessage({
        action = "showResult",
        name = info.name or "Unknown",
        dob = info.dob or "Unknown",         -- <-- Add this
        identifier = info.identifier or "Unknown",
        matchText = Config.Messages.ScanSuccess
    })
end)

-- ESC close
CreateThread(function()
    while true do
        Wait(0)
        if hasNuiOpen and Config.UI.AllowCloseKey and IsControlJustReleased(0, 200) then
            CloseTablet()
        end
    end
end)

if Config.TestMode then
-- Test command
RegisterCommand("fingerprintscan", function()
    TriggerEvent("fingerprint:openTablet")
end, false)
end
