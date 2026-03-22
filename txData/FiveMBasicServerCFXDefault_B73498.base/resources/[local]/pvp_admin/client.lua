-- ==============================================
-- ADMIN CLIENT.LUA - Téléportation, Revive, Menu
-- ==============================================

-- Quand le serveur nous dit de nous téléporter quelque part
RegisterNetEvent('pvp_admin:teleport')
AddEventHandler('pvp_admin:teleport', function(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z + 1.0, false, false, false, true)
    RequestCollisionAtCoord(x, y, z)
    Citizen.Wait(500)
end)

-- Quand le serveur nous dit de réanimer le joueur (il est mort)
RegisterNetEvent('pvp_admin:revive')
AddEventHandler('pvp_admin:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Résurrection du joueur
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)

    -- Remet la vie au max
    SetEntityHealth(PlayerPedId(), 200)
    ClearPedBloodDamage(PlayerPedId())
    SetPlayerInvincible(PlayerId(), false)
end)

-- Quand le serveur nous dit de soigner le joueur (il est vivant)
RegisterNetEvent('pvp_admin:heal')
AddEventHandler('pvp_admin:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
end)

-- Quand le serveur nous dit de tuer le joueur
RegisterNetEvent('pvp_admin:kill')
AddEventHandler('pvp_admin:kill', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

-- Quand le serveur nous dit de geler/dégeler le joueur
local isFrozen = false
RegisterNetEvent('pvp_admin:freeze')
AddEventHandler('pvp_admin:freeze', function()
    isFrozen = not isFrozen
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, isFrozen)
    if isFrozen then
        TriggerEvent('chat:addMessage', { color = {100,150,220}, args = {'[ADMIN]', 'Tu as été gelé par un administrateur'} })
    else
        TriggerEvent('chat:addMessage', { color = {0,255,0}, args = {'[ADMIN]', 'Tu as été dégelé'} })
    end
end)

-- /tpm : Téléporte au marqueur GPS (waypoint sur la carte)
RegisterCommand('tpm', function()
    local waypoint = GetFirstBlipInfoId(8) -- 8 = waypoint blip

    if not DoesBlipExist(waypoint) then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[ADMIN]', 'Place un marqueur sur la carte d\'abord !'} })
        return
    end

    local blipCoords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()

    -- Cherche le bon Z (hauteur du sol) pour ne pas tomber dans le vide
    local foundZ = false
    for z = 1000.0, 0.0, -25.0 do
        SetEntityCoordsNoOffset(ped, blipCoords.x, blipCoords.y, z, false, false, false)
        Citizen.Wait(50)
        RequestCollisionAtCoord(blipCoords.x, blipCoords.y, z)
        Citizen.Wait(50)
        local found, groundZ = GetGroundZFor_3dCoord(blipCoords.x, blipCoords.y, z, false)
        if found then
            SetEntityCoordsNoOffset(ped, blipCoords.x, blipCoords.y, groundZ + 1.0, false, false, false)
            foundZ = true
            break
        end
    end

    if not foundZ then
        SetEntityCoordsNoOffset(ped, blipCoords.x, blipCoords.y, 200.0, false, false, false)
    end

    TriggerEvent('chat:addMessage', { color = {0,255,0}, args = {'[ADMIN]', 'Téléporté au marqueur GPS'} })
end, true) -- admin seulement

RegisterKeyMapping('tpm', 'Teleport au marqueur GPS', 'keyboard', 'F7')

-- /spectate [id] : Observer un joueur (vue caméra)
local spectating = {}  -- table pour savoir qui spectate qui

RegisterCommand('spectate', function()
    -- Toggle spectate - si on spectate déjà, on arrête
    TriggerEvent('pvp_admin:toggleSpectate')
end, true)

-- /getcoord : Copie les coordonnées actuelles dans le presse-papier
RegisterCommand('getcoord', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local coordStr = string.format("%.4f, %.4f, %.4f, heading: %.2f", coords.x, coords.y, coords.z, heading)
    -- Active brièvement le NUI pour que le clipboard fonctionne
    SetNuiFocus(true, false)
    SendNUIMessage({ type = 'copyCoords', coords = coordStr })
    Citizen.Wait(200)
    SetNuiFocus(false, false)
    TriggerEvent('chat:addMessage', { color = {0,255,0}, args = {'[ADMIN]', 'Coordonnées copiées : ' .. coordStr} })
end, true)

RegisterKeyMapping('getcoord', 'Copier mes coordonnées', 'keyboard', 'F8')


-- ==============================================
-- SPECTATE - Mode observation
-- ==============================================

local isSpectating = false
local spectateTarget = -1

