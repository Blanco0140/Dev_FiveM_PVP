local markets = {}

local dataFile = "markets.json"

local function LoadMarkets()
    local data = LoadResourceFile(GetCurrentResourceName(), dataFile)
    if data then
        local decoded = json.decode(data)
        if decoded then markets = decoded end
    end
end

local function SaveMarkets()
    SaveResourceFile(GetCurrentResourceName(), dataFile, json.encode(markets), -1)
    TriggerClientEvent('pvp_market:updateMarkets', -1, markets)
end

CreateThread(function()
    LoadMarkets()
end)

RegisterNetEvent('pvp_market:requestMarkets', function()
    TriggerClientEvent('pvp_market:updateMarkets', source, markets)
end)

-- COMMANDES ADMIN
RegisterCommand(Config.AdminCommandAdd, function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, "command") then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Système', 'Pas la permission.' } })
        return
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    table.insert(markets, {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading
    })

    SaveMarkets()
    TriggerClientEvent('chat:addMessage', source, { args = { '^2Succès', 'Vendeur de marché ajouté.' } })
end)

RegisterCommand(Config.AdminCommandRemove, function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, "command") then return end

    local index = tonumber(args[1])
    if index and markets[index] then
        table.remove(markets, index)
        SaveMarkets()
        TriggerClientEvent('chat:addMessage', source, { args = { '^2Succès', 'Marché '..index..' supprimé.' } })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Erreur', 'ID invalide. Utilisez /marketlist pour voir les IDs.' } })
    end
end)

RegisterCommand('marketlist', function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, "command") then return end
    for i, m in ipairs(markets) do
        TriggerClientEvent('chat:addMessage', source, { args = { '^3['..i..']', string.format('Marché aux coords : %.2f, %.2f, %.2f', m.x, m.y, m.z) } })
    end
end)

-- ACHAT
RegisterNetEvent('pvp_market:buyWeapon', function(weaponHash)
    local src = source
    local wHash = tonumber(weaponHash)

    -- Chercher le prix
    local price = nil
    local wName = "Arme"
    for _, w in ipairs(Config.WeaponsBuy) do
        if GetHashKey(w.hash) == wHash then
            price = w.price
            wName = w.name
            break
        end
    end

    if not price then return end

    local currentPoints = exports.pvp_core:GetPlayerPoints(src)
    if currentPoints >= price then
        exports.pvp_core:RemovePlayerPoints(src, price)
        -- On utilise l'event de pvp_inv pour que l'arme soit notifiée et reçue proprement
        TriggerClientEvent('pvp_inv:receiveWeapon', src, "Le Marché", wHash, 250)
        
        TriggerClientEvent('pvp_market:notify', src, 'success', 'Vous avez acheté : ' .. wName .. ' pour '..price..' points.')
        TriggerClientEvent('pvp_market:updatePoints', src, currentPoints - price)
    else
        TriggerClientEvent('pvp_market:notify', src, 'error', "Vous n'avez pas assez de points.")
    end
end)

-- VENTE
RegisterNetEvent('pvp_market:sellWeapon', function(weaponHash)
    local src = source
    local wHash = tonumber(weaponHash)

    -- Vérification Serveur : le joueur a-t-il vraiment l'arme ?
    -- (Sur OneSync, GetWeaponDamageType permet de le deviner rudimentairement ou juste RemoveWeapon)
    -- On fait confiance au client dans un premier temps pour retirer puis on ajoute
    
    local ped = GetPlayerPed(src)
    
    local value = Config.WeaponsSellValues[wHash] or Config.DefaultSellValue
    
    RemoveWeaponFromPed(ped, wHash)
    -- Pour forcer l'inventaire pvp_inv à se vider on lui envoie son propre event
    TriggerClientEvent('pvp_inv:removeWeapon', src, wHash)
    
    exports.pvp_core:AddPlayerPoints(src, value)
    
    local currentPoints = exports.pvp_core:GetPlayerPoints(src)
    TriggerClientEvent('pvp_market:notify', src, 'success', 'Vous avez vendu une arme pour '..value..' points.')
    TriggerClientEvent('pvp_market:updatePoints', src, currentPoints)
end)
