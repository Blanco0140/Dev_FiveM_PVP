local PlayerInventories = {}
local pendingTrades = {}
local tradeCounter  = 0
local nameCache     = {}

local function GetName(src)
    if not nameCache[src] then nameCache[src] = GetPlayerName(src) or ("Joueur " .. src) end
    return nameCache[src]
end

local function GetLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

local function GenerateUUID()
    return "wep_" .. os.time() .. "_" .. math.random(1000, 9999)
end

AddEventHandler('playerDropped', function()
    local src = source
    if PlayerInventories[src] then
        local identifier = GetLicense(src)
        if identifier then
            MySQL.update('UPDATE users SET inventory = ? WHERE identifier = ?', {json.encode(PlayerInventories[src]), identifier})
        end
        PlayerInventories[src] = nil
    end
    nameCache[src] = nil
end)

local function LoadInventory(src)
    local identifier = GetLicense(src)
    if not identifier then return false end
    
    local result = MySQL.query.await('SELECT inventory FROM users WHERE identifier = ?', {identifier})
    if result and result[1] and result[1].inventory then
        PlayerInventories[src] = json.decode(result[1].inventory) or {}
    else
        PlayerInventories[src] = {}
        -- Insérer dans la BDD au cas où la ligne n'est pas encore finie (sécurité)
        MySQL.update.await('UPDATE users SET inventory = ? WHERE identifier = ?', {"[]", identifier})
    end
    TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
    return true
end

local function SaveInventory(src)
    if not PlayerInventories[src] then return end
    local identifier = GetLicense(src)
    if not identifier then return end
    MySQL.update('UPDATE users SET inventory = ? WHERE identifier = ?', {json.encode(PlayerInventories[src]), identifier})
end

RegisterNetEvent('pvp_inv:requestData', function()
    LoadInventory(source)
end)

-- Sauvegarde periodique de toutes les 2 minutes pour la securite
CreateThread(function()
    while true do
        Wait(120000)
        for src, _ in pairs(PlayerInventories) do
            SaveInventory(src)
        end
    end
end)

-- EXPORTS POUR LES AUTRES SCRIPTS
exports('AddItem', function(src, hash, name, ammo)
    if not PlayerInventories[src] then
        print("^3[PVP INV] Inventaire non charge pour " .. src .. ". Chargement force.^7")
        if not LoadInventory(src) then return false end
    end
    local u = GenerateUUID()
    table.insert(PlayerInventories[src], {
        uuid = u,
        hash = hash,
        name = name,
        ammo = tonumber(ammo) or 250
    })
    SaveInventory(src)
    TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
    return u
end)

exports('RemoveItem', function(src, uuid)
    if not PlayerInventories[src] then
        if not LoadInventory(src) then return false end
    end
    for i, item in ipairs(PlayerInventories[src]) do
        if item.uuid == uuid then
            table.remove(PlayerInventories[src], i)
            SaveInventory(src)
            TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
            return true
        end
    end
    return false
end)

exports('GetInventory', function(src)
    if not PlayerInventories[src] then LoadInventory(src) end
    return PlayerInventories[src] or {}
end)

exports('ClearInventory', function(src)
    if not PlayerInventories[src] then LoadInventory(src) end
    PlayerInventories[src] = {}
    SaveInventory(src)
    TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
end)


-- LOGIQUE INTERNE (EQUIPER / DROP / DON / TRADE)
RegisterNetEvent('pvp_inv:updateItemAmmo', function(uuid, ammo)
    local src = source
    if not PlayerInventories[src] then return end
    for _, item in ipairs(PlayerInventories[src]) do
        if item.uuid == uuid then
            item.ammo = tonumber(ammo) or 0
            break
        end
    end
end)

RegisterNetEvent('pvp_inv:equipItem', function(uuid)
    local src = source
    if not PlayerInventories[src] then return end
    for _, item in ipairs(PlayerInventories[src]) do
        if item.uuid == uuid then
            TriggerClientEvent('pvp_inv:doEquip', src, item.uuid, item.hash, item.ammo)
            return
        end
    end
end)