AddEventHandler('pvp_admin:toggleSpectate', function()
    if isSpectating then
        -- Arrêter le spectate
        isSpectating = false
        local ped = PlayerPedId()
        NetworkSetInSpectatorMode(false, ped)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        TriggerEvent('chat:addMessage', { color = {255,165,0}, args = {'[ADMIN]', 'Mode spectateur DÉSACTIVÉ'} })
    else
        -- Demander quel joueur spectater
        TriggerEvent('chat:addMessage', { color = {255,165,0}, args = {'[ADMIN]', 'Utilise /spec [id] pour observer un joueur'} })
    end
end)

RegisterCommand('spec', function(source, args)
    if #args < 1 then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[ADMIN]', 'Utilisation : /spec [id]'} })
        return
    end

    local targetServerId = tonumber(args[1])
    if not targetServerId then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[ADMIN]', 'ID invalide !'} })
        return
    end

    -- Cherche le joueur local qui correspond à cet ID serveur
    local targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 or targetPlayer == PlayerId() then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[ADMIN]', 'Joueur introuvable ou c\'est toi !'} })
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        TriggerEvent('chat:addMessage', { color = {255,0,0}, args = {'[ADMIN]', 'Le joueur n\'est pas disponible'} })
        return
    end

    isSpectating = true
    spectateTarget = targetPlayer
    local myPed = PlayerPedId()

    -- Rend invisible et active le mode spectateur
    SetEntityVisible(myPed, false, false)
    SetEntityCollision(myPed, false, false)
    NetworkSetInSpectatorMode(true, targetPed)

    TriggerEvent('chat:addMessage', { color = {0,255,0}, args = {'[ADMIN]', 'Mode spectateur sur le joueur ID: ' .. targetServerId .. ' (tape /spectate pour arrêter)'} })
end, true)



-- ==============================================


local menuOpen = false

RegisterCommand('playermenu', function()
    if menuOpen then
        -- Fermer le menu
        menuOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'close' })
    else
        -- Ouvrir le menu immédiatement (affiche "Chargement...")
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'open', players = {} })
        -- Puis demander la liste des joueurs au serveur
        TriggerServerEvent('pvp_admin:requestPlayers')
    end
end, true) -- admin seulement

-- Lier F9 au menu
RegisterKeyMapping('playermenu', 'Ouvrir le menu des joueurs', 'keyboard', 'F9')

-- Quand on reçoit la liste des joueurs du serveur, on met à jour le menu
RegisterNetEvent('pvp_admin:receivePlayers')
AddEventHandler('pvp_admin:receivePlayers', function(playerList)
    if menuOpen then
        SendNUIMessage({
            type = 'update',
            players = playerList
        })
    end
end)

-- Quand le joueur ferme le menu via le bouton X ou Echap
RegisterNUICallback('close', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Quand l'admin clique sur un bouton d'action dans le menu
RegisterNUICallback('action', function(data, cb)
    -- Exécute la commande correspondante
    ExecuteCommand(data.command)
    -- Rafraîchit la liste après un petit délai
    Citizen.Wait(500)
    TriggerServerEvent('pvp_admin:requestPlayers')
    cb('ok')
end)




-- Affiche l'ID de chaque joueur au-dessus de sa tête (visible uniquement pour les admins)
-- On utilise une commande pour activer/désactiver cet affichage
local showIds = false

RegisterCommand('showids', function()
    showIds = not showIds
    if showIds then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'[ADMIN]', 'Affichage des IDs : ACTIVÉ'}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Affichage des IDs : DÉSACTIVÉ'}
        })
    end
end, true) -- admin seulement

-- Boucle qui dessine les IDs au-dessus des têtes des joueurs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showIds then
            local players = GetActivePlayers()
            local myPed = PlayerPedId()

            for _, player in ipairs(players) do
                local targetPed = GetPlayerPed(player)

                -- Ne pas afficher notre propre ID
                if targetPed ~= myPed then
                    local serverId = GetPlayerServerId(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    local myCoords = GetEntityCoords(myPed)
                    local distance = #(myCoords - targetCoords)

                    -- Affiche l'ID uniquement si le joueur est à moins de 100 mètres
                    if distance < 100.0 then
                        -- Dessine le texte au-dessus de la tête du joueur
                        local headBone = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                        DrawText3D(headBone.x, headBone.y, headBone.z + 0.3, '[' .. serverId .. ']')
                    end
                end
            end
        else
            -- Si les IDs ne sont pas affichés, on attend un peu pour économiser les performances
            Citizen.Wait(500)
        end
    end
end)

-- Fonction utilitaire pour afficher du texte en 3D dans le monde
function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)

    if onScreen then
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 100, 0, 255) -- Orange
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(screenX, screenY)
    end
end


-- ==============================================
-- NOCLIP - Touche F10 pour activer/désactiver
-- Shift pour aller plus vite
-- ==============================================

local noclipActive = false
local noclipSpeed = 2.0       -- Vitesse normale
local noclipFastSpeed = 6.0   -- Vitesse rapide (avec Shift)

