-- ================================================
--  PVP SQUAD - Server FINAL
-- ================================================

local squads       = {}
local playerSquad  = {}
local squadCounter = 0

local function GetName(src)
    return GetPlayerName(src) or ("Joueur " .. tostring(src))
end

local function IsValid(src)
    return src ~= nil and type(src) == "number" and GetPlayerPing(src) >= 0
end

local function NewSquadId()
    squadCounter = squadCounter + 1
    return squadCounter
end

local function SerializeSquad(squad)
    local members = {}
    for i, memberId in ipairs(squad.members) do
        members[i] = { id = memberId, name = GetName(memberId) }
    end
    return {
        id       = squad.id,
        name     = squad.name,
        leader   = squad.leader,
        members  = members,
        isPublic = squad.isPublic,
        slots    = #squad.members,
        maxSlots = squad.maxSlots
    }
end

local function SendSquadList(src)
    local list = {}
    for _, squad in pairs(squads) do
        table.insert(list, SerializeSquad(squad))
    end
    TriggerClientEvent('pvp_squad:squadList', src, list)
end

local function BroadcastSquadList()
    local list = {}
    for _, squad in pairs(squads) do
        table.insert(list, SerializeSquad(squad))
    end
    TriggerClientEvent('pvp_squad:squadList', -1, list)
end

local function BroadcastSquadMembers()
    for _, squad in pairs(squads) do
        local memberIds = {}
        for _, mid in ipairs(squad.members) do
            table.insert(memberIds, mid)
        end
        for _, mid in ipairs(squad.members) do
            if IsValid(mid) then
                TriggerClientEvent('pvp_squad:updateMembers', mid, memberIds)
            end
        end
    end
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid and not playerSquad[pid] then
            TriggerClientEvent('pvp_squad:updateMembers', pid, {})
        end
    end
end

-- Retire un joueur de sa squad (usage interne)
local function LeaveSquad(src)
    local squadId = playerSquad[src]
    if not squadId then return end

    local squad = squads[squadId]
    if not squad then
        playerSquad[src] = nil
        return
    end

    -- Retire le membre de la liste
    for i = #squad.members, 1, -1 do
        if squad.members[i] == src then
            table.remove(squad.members, i)
            break
        end
    end

    playerSquad[src] = nil
    TriggerClientEvent('pvp_squad:mySquad',       src, nil)
    TriggerClientEvent('pvp_squad:updateMembers', src, {})
    TriggerClientEvent('pvp_squad:notification',  src, "Vous avez quitté la squad.", 'info')

    -- Squad vide → suppression
    if #squad.members == 0 then
        squads[squadId] = nil
        BroadcastSquadList()
        BroadcastSquadMembers()
        return
    end

    -- Nouveau leader si besoin
    if squad.leader == src then
        squad.leader = squad.members[1]
        if IsValid(squad.leader) then
            TriggerClientEvent('pvp_squad:notification', squad.leader, "Vous êtes le nouveau chef de squad !", 'success')
        end
    end

    -- Notifie les membres restants
    for _, mid in ipairs(squad.members) do
        if IsValid(mid) then
            TriggerClientEvent('pvp_squad:mySquad', mid, SerializeSquad(squad))
        end
    end

    BroadcastSquadList()
    BroadcastSquadMembers()
end

-- ================================================
--  EVENTS
-- ================================================

RegisterNetEvent('pvp_squad:getList', function()
    SendSquadList(source)
end)

RegisterNetEvent('pvp_squad:create', function(squadName, isPublic)
    local src = source
    if not IsValid(src) then return end
    if playerSquad[src] then
        TriggerClientEvent('pvp_squad:notification', src, "Quittez votre squad actuelle d'abord.", 'error')
        return
    end

    squadName = tostring(squadName or ""):sub(1, 20)
    if squadName == "" then squadName = "Squad de " .. GetName(src) end

    local squadId = NewSquadId()
    squads[squadId] = {
        id       = squadId,
        name     = squadName,
        leader   = src,
        members  = { src },
        isPublic = isPublic == true,
        maxSlots = 10
    }
    playerSquad[src] = squadId

    TriggerClientEvent('pvp_squad:mySquad',      src, SerializeSquad(squads[squadId]))
    TriggerClientEvent('pvp_squad:notification', src, "Squad \"" .. squadName .. "\" créée !", 'success')

    BroadcastSquadList()
    BroadcastSquadMembers()
end)

RegisterNetEvent('pvp_squad:join', function(squadId)
    local src = source
    if not IsValid(src) then return end
    if playerSquad[src] then
        TriggerClientEvent('pvp_squad:notification', src, "Quittez votre squad actuelle d'abord.", 'error')
        return
    end

    squadId = tonumber(squadId)
    if not squadId then return end
    local squad = squads[squadId]
    if not squad then
        TriggerClientEvent('pvp_squad:notification', src, "Squad introuvable.", 'error')
        return
    end
    if not squad.isPublic then
        TriggerClientEvent('pvp_squad:notification', src, "Cette squad est privée.", 'error')
        return
    end
    if #squad.members >= squad.maxSlots then
        TriggerClientEvent('pvp_squad:notification', src, "La squad est complète (10/10).", 'error')
        return
    end

    table.insert(squad.members, src)
    playerSquad[src] = squadId

    for _, mid in ipairs(squad.members) do
        if IsValid(mid) then
            TriggerClientEvent('pvp_squad:mySquad', mid, SerializeSquad(squad))
            if mid ~= src then
                TriggerClientEvent('pvp_squad:notification', mid, GetName(src) .. " a rejoint la squad !", 'info')
            end
        end
    end
    TriggerClientEvent('pvp_squad:notification', src, "Vous avez rejoint \"" .. squad.name .. "\" !", 'success')

    BroadcastSquadList()
    BroadcastSquadMembers()
end)

