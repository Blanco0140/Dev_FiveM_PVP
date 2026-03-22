-- ================================================
--  PVP INVENTORY - Server (FIX TRADE/DON)
-- ================================================

local pendingTrades = {}
local tradeCounter  = 0
local nameCache     = {}

local function GetName(src)
    if not nameCache[src] then
        nameCache[src] = GetPlayerName(src) or ("Joueur " .. src)
    end
    return nameCache[src]
end

AddEventHandler('playerDropped', function() nameCache[source] = nil end)

local function IsValid(id)
    return id and GetPlayerPing(id) >= 0
end

-- Retrouve le server ID depuis le player index client
-- Le client envoie le player index local (GetActivePlayers()),
-- on doit retrouver son server ID
local function GetServerIdFromClientIndex(clientIndex)
    -- GetPlayerFromIndex retourne le server ID directement sur certaines versions
    -- La méthode fiable : chercher parmi les joueurs connectés
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid then
            -- Vérifie si le net ID correspond
            local ped = GetPlayerPed(pid)
            if ped then
                return pid
            end
        end
    end
    return nil
end

-- Méthode correcte : le client envoie directement le server ID du joueur cible
-- On utilise GetPlayerServerId côté client puis on le passe au serveur

RegisterNetEvent('pvp_inv:giveWeapon', function(targetServerId, weaponHash, ammo)
    local src    = source
    local target = tonumber(targetServerId)

    if not target or not IsValid(target) or not IsValid(src) then
        print("[pvp_inv] DON: joueur cible invalide ID=" .. tostring(targetServerId))
        return
    end

    if ammo == nil or ammo < 0 then
        print("[pvp_inv] DON EXPLOIT: " .. GetName(src) .. " a tente d'envoyer " .. tostring(ammo) .. " munitions !")
        return
    end

    ammo = math.min(ammo, 9999)
    TriggerClientEvent('pvp_inv:removeWeapon',  src,    weaponHash)
    TriggerClientEvent('pvp_inv:receiveWeapon', target, GetName(src), weaponHash, ammo)
    print("[pvp_inv] DON: " .. GetName(src) .. " → " .. GetName(target) .. " | " .. weaponHash)
end)

RegisterNetEvent('pvp_inv:requestTrade', function(targetServerId, weaponHash, ammo)
    local src    = source
    local target = tonumber(targetServerId)

    if not target or not IsValid(target) or not IsValid(src) then
        print("[pvp_inv] TRADE: joueur cible invalide ID=" .. tostring(targetServerId))
        return
    end

    if ammo == nil or ammo < 0 then
        print("[pvp_inv] TRADE EXPLOIT: " .. GetName(src) .. " a tente d'echanger " .. tostring(ammo) .. " munitions !")
        return
    end

    ammo = math.min(ammo, 9999)
    tradeCounter = tradeCounter + 1
    local tradeId = tradeCounter

    pendingTrades[tradeId] = { from = src, to = target, hash = weaponHash, ammo = ammo }

    TriggerClientEvent('pvp_inv:tradeRequest', target, tradeId, GetName(src), src, weaponHash, ammo)
    print("[pvp_inv] TRADE REQUEST: " .. GetName(src) .. " → " .. GetName(target) .. " TradeID=" .. tradeId)

    SetTimeout(30000, function()
        if pendingTrades[tradeId] then
            pendingTrades[tradeId] = nil
            if IsValid(src) then TriggerClientEvent('pvp_inv:tradeDeclined', src) end
        end
    end)
end)

RegisterNetEvent('pvp_inv:acceptTrade', function(tradeId)
    local src   = source
    local trade = pendingTrades[tradeId]
    if not trade or trade.to ~= src then return end
    if not IsValid(trade.from) then pendingTrades[tradeId] = nil return end

    TriggerClientEvent('pvp_inv:removeWeapon',  trade.from, trade.hash)
    TriggerClientEvent('pvp_inv:tradeAccepted', src, tradeId, trade.hash, trade.ammo)
    pendingTrades[tradeId] = nil
    print("[pvp_inv] TRADE ACCEPTED: TradeID=" .. tradeId)
end)

RegisterNetEvent('pvp_inv:declineTrade', function(tradeId)
    local src   = source
    local trade = pendingTrades[tradeId]
    if not trade or trade.to ~= src then return end
    if IsValid(trade.from) then TriggerClientEvent('pvp_inv:tradeDeclined', trade.from) end
    pendingTrades[tradeId] = nil
end)

RegisterNetEvent('pvp_inv:dropWeapon', function(_) end)

RegisterNetEvent('pvp_inv:requestPoints', function()
    local src = source
    local pts = exports.pvp_core:GetPlayerPoints(src)
    TriggerClientEvent('pvp_inv:receivePoints', src, pts)
end)
