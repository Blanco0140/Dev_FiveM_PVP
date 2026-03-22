local marketPeds = {}
local marketsData = {}
local marketOpen = false

local function CreateMarketPed(coords, h)
    local hash = GetHashKey(Config.PedModel)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, h, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

local function RefreshPeds()
    for _, p in pairs(marketPeds) do DeleteEntity(p) end
    marketPeds = {}
    for i, m in ipairs(marketsData) do
        marketPeds[i] = CreateMarketPed(vector3(m.x, m.y, m.z), m.h)
    end
end

RegisterNetEvent('pvp_market:updateMarkets')
AddEventHandler('pvp_market:updateMarkets', function(list)
    marketsData = list
    RefreshPeds()
end)

CreateThread(function()
    TriggerServerEvent('pvp_market:requestMarkets')
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if not marketOpen then
            for i, m in ipairs(marketsData) do
                local dist = #(pos - vector3(m.x, m.y, m.z))
                if dist < 5.0 then
                    wait = 0
                    DrawText3D(m.x, m.y, m.z + 1.0, "~w~Marché d'Armes~n~~r~[E]~w~ Ouvrir")
                    if dist < 1.5 and IsControlJustReleased(0, 38) then
                        OpenMarket()
                    end
                end
            end
        end
        Wait(wait)
    end
end)

function OpenMarket()
    marketOpen = true
    SetTimecycleModifier('hud_def_blur')
    SetNuiFocus(true, true)
    TriggerServerEvent('pvp_market:requestData')
end

RegisterNetEvent('pvp_market:openMarketData')
AddEventHandler('pvp_market:openMarketData', function(pts, invWeapons)
    if not marketOpen then return end
    SendNUIMessage({
        action = 'openMarket',
        catalog = Config.WeaponsBuy,
        inventory = invWeapons
    })
    SendNUIMessage({ action = 'setPoints', points = pts })
end)

RegisterNetEvent('pvp_market:updateData')
AddEventHandler('pvp_market:updateData', function(pts, invWeapons)
    if not marketOpen then return end
    SendNUIMessage({ action = 'updateInventory', inventory = invWeapons })
    SendNUIMessage({ action = 'setPoints', points = pts })
end)

RegisterNetEvent('pvp_market:updatePoints')
AddEventHandler('pvp_market:updatePoints', function(pts)
    SendNUIMessage({ action = 'setPoints', points = pts })
end)

RegisterNetEvent('pvp_market:notify')
AddEventHandler('pvp_market:notify', function(type, msg)
    SendNUIMessage({ action = 'notify', type = type, text = msg })
end)

RegisterNUICallback('close', function(_, cb)
    marketOpen = false
    ClearTimecycleModifier()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyWeapon', function(data, cb)
    TriggerServerEvent('pvp_market:buyWeapon', GetHashKey(data.hash))
    cb('ok')
end)

RegisterNUICallback('sellWeapon', function(data, cb)
    TriggerServerEvent('pvp_market:sellWeapon', data.hash)
    cb('ok')
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(1)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