RegisterNetEvent('pvp_squad:requestJoin', function(squadId)
    local src = source
    if not IsValid(src) then return end
    if playerSquad[src] then
        TriggerClientEvent('pvp_squad:notification', src, "Quittez votre squad actuelle d'abord.", 'error')
        return
    end

    squadId = tonumber(squadId)
    if not squadId then return end
    local squad = squads[squadId]
    if not squad then return end

    if #squad.members >= squad.maxSlots then
        TriggerClientEvent('pvp_squad:notification', src, "La squad est complète.", 'error')
        return
    end

    if IsValid(squad.leader) then
        TriggerClientEvent('pvp_squad:joinRequest', squad.leader, src, GetName(src), squadId)
        TriggerClientEvent('pvp_squad:notification', src, "Demande envoyée au chef de squad.", 'info')
    end
end)

RegisterNetEvent('pvp_squad:acceptJoin', function(targetSrc)
    local src     = source
    targetSrc     = tonumber(targetSrc)
    if not targetSrc then return end

    local squadId = playerSquad[src]
    if not squadId then return end
    local squad = squads[squadId]
    if not squad or squad.leader ~= src then return end
    if not IsValid(targetSrc) then return end
    if playerSquad[targetSrc] then
        TriggerClientEvent('pvp_squad:notification', src, "Ce joueur est déjà dans une squad.", 'error')
        return
    end
    if #squad.members >= squad.maxSlots then
        TriggerClientEvent('pvp_squad:notification', src, "La squad est complète.", 'error')
        return
    end

    table.insert(squad.members, targetSrc)
    playerSquad[targetSrc] = squadId

    for _, mid in ipairs(squad.members) do
        if IsValid(mid) then
            TriggerClientEvent('pvp_squad:mySquad', mid, SerializeSquad(squad))
            if mid ~= targetSrc then
                TriggerClientEvent('pvp_squad:notification', mid, GetName(targetSrc) .. " a rejoint la squad !", 'info')
            end
        end
    end
    TriggerClientEvent('pvp_squad:notification', targetSrc, "Demande acceptée ! Bienvenue dans \"" .. squad.name .. "\" !", 'success')

    BroadcastSquadList()
    BroadcastSquadMembers()
end)

RegisterNetEvent('pvp_squad:leave', function()
    LeaveSquad(source)
end)

RegisterNetEvent('pvp_squad:kick', function(targetSrc)
    local src     = source
    targetSrc     = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then return end

    local squadId = playerSquad[src]
    if not squadId then return end
    local squad = squads[squadId]
    if not squad or squad.leader ~= src then
        TriggerClientEvent('pvp_squad:notification', src, "Seul le chef peut exclure.", 'error')
        return
    end
    if playerSquad[targetSrc] ~= squadId then return end

    -- Retire le membre
    for i = #squad.members, 1, -1 do
        if squad.members[i] == targetSrc then
            table.remove(squad.members, i)
            break
        end
    end

    playerSquad[targetSrc] = nil
    TriggerClientEvent('pvp_squad:mySquad',       targetSrc, nil)
    TriggerClientEvent('pvp_squad:updateMembers', targetSrc, {})
    TriggerClientEvent('pvp_squad:notification',  targetSrc, "Vous avez été exclu de la squad.", 'error')
    TriggerClientEvent('pvp_squad:notification',  src, GetName(targetSrc) .. " a été exclu.", 'info')

    for _, mid in ipairs(squad.members) do
        if IsValid(mid) then
            TriggerClientEvent('pvp_squad:mySquad', mid, SerializeSquad(squad))
        end
    end

    BroadcastSquadList()
    BroadcastSquadMembers()
end)

RegisterNetEvent('pvp_squad:setVisibility', function(isPublic)
    local src     = source
    local squadId = playerSquad[src]
    if not squadId then return end
    local squad = squads[squadId]
    if not squad or squad.leader ~= src then return end

    squad.isPublic = isPublic == true
    local msg = squad.isPublic and "Squad rendue publique." or "Squad rendue privée."

    for _, mid in ipairs(squad.members) do
        if IsValid(mid) then
            TriggerClientEvent('pvp_squad:mySquad', mid, SerializeSquad(squad))
        end
    end
    TriggerClientEvent('pvp_squad:notification', src, msg, 'info')

    BroadcastSquadList()
end)

AddEventHandler('playerDropped', function()
    local src = source
    LeaveSquad(src)
    playerSquad[src] = nil
end)
