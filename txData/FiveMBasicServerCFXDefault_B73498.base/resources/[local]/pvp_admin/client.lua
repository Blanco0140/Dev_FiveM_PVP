-- ==============================================
-- ADMIN CLIENT.LUA - Réception des téléportations
-- ==============================================

-- Quand le serveur nous dit de nous téléporter quelque part
RegisterNetEvent('pvp_admin:teleport')
AddEventHandler('pvp_admin:teleport', function(x, y, z)
    local ped = PlayerPedId()

    -- Téléporte le joueur aux coordonnées reçues
    SetEntityCoords(ped, x, y, z + 1.0, false, false, false, true)

    -- Petit effet pour que ce soit propre (évite de tomber dans le vide)
    RequestCollisionAtCoord(x, y, z)
    Citizen.Wait(500)
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
local noclipCam = nil

-- F10 = touche 57 dans FiveM (INPUT_SELECT_WEAPON_SPECIAL est 57)
-- On utilise RegisterKeyMapping pour lier F10 à une commande
RegisterCommand('noclip', function()
    noclipActive = not noclipActive
    local ped = PlayerPedId()

    if noclipActive then
        -- ACTIVER LE NOCLIP

        -- Rend le joueur invisible pour les autres
        SetEntityVisible(ped, false, false)

        -- Le joueur ne peut plus recevoir de dégâts
        SetEntityInvincible(ped, true)

        -- Désactive les collisions (on traverse les murs)
        SetEntityCollision(ped, false, false)

        -- Freeze le personnage (il ne bouge plus tout seul)
        FreezeEntityPosition(ped, true)

        -- Message dans le chat
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'[ADMIN]', 'Noclip ACTIVÉ - ZQSD pour bouger, Shift = vitesse rapide'}
        })
    else
        -- DÉSACTIVER LE NOCLIP

        -- Remet le joueur visible
        SetEntityVisible(ped, true, false)

        -- Réactive les dégâts
        SetEntityInvincible(ped, false)

        -- Réactive les collisions
        SetEntityCollision(ped, true, true)

        -- Défreeze le personnage
        FreezeEntityPosition(ped, false)

        -- Message dans le chat
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
        Citizen.Wait(0)

        if noclipActive then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetGameplayCamRot(2)

            -- Calcul de la direction de la caméra (où on regarde)
            local camForwardX = -math.sin(math.rad(heading.z)) * math.cos(math.rad(heading.x))
            local camForwardY =  math.cos(math.rad(heading.z)) * math.cos(math.rad(heading.x))
            local camForwardZ =  math.sin(math.rad(heading.x))

            -- Droite de la caméra (pour aller à gauche/droite)
            local camRightX = math.cos(math.rad(heading.z))
            local camRightY = math.sin(math.rad(heading.z))

            -- Vitesse : rapide si Shift est maintenu, normale sinon
            local speed = noclipSpeed
            if IsControlPressed(0, 21) then -- 21 = Shift (Sprint)
                speed = noclipFastSpeed
            end

            -- Vitesse lente si Ctrl est maintenu
            if IsControlPressed(0, 36) then -- 36 = Ctrl (Duck)
                speed = noclipSpeed * 0.3
            end

            local newX = coords.x
            local newY = coords.y
            local newZ = coords.z

            -- Z (avant) = Avancer
            if IsControlPressed(0, 32) then -- 32 = W/Z (Move Forward)
                newX = newX + camForwardX * speed * 0.1
                newY = newY + camForwardY * speed * 0.1
                newZ = newZ + camForwardZ * speed * 0.1
            end

            -- S = Reculer
            if IsControlPressed(0, 33) then -- 33 = S (Move Backward)
                newX = newX - camForwardX * speed * 0.1
                newY = newY - camForwardY * speed * 0.1
                newZ = newZ - camForwardZ * speed * 0.1
            end

            -- Q = Aller à gauche
            if IsControlPressed(0, 34) then -- 34 = A/Q (Move Left)
                newX = newX - camRightX * speed * 0.1
                newY = newY - camRightY * speed * 0.1
            end

            -- D = Aller à droite
            if IsControlPressed(0, 35) then -- 35 = D (Move Right)
                newX = newX + camRightX * speed * 0.1
                newY = newY + camRightY * speed * 0.1
            end

            -- On déplace le personnage à la nouvelle position
            SetEntityCoordsNoOffset(ped, newX, newY, newZ, true, true, true)

            -- On tourne le personnage dans la direction de la caméra
            SetEntityHeading(ped, heading.z)

            -- Empêche le jeu d'afficher le personnage en train de marcher/courir
            DisableControlAction(0, 32, true)  -- W
            DisableControlAction(0, 33, true)  -- S
            DisableControlAction(0, 34, true)  -- A/Q
            DisableControlAction(0, 35, true)  -- D
        end
    end
end)
