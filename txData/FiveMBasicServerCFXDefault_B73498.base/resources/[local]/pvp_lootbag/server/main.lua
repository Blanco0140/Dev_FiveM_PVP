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
AddEventHandler('lootbag:playerDied', function(weapons, coords)
    local playerId = source -- capture immédiate avant tout yield

    if not weapons or #weapons == 0 then
        print('[LootBag] ' .. playerId .. ' est mort sans armes, pas de sac créé.')
        return
    end

    local bagId = generateBagId()

    activeBags[bagId] = {
        weapons  = weapons,
        coords   = coords,
        ownerId  = playerId,
        alive    = true
    }

    -- Notifier tous les clients de la création du sac
    TriggerClientEvent('lootbag:spawnBag', -1, bagId, coords, weapons)

    print('[LootBag] Sac #' .. bagId .. ' créé aux coords ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)

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

    -- Donner les armes au joueur qui loote
    TriggerClientEvent('lootbag:lootResult', playerId, true, bagId, weapons, nil)

    -- Supprimer le sac visuellement pour tous
    TriggerClientEvent('lootbag:removeBag', -1, bagId)

    print('[LootBag] Sac #' .. bagId .. ' looté par le joueur ' .. playerId)
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
