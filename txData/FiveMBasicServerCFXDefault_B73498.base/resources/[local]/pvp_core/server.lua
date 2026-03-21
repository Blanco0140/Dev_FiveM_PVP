-- ==============================================
-- PVP CORE - server.lua
-- Gestion des joueurs, kills, morts, stats
-- ==============================================

-- Quand un joueur se connecte, on le crée en BDD s'il n'existe pas
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local player = source
    local identifier = nil

    for k, v in ipairs(GetPlayerIdentifiers(player)) do
        if string.match(v, 'license:') then
            identifier = v
            break
        end
    end

    if identifier then
        local exist = MySQL.query.await('SELECT identifier FROM users WHERE identifier = ?', {identifier})

        if not exist[1] then
            MySQL.insert.await('INSERT INTO users (identifier, name, kills, deaths) VALUES (?, ?, 0, 0)', {identifier, name})
            print('^2[PVP] Nouveau joueur : ' .. name .. ' | Sa licence est -> ^3' .. identifier .. '^7')
        else
            -- Met à jour le nom au cas où il a changé
            MySQL.update.await('UPDATE users SET name = ? WHERE identifier = ?', {name, identifier})
            print('^4[PVP] Joueur connu : ' .. name .. ' | Sa licence est -> ^3' .. identifier .. '^7')
        end
    else
        print('^1[PVP] Erreur : Impossible de trouver la licence du joueur ' .. name .. '^7')
    end
end)


-- ==============================================
-- TRACKING DES KILLS / MORTS
-- ==============================================

-- Quand un joueur meurt (envoyé par le client)
RegisterNetEvent('pvp_core:playerKilled')
AddEventHandler('pvp_core:playerKilled', function(killerId)
    local victimId = source
    local victimIdentifier = nil
    local killerIdentifier = nil

    -- Identifier de la victime
    for k, v in ipairs(GetPlayerIdentifiers(victimId)) do
        if string.match(v, 'license:') then
            victimIdentifier = v
            break
        end
    end

    -- Ajoute un mort à la victime
    if victimIdentifier then
        MySQL.update('UPDATE users SET deaths = deaths + 1 WHERE identifier = ?', {victimIdentifier})
    end

    -- Si un tueur est identifié, ajoute un kill
    if killerId and killerId > 0 then
        for k, v in ipairs(GetPlayerIdentifiers(killerId)) do
            if string.match(v, 'license:') then
                killerIdentifier = v
                break
            end
        end

        if killerIdentifier then
            MySQL.update('UPDATE users SET kills = kills + 1 WHERE identifier = ?', {killerIdentifier})
        end
    end
end)


-- ==============================================
-- LEADERBOARD - Données pour le classement
-- ==============================================

RegisterNetEvent('pvp_leaderboard:requestStats')
AddEventHandler('pvp_leaderboard:requestStats', function()
    local requesterId = source

    -- Utilise pcall pour éviter que ça crash si la BDD n'est pas prête
    local success, err = pcall(function()
        local topPlayers = MySQL.query.await('SELECT name, kills, deaths FROM users ORDER BY kills DESC LIMIT 20')

        local totalResult = MySQL.query.await('SELECT COUNT(*) as total FROM users')
        local totalPlayers = totalResult and totalResult[1] and totalResult[1].total or 0

        local totalKillsResult = MySQL.query.await('SELECT SUM(kills) as total FROM users')
        local totalKills = totalKillsResult and totalKillsResult[1] and totalKillsResult[1].total or 0

        local onlinePlayers = GetPlayers()
        local onlineCount = #onlinePlayers

        -- Stats du joueur qui demande
        local myIdentifier = nil
        for k, v in ipairs(GetPlayerIdentifiers(requesterId)) do
            if string.match(v, 'license:') then
                myIdentifier = v
                break
            end
        end
        local myStats = nil
        if myIdentifier then
            local result = MySQL.query.await('SELECT name, kills, deaths FROM users WHERE identifier = ?', {myIdentifier})
            if result and result[1] then
                myStats = result[1]
            end
        end

        -- Meilleur KD
        local topKD = 0
        if topPlayers then
            for _, p in ipairs(topPlayers) do
                local deaths = p.deaths or 0
                if deaths == 0 then deaths = 1 end
                local kd = (p.kills or 0) / deaths
                if kd > topKD then topKD = kd end
            end
        end

        TriggerClientEvent('pvp_leaderboard:receiveStats', requesterId, {
            players = topPlayers or {},
            totalPlayers = totalPlayers,
            onlineCount = onlineCount,
            totalKills = totalKills,
            topKD = math.floor(topKD * 10) / 10,
            myStats = myStats
        })
    end)

    -- Si erreur, envoie quand même des données vides pour que le menu s'affiche
    if not success then
        print('^1[LEADERBOARD] Erreur BDD: ' .. tostring(err) .. '^7')
        TriggerClientEvent('pvp_leaderboard:receiveStats', requesterId, {
            players = {},
            totalPlayers = 0,
            onlineCount = #GetPlayers(),
            totalKills = 0,
            topKD = 0,
            myStats = nil
        })
    end
end)

