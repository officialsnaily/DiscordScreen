--[[
    DiscordScreen - Server Script
]]

-- ADD YOUR DISCORD WEBHOOK HERE
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
local CURRENT_VERSION = "1.1.1" 

local screenshotCounts = {}
local lastScreenshotTime = {}

RegisterCommand("screen", function(source, args)
    local target = tonumber(args[1])
    local reason = table.concat(args, " ", 2)
    local requesterName = source > 0 and GetPlayerName(source) or "Console"
    local requesterId = source > 0 and source or 0

    if not target then print("^1[DiscordScreen] Invalid ID.^7") return end

    -- if lastScreenshotTime[target] and (os.time() - lastScreenshotTime[target]) < 10 then ... end
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

    -- Check if data is too small (fail)
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
    local idString = table.concat(identifiers, "\n")
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
        footer = { text = "System by Team Snaily" }
    }

    print("^3[DiscordScreen] Server: Handing over to JS uploader...^7")
    TriggerEvent("DiscordScreen:executeJS_Upload", DISCORD_WEBHOOK, data, embedData)
end)
