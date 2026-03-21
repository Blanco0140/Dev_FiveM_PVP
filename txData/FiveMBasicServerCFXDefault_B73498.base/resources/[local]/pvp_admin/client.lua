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
