--[[
    DiscordScreen - Client Script
    ----------------------------
]]

RegisterNetEvent("DiscordScreen:take")
AddEventHandler("DiscordScreen:take", function(requesterName, requesterId, reason)
    local playerName = GetPlayerName(PlayerId()) or "Unknown"
    local playerId = GetPlayerServerId(PlayerId())
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)

    local veh = GetVehiclePedIsIn(ped, false)
    local vehInfo = "Not in vehicle"
    if veh and veh ~= 0 then
        local model = GetEntityModel(veh)
        local name = GetDisplayNameFromVehicleModel(model)
        local plate = GetVehicleNumberPlateText(veh)
        vehInfo = string.format("%s | Plate: %s", name, plate)
    end

    print("^3[DiscordScreen] Client: Requesting screenshot generation...^7")

    -- FIX: Force JPG and 0.5 quality to avoid NetEvent limis
    exports['screenshot-basic']:requestScreenshot({encoding = 'jpg', quality = 0.5}, function(data)
        if not data then
            print("^1[DiscordScreen] Client: Screenshot failed to generate.^7")
            return
        end

        print("^2[DiscordScreen] Client: Screenshot generated (" .. string.len(data) .. " bytes). Sending to server...^7")

        TriggerServerEvent("DiscordScreen:receiveData", 
            data, 
            playerName, playerId, requesterName, requesterId,
            coords, health, armor, vehInfo, reason
        )
    end)
end)
