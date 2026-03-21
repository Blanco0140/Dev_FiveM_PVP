-- ==============================================
-- SAFEZONE CLIENT.LUA - Protection + Affichage visuel
-- ==============================================

local safezones = {}
local inSafezone = false
local currentZoneId = nil
local mapBlips = {}

-- Réception des safezones depuis le serveur
RegisterNetEvent('pvp_safezone:sync')
AddEventHandler('pvp_safezone:sync', function(zones)
    safezones = zones or {}

    -- Supprime les anciens blips de la carte
    for _, blip in ipairs(mapBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    mapBlips = {}

    -- Crée un cercle vert sur la carte pour chaque safezone
    for id, zone in pairs(safezones) do
        local radiusBlip = AddBlipForRadius(zone.x, zone.y, zone.z, zone.radius + 0.0)
        SetBlipHighDetail(radiusBlip, true)
        SetBlipColour(radiusBlip, 2) -- Vert
        SetBlipAlpha(radiusBlip, 255)
        table.insert(mapBlips, radiusBlip)
    end
end)

-- ==============================================
-- PROTECTION DANS LA SAFEZONE
-- ==============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)

        local ped = PlayerPedId()
        local myCoords = GetEntityCoords(ped)
        local wasInSafezone = inSafezone
        inSafezone = false
        currentZoneId = nil

        for id, zone in pairs(safezones) do
            local dist = #(myCoords - vector3(zone.x, zone.y, zone.z))
            if dist < zone.radius then
                inSafezone = true
                currentZoneId = id
                break
            end
        end

        if inSafezone and not wasInSafezone then
            TriggerEvent('chat:addMessage', { color = {0, 255, 0}, args = {'[SAFEZONE]', 'Tu es en zone protegee - Pas de degats'} })
        end

        if not inSafezone and wasInSafezone then
            TriggerEvent('chat:addMessage', { color = {255, 165, 0}, args = {'[SAFEZONE]', 'Tu quittes la zone protegee - Attention !'} })
        end
    end
end)

-- Boucle de protection active
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if inSafezone then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 53, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)

            SetTextFont(4)
            SetTextScale(0.38, 0.38)
            SetTextColour(0, 255, 100, 200)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("~g~SAFEZONE ~w~- Zone Protegee")
            DrawText(0.5, 0.92)
        else
            SetEntityInvincible(PlayerPedId(), false)
        end
    end
end)

