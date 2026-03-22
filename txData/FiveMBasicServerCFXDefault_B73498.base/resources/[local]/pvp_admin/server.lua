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


-- ==============================================
-- RÉANIMATION
-- ==============================================

-- /revive [id] : Réanime un joueur mort (le remet en vie)
RegisterCommand('revive', function(source, args)
    local adminId = source

    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Utilisation : /revive [id du joueur]'}
        })
        return
    end

    local targetId = tonumber(args[1])

    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Joueur introuvable avec cet ID !'}
        })
        return
    end

    -- Envoie l'ordre de réanimation au joueur ciblé
    TriggerClientEvent('pvp_admin:revive', targetId)

    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 255, 0},
        args = {'[ADMIN]', targetName .. ' (ID: ' .. targetId .. ') a été réanimé !'}
    })
    TriggerClientEvent('chat:addMessage', targetId, {
        color = {0, 255, 0},
        args = {'[ADMIN]', 'Tu as été réanimé par un administrateur'}
    })
end, true)


-- /heal [id] : Remet la vie au maximum d'un joueur (même s'il n'est pas mort)
RegisterCommand('heal', function(source, args)
    local adminId = source

    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Utilisation : /heal [id du joueur]'}
        })
        return
    end

    local targetId = tonumber(args[1])

    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {255, 0, 0},
            args = {'[ADMIN]', 'Joueur introuvable avec cet ID !'}
        })
        return
    end

    TriggerClientEvent('pvp_admin:heal', targetId)

    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {0, 255, 0},
        args = {'[ADMIN]', targetName .. ' (ID: ' .. targetId .. ') a été soigné !'}
    })
end, true)


-- ==============================================
-- KILL / KICK / BAN / FREEZE
-- ==============================================

-- /kill [id] : Tue un joueur instantanément
RegisterCommand('kill', function(source, args)
    local adminId = source
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Utilisation : /kill [id]'} })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Joueur introuvable !'} })
        return
    end
    TriggerClientEvent('pvp_admin:kill', targetId)
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', targetName .. ' (ID: ' .. targetId .. ') a été tué'} })
end, true)

-- /kick [id] [raison] : Expulse un joueur du serveur
RegisterCommand('kick', function(source, args)
    local adminId = source
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Utilisation : /kick [id] [raison]'} })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Joueur introuvable !'} })
        return
    end
    local reason = "Expulsé par un administrateur"
    if #args > 1 then
        reason = table.concat(args, " ", 2)
    end
    local targetName = GetPlayerName(targetId)
    DropPlayer(targetId, 'Tu as ete kick.\nRaison : ' .. reason)
    TriggerClientEvent('chat:addMessage', adminId, { color = {255,165,0}, args = {'[ADMIN]', targetName .. ' a été kick. Raison : ' .. reason} })
end, true)

-- /ban [id] [raison] : Bannit un joueur
RegisterCommand('ban', function(source, args)
    local adminId = source
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Utilisation : /ban [id] [raison]'} })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Joueur introuvable !'} })
        return
    end
    local reason = "Banni par un administrateur"
    if #args > 1 then
        reason = table.concat(args, " ", 2)
    end
    local targetName = GetPlayerName(targetId)
    DropPlayer(targetId, 'Tu as ete BANNI de ce serveur.\nRaison : ' .. reason)
    TriggerClientEvent('chat:addMessage', adminId, { color = {180,0,0}, args = {'[ADMIN]', targetName .. ' a ete BANNI. Raison : ' .. reason} })
    print('^1[ADMIN] BAN: ' .. targetName .. ' - Raison: ' .. reason .. '^7')
end, true)

-- /freeze [id] : Gèle ou dégèle un joueur
RegisterCommand('freeze', function(source, args)
    local adminId = source
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Utilisation : /freeze [id]'} })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[ADMIN]', 'Joueur introuvable !'} })
        return
    end
    TriggerClientEvent('pvp_admin:freeze', targetId)
    local targetName = GetPlayerName(targetId)
    TriggerClientEvent('chat:addMessage', adminId, { color = {100,150,220}, args = {'[ADMIN]', targetName .. ' a ete gele/degele'} })
end, true)


-- ==============================================

-- MENU JOUEURS (F9) - Données serveur
-- ==============================================

-- Quand le client demande la liste des joueurs
RegisterNetEvent('pvp_admin:requestPlayers')
AddEventHandler('pvp_admin:requestPlayers', function()
    local adminId = source
    local players = GetPlayers()
    local playerList = {}

    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        local playerPed = GetPlayerPed(playerId)
        local health = GetEntityHealth(playerPed)
        local maxHealth = 200
        local ping = GetPlayerPing(playerId)

        table.insert(playerList, {
            id = tonumber(playerId),
            name = playerName,
            health = health,
            maxHealth = maxHealth,
            ping = ping
        })
    end

    -- Renvoie la liste au client qui l'a demandée
    TriggerClientEvent('pvp_admin:receivePlayers', adminId, playerList)
end)


-- ==============================================
-- VEHICULES ET ARMES (Admin)
-- ==============================================

-- /car [modele] : Fait spawn un véhicule (côté client)
RegisterCommand('car', function(source, args)
    local adminId = source
    local modelName = args[1] or 'adder'
    TriggerClientEvent('pvp_admin:spawnCar', adminId, modelName)
end, true)

-- /giveweapon [nom_arme] [munitions] : Se donner une arme (côté client)
RegisterCommand('giveweapon', function(source, args)
    local adminId = source
    local weaponName = args[1]
    local ammo = tonumber(args[2]) or 250

    if not weaponName then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255, 0, 0}, args = {'[ADMIN]', 'Utilisation : /giveweapon [nom_arme] [munitions]'} })
        return
    end
    
    TriggerClientEvent('pvp_admin:giveWeapon', adminId, weaponName, ammo)
end, true)
