-- ==============================================
-- PVP LEADERBOARD - CLIENT
-- ==============================================

local menuOpen = false

RegisterCommand('leaderboard', function()
    if menuOpen then
        menuOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'close' })
    else
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'open', players = {} })
        TriggerServerEvent('pvp_leaderboard:requestStats')
    end
end, false) -- false = tous les joueurs peuvent voir le leaderboard

RegisterKeyMapping('leaderboard', 'Ouvrir le leaderboard PVP', 'keyboard', 'F5')

-- Quand on reçoit les stats du serveur
RegisterNetEvent('pvp_leaderboard:receiveStats')
AddEventHandler('pvp_leaderboard:receiveStats', function(data)
    if menuOpen then
        SendNUIMessage({
            type = 'update',
            data = data
        })
    end
end)

-- Fermer le menu
RegisterNUICallback('close', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
