-- ==============================================
-- TELEPORTER SERVER.LUA - Gestion des PED teleporteurs
-- ==============================================

local teleporters = {}
local nextId = 1

-- /teleporter add : Place un PED téléporteur à ta position
RegisterCommand('teleporter', function(source, args)
    local adminId = source

    if #args < 1 then
        TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[TELEPORTER]', 'Utilisation :\n/teleporter add - Placer un PED\n/teleporter remove [id] - Supprimer\n/teleporter list - Voir tous les PED'} })
        return
    end

    local action = string.lower(args[1])

    if action == 'add' then
        local ped = GetPlayerPed(adminId)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local tp = {
            id = nextId,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = heading
        }

        teleporters[nextId] = tp
        nextId = nextId + 1

        TriggerClientEvent('pvp_teleporter:sync', -1, teleporters)
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {0, 255, 0},
            args = {'[TELEPORTER]', 'PED Teleporteur #' .. tp.id .. ' place !'}
        })

    elseif action == 'remove' or action == 'del' then
        local tpId = tonumber(args[2])
        if not tpId then
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[TELEPORTER]', 'Utilisation : /teleporter remove [id]'} })
            return
        end
        if teleporters[tpId] then
            teleporters[tpId] = nil
            TriggerClientEvent('pvp_teleporter:sync', -1, teleporters)
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,165,0}, args = {'[TELEPORTER]', 'Teleporteur #' .. tpId .. ' supprime !'} })
        else
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,0,0}, args = {'[TELEPORTER]', 'Teleporteur #' .. tpId .. ' introuvable !'} })
        end

    elseif action == 'list' then
        local count = 0
        for id, tp in pairs(teleporters) do
            count = count + 1
            TriggerClientEvent('chat:addMessage', adminId, {
                color = {255,255,255},
                args = {'[#' .. id .. ']', string.format("Pos: %.0f, %.0f, %.0f", tp.x, tp.y, tp.z)}
            })
        end
        if count == 0 then
            TriggerClientEvent('chat:addMessage', adminId, { color = {255,255,255}, args = {'[TELEPORTER]', 'Aucun teleporteur actif'} })
        end
    end
end, true)

-- Quand un joueur se connecte
AddEventHandler('playerJoining', function()
    TriggerClientEvent('pvp_teleporter:sync', source, teleporters)
end)

-- Le client demande les safezones pour le menu
RegisterNetEvent('pvp_teleporter:requestSafezones')
AddEventHandler('pvp_teleporter:requestSafezones', function()
    -- Redirige au client directement (le client utilisera l'export de pvp_safezone)
    TriggerClientEvent('pvp_teleporter:openMenu', source)
end)
