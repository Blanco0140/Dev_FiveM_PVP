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
        
        -- Ajout à l'inventaire virtuel
        exports.pvp_inv:AddItem(src, wHash, wName, 250)
        
        TriggerClientEvent('pvp_market:notify', src, 'success', 'Vous avez achete : ' .. wName .. ' pour '..price..' points.')
        
        -- Renvoyer nouveau statut
        local newPts = exports.pvp_core:GetPlayerPoints(src)
        local inv = exports.pvp_inv:GetInventory(src) or {}
        local myWeapons = {}
        for _, item in ipairs(inv) do
            local val = Config.WeaponsSellValues[item.hash] or Config.DefaultSellValue
            table.insert(myWeapons, { uuid = item.uuid, hash = item.hash, name = item.name, value = val })
        end
        TriggerClientEvent('pvp_market:updateData', src, newPts, myWeapons)
    else
        TriggerClientEvent('pvp_market:notify', src, 'error', "Vous n'avez pas assez de points.")
    end
end)

-- VENTE
RegisterNetEvent('pvp_market:sellWeapon', function(uuid)
    local src = source
    local inv = exports.pvp_inv:GetInventory(src) or {}
    local foundHash = nil
    for _, it in ipairs(inv) do
        if it.uuid == uuid then foundHash = it.hash; break; end
    end
    
    if not foundHash then return end
    
    local value = Config.WeaponsSellValues[foundHash] or Config.DefaultSellValue
    
    if exports.pvp_inv:RemoveItem(src, uuid) then
        exports.pvp_core:AddPlayerPoints(src, value)
        TriggerClientEvent('pvp_market:notify', src, 'success', 'Vous avez vendu une arme pour '..value..' points.')
        
        local newPts = exports.pvp_core:GetPlayerPoints(src)
        local newInv = exports.pvp_inv:GetInventory(src) or {}
        local myWeapons = {}
        for _, item in ipairs(newInv) do
            local val = Config.WeaponsSellValues[item.hash] or Config.DefaultSellValue
            table.insert(myWeapons, { uuid = item.uuid, hash = item.hash, name = item.name, value = val })
        end
        TriggerClientEvent('pvp_market:updateData', src, newPts, myWeapons)
    end
end)

-- NOUVEL EVENT: Charger points + inv pour UI
RegisterNetEvent('pvp_market:requestData', function()
    local src = source
    local pts = exports.pvp_core:GetPlayerPoints(src)
    local inv = exports.pvp_inv:GetInventory(src) or {}
    
    local myWeapons = {}
    for _, item in ipairs(inv) do
        local val = Config.WeaponsSellValues[item.hash] or Config.DefaultSellValue
        table.insert(myWeapons, { uuid = item.uuid, hash = item.hash, name = item.name, value = val })
    end
    TriggerClientEvent('pvp_market:openMarketData', src, pts, myWeapons)
end)
