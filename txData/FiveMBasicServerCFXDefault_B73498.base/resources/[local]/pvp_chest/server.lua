-- ============================================================
--  PVP CHEST — Serveur
-- ============================================================

-- Cache mémoire : évite une requête DB à chaque action
-- { [identifier] = { chest = {}, dirty = false } }
local cache = {}

local function GetLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

-- ─── Charge depuis le cache ou la DB ─────────────────────────
local function LoadChest(identifier, cb)
    if cache[identifier] then
        cb(cache[identifier])
        return
    end

    MySQL.query('SELECT chest FROM pvp_chests WHERE identifier = ?',
        { identifier },
        function(rows)
            if rows and #rows > 0 then
                cache[identifier] = json.decode(rows[1].chest) or {}
            else
                MySQL.insert('INSERT INTO pvp_chests (identifier, chest) VALUES (?, ?)',
                    { identifier, '{}' })
                cache[identifier] = {}
            end
            cb(cache[identifier])
        end
    )
end

-- ─── Sauvegarde en DB ─────────────────────────────────────────
local function SaveChest(identifier)
    if not cache[identifier] then return end
    MySQL.update('UPDATE pvp_chests SET chest = ? WHERE identifier = ?',
        { json.encode(cache[identifier]), identifier })
end

-- ─── Ouverture ───────────────────────────────────────────────
RegisterNetEvent('pvpChest:open', function(inventory)
    local src        = source
    local identifier = GetLicense(src)
    if not identifier then return end

    LoadChest(identifier, function(chest)
        TriggerClientEvent('pvpChest:update', src, inventory, chest)
    end)
end)

-- ─── Déposer ─────────────────────────────────────────────────
RegisterNetEvent('pvpChest:deposit', function(hashStr, ammo, name, cat)
    local src        = source
    local identifier = GetLicense(src)
    if not identifier or not hashStr then return end

    LoadChest(identifier, function(chest)
        local existing = chest[hashStr]
        chest[hashStr] = {
            hash = hashStr,
            ammo = (existing and existing.ammo or 0) + (tonumber(ammo) or 0),
            name = name or (existing and existing.name) or 'Arme',
            cat  = cat  or (existing and existing.cat)  or '',
        }
        SaveChest(identifier)
        TriggerClientEvent('pvpChest:update', src, nil, chest)
    end)
end)

-- ─── Retirer ─────────────────────────────────────────────────
RegisterNetEvent('pvpChest:withdraw', function(hashStr)
    local src        = source
    local identifier = GetLicense(src)
    if not identifier or not hashStr then return end

    LoadChest(identifier, function(chest)
        local slot = chest[hashStr]
        if not slot then return end

        chest[hashStr] = nil
        SaveChest(identifier)
        TriggerClientEvent('pvpChest:giveWeapon', src, hashStr, slot.ammo)
    end)
end)

-- ─── Nettoyage déconnexion ───────────────────────────────────
AddEventHandler('playerDropped', function()
    local identifier = GetLicense(source)
    if identifier then cache[identifier] = nil end
end)
