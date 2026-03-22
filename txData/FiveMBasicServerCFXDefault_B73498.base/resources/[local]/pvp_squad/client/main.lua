-- ================================================
--  PVP SQUAD - Client
-- ================================================

local squadOpen    = false
local mySquad      = nil
local squadMembers = {}
local myServerId   = GetPlayerServerId(PlayerId())
local showHUD      = true

CreateThread(function()
    while true do

        -- Friendly Fire OFF pour les membres de la même squad
        if #squadMembers > 0 then
            local myPed = PlayerPedId()
            for _, serverId in ipairs(squadMembers) do
                if serverId ~= myServerId then
                    local targetPlayer = GetPlayerFromServerId(serverId)
                    if targetPlayer ~= -1 then
                        local targetPed = GetPlayerPed(targetPlayer)
                        if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                            SetEntityCanBeDamagedByRelationshipGroup(myPed, false)
                            SetEntityCanBeDamagedByRelationshipGroup(targetPed, false)
                            -- Restaure HP si blessé par coéquipier
                            local myHp = GetEntityHealth(myPed)
                            if myHp > 0 and myHp < 200 then
                                if GetPedSourceOfDeath(myPed) == targetPed then
                                    SetEntityHealth(myPed, math.min(myHp + 5, 200))
                                end
                            end
                        end
                    end
                end
            end
            NetworkSetFriendlyFireOption(false)
        end

        Wait(0)
    end
end)

RegisterCommand('squad', function()
    if squadOpen then CloseSquad() else OpenSquad() end
end, false)

-- Raccourci natif FiveM modifiable dans les options du jeu
RegisterKeyMapping('squad', 'Ouvrir le menu Squad', 'keyboard', 'J')

function OpenSquad()
    squadOpen = true
    SetTimecycleModifier('hud_def_blur')
    TriggerServerEvent('pvp_squad:getList')
    SendNUIMessage({ action = 'open', mySquad = mySquad, myServerId = myServerId })
    SetNuiFocus(true, true)
end

function CloseSquad()
    squadOpen = false
    ClearTimecycleModifier()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- NUI CALLBACKS
RegisterNUICallback('close',           function(_, cb) CloseSquad() cb('ok') end)
RegisterNUICallback('keyJ',            function(_, cb) CloseSquad() cb('ok') end)

RegisterNUICallback('createSquad', function(data, cb)
    TriggerServerEvent('pvp_squad:create', tostring(data.name or "Ma Squad"):sub(1,20), data.isPublic == true)
    cb('ok')
end)

RegisterNUICallback('joinSquad',    function(data, cb) TriggerServerEvent('pvp_squad:join',          data.squadId)  cb('ok') end)
RegisterNUICallback('requestJoin',  function(data, cb) TriggerServerEvent('pvp_squad:requestJoin',   data.squadId)  cb('ok') end)
RegisterNUICallback('leaveSquad',   function(_, cb)    TriggerServerEvent('pvp_squad:leave')                        cb('ok') end)
RegisterNUICallback('kickMember',   function(data, cb) TriggerServerEvent('pvp_squad:kick',          data.targetSrc) cb('ok') end)
RegisterNUICallback('setVisibility',function(data, cb) TriggerServerEvent('pvp_squad:setVisibility', data.isPublic) cb('ok') end)
RegisterNUICallback('acceptJoin',   function(data, cb) TriggerServerEvent('pvp_squad:acceptJoin',    data.targetSrc) cb('ok') end)
RegisterNUICallback('toggleHUD',    function(data, cb) showHUD = data.show == true                                  cb('ok') end)

-- EVENTS SERVEUR
RegisterNetEvent('pvp_squad:squadList', function(list)
    SendNUIMessage({ action = 'squadList', squads = list })
end)

RegisterNetEvent('pvp_squad:mySquad', function(squadData)
    mySquad      = squadData
    squadMembers = {}
    if squadData then
        for _, m in ipairs(squadData.members) do
            table.insert(squadMembers, m.id)
        end
    end
    SendNUIMessage({ action = 'mySquad', squad = mySquad, show = showHUD })
end)

RegisterNetEvent('pvp_squad:updateMembers', function(members)
    squadMembers = members or {}
end)

RegisterNetEvent('pvp_squad:joinRequest', function(requesterSrc, requesterName, squadId)
    SendNUIMessage({ action = 'joinRequest', requesterSrc = requesterSrc, requesterName = requesterName, squadId = squadId })
end)

RegisterNetEvent('pvp_squad:notification', function(msg, ntype)
    SendNUIMessage({ action = 'notification', msg = msg, ntype = ntype or 'info' })
end)