RegisterCommand('noclip', function()
    noclipActive = not noclipActive
    local ped = PlayerPedId()

    if noclipActive then
        -- ACTIVER LE NOCLIP
        SetEntityVisible(ped, false, false)
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)

        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'[ADMIN]', 'Noclip ACTIVÉ - ZQSD pour bouger, Shift = rapide, Ctrl = lent'}
        })
    else
        -- DÉSACTIVER LE NOCLIP
        SetEntityVisible(ped, true, false)
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)

        -- Empêche de tomber dans le vide en rechargeant le sol
        local coords = GetEntityCoords(ped)
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Noclip DÉSACTIVÉ'}
        })
    end
end, true) -- admin seulement

-- Lier la touche F10 à la commande noclip
RegisterKeyMapping('noclip', 'Activer/Désactiver le Noclip', 'keyboard', 'F10')

-- Boucle qui gère le déplacement en noclip
Citizen.CreateThread(function()
    while true do
        if noclipActive then
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetGameplayCamRot(2)

            -- Calcul de la direction de la caméra
            local camForwardX = -math.sin(math.rad(heading.z)) * math.cos(math.rad(heading.x))
            local camForwardY =  math.cos(math.rad(heading.z)) * math.cos(math.rad(heading.x))
            local camForwardZ =  math.sin(math.rad(heading.x))

            local camRightX = math.cos(math.rad(heading.z))
            local camRightY = math.sin(math.rad(heading.z))

            -- On désactive les contrôles de mouvement du jeu AVANT de les lire
            DisableControlAction(0, 30, true)  -- Gauche/Droite
            DisableControlAction(0, 31, true)  -- Avant/Arrière
            DisableControlAction(0, 32, true)  -- W
            DisableControlAction(0, 33, true)  -- S
            DisableControlAction(0, 34, true)  -- A/Q
            DisableControlAction(0, 35, true)  -- D
            DisableControlAction(0, 36, true)  -- Ctrl
            DisableControlAction(0, 21, true)  -- Shift

            -- Vitesse : rapide si Shift, lente si Ctrl
            local speed = noclipSpeed
            if IsDisabledControlPressed(0, 21) then -- Shift
                speed = noclipFastSpeed
            end
            if IsDisabledControlPressed(0, 36) then -- Ctrl
                speed = noclipSpeed * 0.3
            end

            local newX = coords.x
            local newY = coords.y
            local newZ = coords.z

            -- Z/W = Avancer
            if IsDisabledControlPressed(0, 32) then
                newX = newX + camForwardX * speed * 0.1
                newY = newY + camForwardY * speed * 0.1
                newZ = newZ + camForwardZ * speed * 0.1
            end

            -- S = Reculer
            if IsDisabledControlPressed(0, 33) then
                newX = newX - camForwardX * speed * 0.1
                newY = newY - camForwardY * speed * 0.1
                newZ = newZ - camForwardZ * speed * 0.1
            end

            -- Q/A = Gauche
            if IsDisabledControlPressed(0, 34) then
                newX = newX - camRightX * speed * 0.1
                newY = newY - camRightY * speed * 0.1
            end

            -- D = Droite
            if IsDisabledControlPressed(0, 35) then
                newX = newX + camRightX * speed * 0.1
                newY = newY + camRightY * speed * 0.1
            end

            -- Déplace le joueur
            SetEntityCoordsNoOffset(ped, newX, newY, newZ, true, true, true)
            SetEntityHeading(ped, heading.z)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ==============================================
-- VEHICULE ET ARMES (Admin)
-- ==============================================

-- /car [modele] : Fait spawn un véhicule
RegisterNetEvent('pvp_admin:spawnCar')
AddEventHandler('pvp_admin:spawnCar', function(modelName)
    local modelHash = GetHashKey(modelName)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        TriggerEvent('chat:addMessage', { color = {255, 0, 0}, args = {'[ADMIN]', 'Modele de vehicule invalide.'} })
        return
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(10)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    
    SetModelAsNoLongerNeeded(modelHash)
    TriggerEvent('chat:addMessage', { color = {0, 255, 0}, args = {'[ADMIN]', 'Vehicule ' .. modelName .. ' spawne.'} })
end)

-- /giveweapon [nom_arme] [munitions] : Se donner une arme
RegisterNetEvent('pvp_admin:giveWeapon')
AddEventHandler('pvp_admin:giveWeapon', function(weaponName, ammo)
    weaponName = string.upper(weaponName)
    if not string.find(weaponName, "WEAPON_") then
        weaponName = "WEAPON_" .. weaponName
    end

    local weaponHash = GetHashKey(weaponName)
    local ped = PlayerPedId()

    GiveWeaponToPed(ped, weaponHash, ammo, false, true)
    TriggerEvent('chat:addMessage', { color = {0, 255, 0}, args = {'[ADMIN]', 'Arme reçue : ' .. weaponName .. ' (' .. ammo .. ' balles)'} })
end)
