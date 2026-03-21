-- ==============================================
-- ADMIN SERVER.LUA - Commandes Admin (côté serveur)
-- ==============================================

-- /goto [id] : Te téléporte vers un joueur
RegisterCommand('goto', function(source, args)
    local adminId = source

    -- Vérifie que l'admin a donné un ID
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Utilisation : /goto [id du joueur]'}
        })
        return
    end

    local targetId = tonumber(args[1])

    -- Vérifie que le joueur cible existe
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Joueur introuvable avec cet ID !'}
        })
        return
    end

    -- Récupère la position du joueur cible
    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)

    -- Téléporte l'admin vers le joueur
    TriggerClientEvent('pvp_admin:teleport', adminId, targetCoords.x, targetCoords.y, targetCoords.z)

    -- Messages de confirmation
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 255, 0},
        args = {'[ADMIN]', 'Téléporté vers ' .. targetName .. ' (ID: ' .. targetId .. ')'}
    })
end, true) -- true = commande réservée aux admins (ace permission)


-- /bring [id] : Téléporte un joueur vers toi
RegisterCommand('bring', function(source, args)
    local adminId = source

    -- Vérifie que l'admin a donné un ID
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Utilisation : /bring [id du joueur]'}
        })
        return
    end

    local targetId = tonumber(args[1])

    -- Vérifie que le joueur cible existe
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Joueur introuvable avec cet ID !'}
        })
        return
    end

    -- Récupère la position de l'admin
    local adminPed = GetPlayerPed(adminId)
    local adminCoords = GetEntityCoords(adminPed)

    -- Téléporte le joueur vers l'admin
    TriggerClientEvent('pvp_admin:teleport', targetId, adminCoords.x, adminCoords.y, adminCoords.z)

    -- Messages de confirmation
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 255, 0},
        args = {'[ADMIN]', targetName .. ' (ID: ' .. targetId .. ') a été téléporté vers toi'}
    })
    TriggerClientEvent('chat:addMessage', targetId, {
        color = {255, 165, 0},
        args = {'[ADMIN]', 'Tu as été téléporté par un administrateur'}
    })
end, true) -- true = commande réservée aux admins


-- /players : Affiche la liste de tous les joueurs connectés avec leur ID
RegisterCommand('players', function(source, args)
    local adminId = source
    local players = GetPlayers()

    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 200, 255},
        args = {'[SERVEUR]', '--- Liste des joueurs connectés ---'}
    })

    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        local playerPed = GetPlayerPed(playerId)
        local health = GetEntityHealth(playerPed)

        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 255, 255},
            args = {'[ID: ' .. playerId .. ']', playerName .. ' | Vie: ' .. health}
        })
    end

    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 200, 255},
        args = {'[SERVEUR]', 'Total: ' .. #players .. ' joueur(s) en ligne'}
    })
end, true) -- true = commande réservée aux admins


-- /myid : Permet à N'IMPORTE QUEL joueur de voir son propre ID
RegisterCommand('id', function(source, args)
    local playerId = source
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {0, 200, 255},
        args = {'[SERVEUR]', 'Ton ID est : ' .. playerId}
    })
end, false) -- false = tout le monde peut utiliser cette commande
