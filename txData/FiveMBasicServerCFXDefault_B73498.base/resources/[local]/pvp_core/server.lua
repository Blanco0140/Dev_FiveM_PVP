-- ==============================================
-- PVP CORE - server.lua
-- Gestion des joueurs, kills, morts, stats
-- ==============================================

-- Configuration du webhook
local webhookUrl = "https://discord.com/api/webhooks/1485080990572609556/iBi0Ivv1repYwCZdbDIIyX75IKHnFPMlDa6YJIF4isiRqt6dk5oAy47vFZeTmMMoVMYI"

Citizen.CreateThread(function()
    Wait(1500)
    MySQL.query('SHOW COLUMNS FROM `users` LIKE "points"', {}, function(result)
        if not result or #result == 0 then
            MySQL.query('ALTER TABLE `users` ADD COLUMN `points` INT(11) NOT NULL DEFAULT 0')
            print('^2[PVP CORE] Colonne "points" ajoutee a la table users.^7')
        end
    end)
    MySQL.query('SHOW COLUMNS FROM `users` LIKE "inventory"', {}, function(result)
        if not result or #result == 0 then
            MySQL.query('ALTER TABLE `users` ADD COLUMN `inventory` LONGTEXT NOT NULL DEFAULT "[]"')
            print('^2[PVP CORE] Colonne "inventory" ajoutee a la table users.^7')
        end
    end)
end)

function SendDiscordLog(name, isNew, ids)
    local color = isNew and 3066993 or 3447003 -- Vert si nouveau, Bleu si connu
    local status = isNew and "s'est connecté (Nouveau joueur)" or "s'est connecté"
    
    local discordText = ids.discord and ("<@" .. string.gsub(ids.discord, "discord:", "") .. ">\n(" .. ids.discord .. ")") or "Non lié"

    local embed = {
        {
            ["title"] = "🔗 Connexion : " .. name,
            ["description"] = "**" .. name .. "** " .. status,
            ["color"] = color,
            ["fields"] = {
                { ["name"] = "🎮 License Rockstar", ["value"] = ids.license or "Introuvable", ["inline"] = true },
                { ["name"] = "💬 Discord", ["value"] = discordText, ["inline"] = true },
                { ["name"] = "🚂 Steam", ["value"] = ids.steam or "Non lié", ["inline"] = true },
                { ["name"] = "🌐 Adresse IP", ["value"] = "||" .. (ids.ip or "Introuvable") .. "||", ["inline"] = true }
            },
            ["footer"] = { ["text"] = "Ashfall PVP Logs" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({username = "Système de Connexion", avatar_url = "https://i.imgur.com/xVzJ8A9.png", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

local WhitelistedDiscords = {
    ["discord:763789542816874548"] = true,
    ["discord:898276549097291826"] = true,
    ["discord:333584346399244290"] = true,
}

-- Quand un joueur se connecte, on le crée en BDD s'il n'existe pas
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local player = source
    deferrals.defer()
    Wait(0)
    deferrals.update("Vérification de la whitelist Discord en cours...")

    local ids = {
        license = nil,
        discord = nil,
        steam = nil,
        ip = GetPlayerEndpoint(player)
    }

    for _, v in ipairs(GetPlayerIdentifiers(player)) do
        if string.match(v, 'license:') then ids.license = v
        elseif string.match(v, 'discord:') then ids.discord = v
        elseif string.match(v, 'steam:') then ids.steam = v
        elseif string.match(v, 'ip:') then ids.ip = string.gsub(v, 'ip:', '') end
    end

    if not ids.discord then
        return deferrals.done("\n[ASHFALL PVP]\nVous devez avoir Discord ouvert et lié à FiveM pour vous connecter.")
    end

    if not WhitelistedDiscords[ids.discord] then
        return deferrals.done("\n[ASHFALL PVP]\nVous n'êtes pas sur la liste blanche.\nVotre Discord ID: " .. string.gsub(ids.discord, "discord:", ""))
    end

    if ids.license then
        local exist = MySQL.query.await('SELECT identifier FROM users WHERE identifier = ?', {ids.license})

        if not exist[1] then
            MySQL.insert.await('INSERT INTO users (identifier, name, kills, deaths, points, inventory) VALUES (?, ?, 0, 0, 0, "[]")', {ids.license, name})
            print('^2[PVP] Nouveau joueur : ' .. name .. ' | Sa licence est -> ^3' .. ids.license .. '^7')
            SendDiscordLog(name, true, ids)
        else
            -- Met à jour le nom au cas où il a changé
            MySQL.update.await('UPDATE users SET name = ? WHERE identifier = ?', {name, ids.license})
            print('^4[PVP] Joueur connu : ' .. name .. ' | Sa licence est -> ^3' .. ids.license .. '^7')
            SendDiscordLog(name, false, ids)
        end
        deferrals.done()
    else
        print('^1[PVP] Erreur : Impossible de trouver la licence du joueur ' .. name .. '^7')
        deferrals.done("\n[ASHFALL PVP]\nErreur : Impossible de trouver votre licence Rockstar.")
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

-- ==============================================
-- EXPORTS DE POINTS (MONNAIE)
-- ==============================================

function GetPlayerLicense(source)
    for _, v in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(v, 'license:') then
            return v
        end
    end
    return nil
end

exports('GetPlayerPoints', function(source)
    local identifier = GetPlayerLicense(source)
    if identifier then
        local result = MySQL.query.await('SELECT points FROM users WHERE identifier = ?', {identifier})
        if result and result[1] then
            return result[1].points or 0
        end
    end
    return 0
end)

exports('AddPlayerPoints', function(source, amount)
    local identifier = GetPlayerLicense(source)
    local amt = tonumber(amount)
    if identifier and amt and amt > 0 then
        MySQL.update.await('UPDATE users SET points = points + ? WHERE identifier = ?', {amt, identifier})
    end
end)

exports('RemovePlayerPoints', function(source, amount)
    local identifier = GetPlayerLicense(source)
    local amt = tonumber(amount)
    if identifier and amt and amt > 0 then
        MySQL.update.await('UPDATE users SET points = GREATEST(0, points - ?) WHERE identifier = ?', {amt, identifier})
    end
end)