RegisterNetEvent('pvp_inv:dropItem', function(uuid)
    local src = source
    exports.pvp_inv:RemoveItem(src, uuid)
end)

RegisterNetEvent('pvp_inv:requestPoints', function()
    local src = source
    local pts = exports.pvp_core:GetPlayerPoints(src)
    TriggerClientEvent('pvp_inv:receivePoints', src, pts)
end)

-- TRADE & GIVE
RegisterNetEvent('pvp_inv:giveItem', function(targetServerId, uuid)
    local src = source
    local target = tonumber(targetServerId)
    if not target or target == src then return end
    
    local foundIdx, foundItem = nil, nil
    for i, it in ipairs(PlayerInventories[src]) do
        if it.uuid == uuid then foundIdx = i; foundItem = it; break; end
    end
    
    if not foundItem then return end
    
    table.remove(PlayerInventories[src], foundIdx)
    table.insert(PlayerInventories[target], foundItem)
    SaveInventory(src)
    SaveInventory(target)
    
    TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
    TriggerClientEvent('pvp_inv:updateInventory', target, PlayerInventories[target])
    TriggerClientEvent('pvp_inv:notifyTrade', target, GetName(src) .. " vous a donne " .. foundItem.name, 'success')
    TriggerClientEvent('pvp_inv:notifyTrade', src, "Vous avez donne " .. foundItem.name, 'success')
end)

RegisterNetEvent('pvp_inv:requestTrade', function(targetServerId, uuid)
    local src = source
    local target = tonumber(targetServerId)
    if not target then return end
    
    local foundItem = nil
    for _, it in ipairs(PlayerInventories[src] or {}) do
        if it.uuid == uuid then foundItem = it; break; end
    end
    if not foundItem then return end
    
    tradeCounter = tradeCounter + 1
    local tradeId = tradeCounter
    pendingTrades[tradeId] = { from = src, to = target, item = foundItem }
    
    TriggerClientEvent('pvp_inv:tradeRequest', target, tradeId, GetName(src), src, foundItem.name, foundItem.ammo)
    
    SetTimeout(30000, function()
        if pendingTrades[tradeId] then
            pendingTrades[tradeId] = nil
            TriggerClientEvent('pvp_inv:notifyTrade', src, "Echange expire.", 'error')
        end
    end)
end)

RegisterNetEvent('pvp_inv:acceptTrade', function(tradeId)
    local src = source
    local trade = pendingTrades[tradeId]
    if not trade or trade.to ~= src then return end
    
    -- Verifier que item est toujours la
    local foundIdx = nil
    for i, it in ipairs(PlayerInventories[trade.from] or {}) do
        if it.uuid == trade.item.uuid then foundIdx = i; break; end
    end
    
    if foundIdx then
        table.remove(PlayerInventories[trade.from], foundIdx)
        table.insert(PlayerInventories[src], trade.item)
        SaveInventory(trade.from)
        SaveInventory(src)
        TriggerClientEvent('pvp_inv:updateInventory', trade.from, PlayerInventories[trade.from])
        TriggerClientEvent('pvp_inv:updateInventory', src, PlayerInventories[src])
        TriggerClientEvent('pvp_inv:notifyTrade', src, "Echange reussi !", 'success')
        TriggerClientEvent('pvp_inv:notifyTrade', trade.from, "Echange reussi !", 'success')
    end
    pendingTrades[tradeId] = nil
end)

RegisterNetEvent('pvp_inv:declineTrade', function(tradeId)
    local src = source
    local trade = pendingTrades[tradeId]
    if trade and trade.from then
        TriggerClientEvent('pvp_inv:notifyTrade', trade.from, "L'echange a ete refuse.", 'error')
    end
    pendingTrades[tradeId] = nil
end)
