-- ==============================================
-- TELEPORTER CLIENT.LUA - PED + Menu TP Safezones
-- ==============================================

local teleporters = {}
local spawnedPeds = {}
local menuOpen = false

local PED_MODEL = 's_m_m_pilot_01' -- Modèle du PED

-- ==============================================
-- SYNC DES TELEPORTERS DEPUIS LE SERVEUR
-- ==============================================

RegisterNetEvent('pvp_teleporter:sync')
AddEventHandler('pvp_teleporter:sync', function(data)
    teleporters = data or {}
    -- Supprime les anciens PED
    despawnAllPeds()
    -- Crée les nouveaux PED
    for id, tp in pairs(teleporters) do
        spawnPed(id, tp)
    end
end)

-- ==============================================
-- SPAWN / DESPAWN DES PED
-- ==============================================

function spawnPed(id, tp)
    local modelHash = GetHashKey(PED_MODEL)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    if HasModelLoaded(modelHash) then
        local ped = CreatePed(4, modelHash, tp.x, tp.y, tp.z - 1.0, tp.heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)

        -- Animation idle
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

        -- Blip sur la carte
        local blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, 280) -- Icône flèche/teleport
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 46) -- Bleu/violet
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Teleporteur")
        EndTextCommandSetBlipName(blip)

        spawnedPeds[id] = { ped = ped, blip = blip }
        SetModelAsNoLongerNeeded(modelHash)
    end
end

function despawnAllPeds()
    for id, data in pairs(spawnedPeds) do
        if DoesEntityExist(data.ped) then
            DeleteEntity(data.ped)
        end
        if DoesBlipExist(data.blip) then
            RemoveBlip(data.blip)
        end
    end
    spawnedPeds = {}
end

-- ==============================================
-- INTERACTION AVEC LE PED (touche E)
-- ==============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearPed = false

        for id, data in pairs(spawnedPeds) do
            if DoesEntityExist(data.ped) then
                local pedCoords = GetEntityCoords(data.ped)
                local dist = #(playerCoords - pedCoords)

                if dist < 3.0 then
                    nearPed = true

                    -- Affiche le texte "Appuie sur E"
                    SetTextFont(4)
                    SetTextScale(0.4, 0.4)
                    SetTextColour(255, 215, 0, 230)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextOutline()
                    SetTextCentre(true)
                    SetTextEntry("STRING")
                    AddTextComponentString("Appuie sur ~y~E~w~ pour te teleporter")
                    DrawText(0.5, 0.85)

                    -- Touche E enfoncée
                    if IsControlJustReleased(0, 38) and not menuOpen then
                        openTeleportMenu()
                    end
                end
            end
        end

        if not nearPed and not menuOpen then
            Citizen.Wait(200) -- Optimisation quand loin des PED
        end
    end
end)

-- ==============================================
-- MENU TELEPORT (NUI)
-- ==============================================

function openTeleportMenu()
    -- Récupère les safezones via l'export
    local safezones = {}
    local success, zones = pcall(function()
        return exports['pvp_safezone']:GetSafezones()
    end)

    if success and zones then
        for id, zone in pairs(zones) do
            table.insert(safezones, {
                id = id,
                x = zone.x,
                y = zone.y,
                z = zone.z,
                heading = zone.heading or 0.0,
                radius = zone.radius,
                name = "Safezone #" .. id
            })
        end
    end

    if #safezones == 0 then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[TELEPORTER]', 'Aucune safezone disponible !'} })
        return
    end

    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        safezones = safezones
    })
end

-- Callback : fermer le menu
RegisterNUICallback('close', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Callback : se TP à une safezone
RegisterNUICallback('teleport', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    local heading = tonumber(data.heading) or 0.0

    if x and y and z then
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
        SetEntityHeading(ped, heading)
        TriggerEvent('chat:addMessage', { color = {0,255,0}, args = {'[TELEPORTER]', 'Teleportation reussie !'} })
    end

    cb('ok')
end)
