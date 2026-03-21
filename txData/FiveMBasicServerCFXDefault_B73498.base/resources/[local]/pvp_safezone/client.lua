-- ==============================================
-- SAFEZONE CLIENT.LUA - Protection + Affichage visuel
-- ==============================================

local safezones = {}
local inSafezone = false
local currentZoneId = nil

-- Réception des safezones depuis le serveur
RegisterNetEvent('pvp_safezone:sync')
AddEventHandler('pvp_safezone:sync', function(zones)
    safezones = zones or {}

    -- Met à jour les blips sur la carte
    removeAllBlips()
    for id, zone in pairs(safezones) do
        createBlip(zone)
    end
end)

-- ==============================================
-- BLIPS SUR LA CARTE
-- ==============================================
local blips = {}

function createBlip(zone)
    local blip = AddBlipForRadius(zone.x, zone.y, zone.z, zone.radius + 0.0)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 2) -- Vert
    SetBlipAlpha(blip, 80)

    -- Blip icône au centre
    local iconBlip = AddBlipForCoord(zone.x, zone.y, zone.z)
    SetBlipSprite(iconBlip, 310) -- Icône bouclier/protection
    SetBlipDisplay(iconBlip, 4)
    SetBlipScale(iconBlip, 0.8)
    SetBlipColour(iconBlip, 2) -- Vert
    SetBlipAsShortRange(iconBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Safezone #" .. zone.id)
    EndTextCommandSetBlipName(iconBlip)

    table.insert(blips, blip)
    table.insert(blips, iconBlip)
end

function removeAllBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

-- ==============================================
-- PROTECTION DANS LA SAFEZONE
-- ==============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200) -- Vérifie toutes les 200ms

        local ped = PlayerPedId()
        local myCoords = GetEntityCoords(ped)
        local wasInSafezone = inSafezone
        inSafezone = false
        currentZoneId = nil

        -- Vérifie si on est dans une safezone
        for id, zone in pairs(safezones) do
            local dist = #(myCoords - vector3(zone.x, zone.y, zone.z))
            if dist < zone.radius then
                inSafezone = true
                currentZoneId = id
                break
            end
        end

        -- Transition : on entre dans une safezone
        if inSafezone and not wasInSafezone then
            TriggerEvent('chat:addMessage', { color = {0, 255, 0}, args = {'[SAFEZONE]', 'Tu es en zone protegee - Pas de degats'} })
        end

        -- Transition : on sort de la safezone
        if not inSafezone and wasInSafezone then
            TriggerEvent('chat:addMessage', { color = {255, 165, 0}, args = {'[SAFEZONE]', 'Tu quittes la zone protegee - Attention !'} })
        end
    end
end)

-- Boucle de protection active (quand on est dans une safezone)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if inSafezone then
            local ped = PlayerPedId()

            -- Invincible dans la safezone
            SetEntityInvincible(ped, true)

            -- Désactive le tir des armes
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)  -- Attaque
            DisableControlAction(0, 25, true)  -- Viser
            DisableControlAction(0, 47, true)  -- Tir arme (sniper)
            DisableControlAction(0, 53, true)  -- Tir arme 2
            DisableControlAction(0, 257, true) -- Attaque 2
            DisableControlAction(0, 263, true) -- Attaque mêlée

            -- Affichage texte à l'écran
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
            -- Hors safezone : on remet la vulnérabilité
            SetEntityInvincible(PlayerPedId(), false)
        end
    end
end)

-- ==============================================
-- MARQUEUR VISUEL AU SOL (cercle vert)
-- ==============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local myCoords = GetEntityCoords(PlayerPedId())

        for id, zone in pairs(safezones) do
            local dist = #(myCoords - vector3(zone.x, zone.y, zone.z))

            -- Affiche le cercle uniquement si on est à moins de 200m
            if dist < 200.0 then
                DrawMarker(
                    1,                          -- Type: cylindre
                    zone.x, zone.y, zone.z - 1.0, -- Position (légèrement sous le sol)
                    0.0, 0.0, 0.0,              -- Direction
                    0.0, 0.0, 0.0,              -- Rotation
                    zone.radius * 2,            -- Largeur (diamètre)
                    zone.radius * 2,            -- Profondeur (diamètre)
                    1.0,                        -- Hauteur
                    0, 200, 50, 40,             -- Couleur RGBA (vert transparent)
                    false,                      -- Pas de rotation
                    false, 2, nil, nil, false    -- Params additionnels
                )
            end
        end
    end
end)
