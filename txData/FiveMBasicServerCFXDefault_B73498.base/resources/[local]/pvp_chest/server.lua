-- ============================================================
--  PVP CHEST — Serveur (VERSION UUID)
-- ============================================================

local cache = {}

local function GetLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

local function LoadChest(identifier, cb)
    if cache[identifier] then
        cb(cache[identifier])
        return
    end

    MySQL.query('SELECT chest FROM pvp_chests WHERE identifier = ?', { identifier }, function(rows)
        if rows and #rows > 0 then
            local decoded = json.decode(rows[1].chest) or {}
            -- Migration of old Hash-based dict to UUID-based array
            local isDict = false
            for k, v in pairs(decoded) do
                if type(k) == "string" and not tonumber(k) then isDict = true break end
                if type(k) == "number" and v.hash and not v.uuid then isDict = true break end
            end
            
            if isDict then
                print("[PVP CHEST] Migration d'un ancien coffre vers le format tableau UUID")
                local newArr = {}
                for k, v in pairs(decoded) do
                    table.insert(newArr, {
                        uuid = "chest_" .. os.time() .. "_" .. math.random(1000, 9999), 
                        hash = v.hash or k, 
                        name = v.name or "Arme", 
                        ammo = tonumber(v.ammo) or 0
                    })
                end
                cache[identifier] = newArr
                MySQL.update('UPDATE pvp_chests SET chest = ? WHERE identifier = ?', { json.encode(newArr), identifier })
            else
                cache[identifier] = decoded
            end
        else
            MySQL.insert('INSERT INTO pvp_chests (identifier, chest) VALUES (?, ?)', { identifier, '[]' })
            cache[identifier] = {}
        end
        cb(cache[identifier])
    end)
end

local function SaveChest(identifier)
    if not cache[identifier] then return end
    MySQL.update('UPDATE pvp_chests SET chest = ? WHERE identifier = ?', { json.encode(cache[identifier]), identifier })
end

RegisterNetEvent('pvpChest:open', function()
    local src        = source
    local identifier = GetLicense(src)
    if not identifier then return end

    LoadChest(identifier, function(chest)
        local inv = exports.pvp_inv:GetInventory(src) or {}
        TriggerClientEvent('pvpChest:update', src, inv, chest)
    end)
end)

RegisterNetEvent('pvpChest:deposit', function(uuid)
    local src        = source
    local identifier = GetLicense(src)
    if not identifier or not uuid then return end

    local inv = exports.pvp_inv:GetInventory(src) or {}
    local foundItem = nil
    for _, it in ipairs(inv) do
        if it.uuid == uuid then foundItem = it break end
    end
    if not foundItem then return end

    LoadChest(identifier, function(chest)
        if exports.pvp_inv:RemoveItem(src, uuid) then
            table.insert(chest, {
                uuid = foundItem.uuid,
                hash = foundItem.hash,
                name = foundItem.name,
                ammo = foundItem.ammo
            })
            SaveChest(identifier)
            
            local newInv = exports.pvp_inv:GetInventory(src) or {}
            TriggerClientEvent('pvpChest:update', src, newInv, chest)
        end
    end)
end)

RegisterNetEvent('pvpChest:withdraw', function(uuid)
    local src        = source
    local identifier = GetLicense(src)
    if not identifier or not uuid then return end

    LoadChest(identifier, function(chest)
        local foundIdx, foundItem = nil, nil
        for i, item in ipairs(chest) do
            if item.uuid == uuid then foundIdx = i; foundItem = item; break end
        end
        if not foundIdx then return end

        table.remove(chest, foundIdx)
        SaveChest(identifier)
        
        exports.pvp_inv:AddItem(src, foundItem.hash, foundItem.name, foundItem.ammo)
        local newInv = exports.pvp_inv:GetInventory(src) or {}
        TriggerClientEvent('pvpChest:update', src, newInv, chest)
    end)
end)

AddEventHandler('playerDropped', function()
    local identifier = GetLicense(source)
    if identifier then cache[identifier] = nil end
end)
