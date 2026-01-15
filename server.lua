--[[
    DiscordScreen - Server Script
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
    local reason = table.concat(args, " ", 2)
    local requesterName = source > 0 and GetPlayerName(source) or "Console"
    local requesterId = source > 0 and source or 0

    if not target then print("^1[DiscordScreen] Invalid ID.^7") return end

    -- Update timestamp for cooldowns
    lastScreenshotTime[target] = os.time()

    if target == -1 then
        for _, playerId in ipairs(GetPlayers()) do
            TriggerClientEvent("DiscordScreen:take", tonumber(playerId), requesterName, requesterId, reason)
        end
        print("^3[DiscordScreen] Requested all players.^7")
        return
    end

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

    local embedData = {
        title = Config.EMBED_TITLE,
        color = 65280,
        fields = {
            { name = "Player", value = string.format("```%s (ID: %s)```", playerName, playerId), inline = true },
            { name = "Requested By", value = string.format("```%s (ID: %s)```", requesterName, requesterId), inline = true },
            { name = "Details", value = string.format("Ping: %s\nVeh: %s", ping, vehInfo), inline = false },
            { name = "Reason", value = string.format("```%s```", reason or "N/A"), inline = false },
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
    Citizen.Wait(1000) -- Wait for console to settle

    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, 'version', 0) or 'Unknown'
    
    -- Function to print the logo
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

    -- Perform the version check
    PerformHttpRequest(UPDATE_URL, function(err, text, headers)
        local latestVersion = text and text:gsub("%s+", "") or nil -- Trim whitespace

        if err == 200 and latestVersion then
            if currentVersion ~= latestVersion then
                -- UPDATE AVAILABLE
                PrintLogo('^1[UPDATE] New version available: ' .. latestVersion .. '!^7')
                print('^1---------------------------------------------------^7')
                print('^1Please download the update at:^7')
                print('^4' .. INFO_LINK .. '^7')
                print('^1---------------------------------------------------^0')
            else
                -- UP TO DATE
                PrintLogo('^4[Snaily Labs] ^7DiscordScreen is up to date and ready to roll!^0')
            end
        else
            -- CHECK FAILED
            PrintLogo('^3[Snaily Labs] ^7Could not check for updates (Offline?).^0')
        end
    end, "GET", "", {})
end)
