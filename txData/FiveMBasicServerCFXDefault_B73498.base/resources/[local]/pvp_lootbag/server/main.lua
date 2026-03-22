-- ============================================
--        LOOTBAG SYSTEM - SERVER SIDE
-- ============================================

local activeBags = {} -- { bagId = { weapons = {}, coords = {}, ownerId = source, timerId } }
local bagCounter = 0

-- ============================================
-- Utilitaires
-- ============================================

local function generateBagId()
    bagCounter = bagCounter + 1
    return bagCounter
end

-- ============================================
-- Event : Un joueur meurt → créer le sac
-- ============================================

RegisterNetEvent('lootbag:playerDied')
AddEventHandler('lootbag:playerDied', function(coords)
    local playerId = source

    local inv = exports.pvp_inv:GetInventory(playerId)
    if not inv or #inv == 0 then
        print('[LootBag] ' .. playerId .. ' est mort sans armes, pas de sac.')
        return
    end

    local bagId = generateBagId()

    activeBags[bagId] = {
        weapons  = inv,
        coords   = coords,
        ownerId  = playerId,
        alive    = true
    }

    -- Le serveur vide l'inventaire du joueur mort !
    exports.pvp_inv:ClearInventory(playerId)

    TriggerClientEvent('lootbag:spawnBag', -1, bagId, coords, inv)

    print('[LootBag] Sac #' .. bagId .. ' cree pour ' .. playerId)

    -- Timer : supprimer le sac après Config.BagLifetime secondes
    SetTimeout(Config.BagLifetime * 1000, function()
        if activeBags[bagId] and activeBags[bagId].alive then
            activeBags[bagId].alive = false
            activeBags[bagId] = nil
            TriggerClientEvent('lootbag:removeBag', -1, bagId)
            print('[LootBag] Sac #' .. bagId .. ' expiré et supprimé.')
        end
    end)
end)

-- ============================================
-- Event : Un joueur veut looter le sac
-- ============================================

RegisterNetEvent('lootbag:lootBag')
AddEventHandler('lootbag:lootBag', function(bagId)
    local playerId = source -- capture immédiate

    if not activeBags[bagId] then
        TriggerClientEvent('lootbag:lootResult', playerId, false, bagId, nil, 'Sac introuvable ou déjà looté.')
        return
    end

    if not activeBags[bagId].alive then
        TriggerClientEvent('lootbag:lootResult', playerId, false, bagId, nil, 'Ce sac a expiré.')
        return
    end

    local weapons = activeBags[bagId].weapons

    -- Marquer le sac comme looté et le supprimer
    activeBags[bagId].alive = false
    activeBags[bagId] = nil

    -- Donner les armes au joueur qui loote (UUID Virtuels via pvp_inv)
    local count = 0
    for _, w in ipairs(weapons) do
        exports.pvp_inv:AddItem(playerId, w.hash, w.name, w.ammo)
        count = count + 1
    end

    TriggerClientEvent('lootbag:lootResult', playerId, true, bagId, count, nil)

    -- Supprimer le sac visuellement pour tous
    TriggerClientEvent('lootbag:removeBag', -1, bagId)

    print('[LootBag] Sac #' .. bagId .. ' loote par ' .. playerId)
end)

-- ============================================
-- Command Admin : voir les sacs actifs
-- ============================================

RegisterCommand('listbags', function(source, args, rawCommand)
    local count = 0
    for id, bag in pairs(activeBags) do
        count = count + 1
        print('[LootBag] Sac #' .. id .. ' | Armes: ' .. #bag.weapons .. ' | Owner: ' .. bag.ownerId)
    end
    print('[LootBag] Total sacs actifs: ' .. count)
end, true)
