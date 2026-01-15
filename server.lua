--[[
    DiscordScreen - Server Script
    Author: Snaily Labs
]]

-- ADD YOUR DISCORD WEBHOOK HERE
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"

-- CONFIGURATION FOR VERSION CHECK
local UPDATE_URL = "https://snai.ly/discordscreenversion"
local INFO_LINK = "https://snai.ly/discordscreen"

local screenshotCounts = {}
local lastScreenshotTime = {}

RegisterCommand("screen", function(source, args)
    local target = tonumber(args[1])
    
    -- FIX: Check if reason is empty string, set to nil if so
    local rawReason = table.concat(args, " ", 2)
    local reason = (rawReason and rawReason ~= "") and rawReason or "No reason specified"

    local requesterName = source > 0 and GetPlayerName(source) or "Console"
    local requesterId = source > 0 and source or 0

    if not target then 
        print("^1[DiscordScreen] Invalid ID. Usage: /screen [id] [reason]^7") 
        return 
    end

    -- Update timestamp for cooldown tracking
    lastScreenshotTime[target] = os.time()

    -- ID -1: Request screenshot for ALL players
    if target == -1 then
        print("^3[DiscordScreen] Starting batch request for ALL players... (Throttled)^7")
        
        Citizen.CreateThread(function()
            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                TriggerClientEvent("DiscordScreen:take", tonumber(playerId), requesterName, requesterId, reason)
                Citizen.Wait(500) -- Stagger requests to prevent lag
            end
            print("^2[DiscordScreen] Batch request sent to " .. #players .. " players.^7")
        end)
        return
    end

    -- Single ID request
    TriggerClientEvent("DiscordScreen:take", target, requesterName, requesterId, reason)
    print("^3[DiscordScreen] Request sent to ID: " .. target .. "^7")
end, true)

RegisterNetEvent("DiscordScreen:receiveData")
AddEventHandler("DiscordScreen:receiveData", function(data, playerName, playerId, requesterName, requesterId, coords, health, armor, vehInfo, reason)
    print("^2[DiscordScreen] Server: Data received from ID " .. playerId .. ". Size: " .. string.len(data) .. " chars.^7")

    if string.len(data) < 100 then
        print("^1[DiscordScreen] Server: Data too small, upload aborted.^7")
        return
    end
    
    screenshotCounts[playerId] = (screenshotCounts[playerId] or 0) + 1
    
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
        local id = GetPlayerIdentifier(playerId, i)
        if not id:find("^ip:") then table.insert(identifiers, id) end
    end
    local ping = GetPlayerPing(playerId)

    -- Construct the Discord Embed
    local embedData = {
        title = Config.EMBED_TITLE,
        color = 65280, -- Green
        fields = {
            { name = "Player", value = string.format("```%s (ID: %s)```", playerName, playerId), inline = true },
            { name = "Requested By", value = string.format("```%s (ID: %s)```", requesterName, requesterId), inline = true },
            { name = "Details", value = string.format("Ping: %s\nVeh: %s", ping, vehInfo), inline = false },
            { name = "Reason", value = string.format("```%s```", reason), inline = false },
        },
        image = { url = "attachment://screenshot.jpg" },
        footer = { text = "System by Snaily Labs" }
    }

    print("^3[DiscordScreen] Server: Handing over to JS uploader...^7")
    TriggerEvent("DiscordScreen:executeJS_Upload", DISCORD_WEBHOOK, data, embedData)
end)

-- ---------------------------------------------------------
-- Snaily Labs Version Checker & Startup Print
-- ---------------------------------------------------------
Citizen.CreateThread(function()
    Citizen.Wait(1000)

    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, 'version', 0) or 'Unknown'
    
    local function PrintLogo(subtitle)
        local snailyArt = [[
^2
      ^7(O)  (O)^2
        \  /
       __\/__       ^3_____
      /  ^7U^2   \     ^3/     \    ^4SNAILY LABS
     (        )___^3(       )   ^7DiscordScreen
      \_______/   ^3 \_____/    ^7v]] .. currentVersion .. [[^2
^0
    ]]
        print(snailyArt)
        if subtitle then print(subtitle) end
    end

    PerformHttpRequest(UPDATE_URL, function(err, text, headers)
        local latestVersion = text and text:gsub("%s+", "") or nil 

        if err == 200 and latestVersion then
            if currentVersion ~= latestVersion then
                PrintLogo('^1[UPDATE] New version available: ' .. latestVersion .. '!^7')
                print('^1---------------------------------------------------^7')
                print('^1Please download the update at:^7')
                print('^4' .. INFO_LINK .. '^7')
                print('^1---------------------------------------------------^0')
            else
                PrintLogo('^4[Snaily Labs] ^7DiscordScreen is up to date and ready to roll!^0')
            end
        else
            PrintLogo('^3[Snaily Labs] ^7Could not check for updates (Offline?).^0')
        end
    end, "GET", "", {})
end)
