-- ==============================================
-- SAFEZONE SERVER.LUA - Gestion des safezones
-- ==============================================

-- Liste des safezones (stockées en mémoire serveur)
local safezones = {}
local nextId = 1

-- /safezone add [rayon] : Crée une safezone à ta position
RegisterCommand('safezone', function(source, args)
    local adminId = source

    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[SAFEZONE]', 'Utilisation :\n/safezone add [rayon] - Créer une zone\n/safezone remove [id] - Supprimer une zone\n/safezone list - Voir toutes les zones'} })
        return
    end

    local action = string.lower(args[1])

    -- ======= ADD =======
    if action == 'add' then
        local radius = tonumber(args[2]) or 50.0

        -- Récupère la position et la direction du joueur
        local ped = GetPlayerPed(adminId)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local zone = {
            id = nextId,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = heading,
            radius = radius,
            creator = GetPlayerName(adminId)
        }

        safezones[nextId] = zone
        nextId = nextId + 1

        -- Envoie la mise à jour à tous les joueurs
        TriggerClientEvent('pvp_safezone:sync', -1, safezones)

        TriggerClientEvent('chat:addMessage', adminId, {
            color = {0, 255, 0},
            args = {'[SAFEZONE]', 'Zone #' .. zone.id .. ' creee ! Rayon: ' .. radius .. 'm | Direction: ' .. string.format("%.0f", heading) .. ' deg'}
        })

    -- ======= REMOVE =======
    elseif action == 'remove' or action == 'del' then
        local zoneId = tonumber(args[2])
        if not zoneId then
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[SAFEZONE]', 'Utilisation : /safezone remove [id]'} })
            return
        end

        if safezones[zoneId] then
            safezones[zoneId] = nil
            TriggerClientEvent('pvp_safezone:sync', -1, safezones)
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,165,0}, args = {'[SAFEZONE]', 'Zone #' .. zoneId .. ' supprimee !'} })
        else
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[SAFEZONE]', 'Zone #' .. zoneId .. ' introuvable !'} })
        end

    -- ======= LIST =======
    elseif action == 'list' then
        TriggerClientEvent('chat:addMessage', adminId, { color = {0,200,255}, args = {'[SAFEZONE]', '--- Liste des safezones ---'} })

        local count = 0
        for id, zone in pairs(safezones) do
            count = count + 1
            TriggerClientEvent('chat:addMessage', adminId, {
                color = {255,255,255},
                args = {'[#' .. id .. ']', 'Rayon: ' .. zone.radius .. 'm | Pos: ' .. string.format("%.0f, %.0f, %.0f", zone.x, zone.y, zone.z) .. ' | Par: ' .. zone.creator}
            })
        end

        if count == 0 then
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,255,255}, args = {'[SAFEZONE]', 'Aucune safezone active'} })
        else
            TriggerClientEvent('chat:addMessage', adminId, { color = {0,200,255}, args = {'[SAFEZONE]', 'Total: ' .. count .. ' zone(s)'} })
        end

    else
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[SAFEZONE]', 'Action inconnue. Utilise: add, remove, list'} })
    end
end, true) -- admin seulement


-- Quand un joueur se connecte, envoie-lui les safezones existantes
AddEventHandler('playerJoining', function()
    TriggerClientEvent('pvp_safezone:sync', source, safezones)
end)
