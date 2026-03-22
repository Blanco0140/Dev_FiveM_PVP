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

    -- Demande des points (on attend 100ms via Callbacks c'est compliqué sans framework, donc on feinte, on utilise la NUI pour tout demander
    -- Mais on a besoin de savoir les armes que le joueur possède pour l'onglet 'Vendre'
    local pPed = PlayerPedId()
    local myWeapons = {}
    for hash, value in pairs(Config.WeaponsSellValues) do
        if HasPedGotWeapon(pPed, hash, false) then
            -- On retrouve le nom dans WeaponsBuy ou générique
            local wName = "Arme Inconnue"
            for _, wb in ipairs(Config.WeaponsBuy) do
                if GetHashKey(wb.hash) == hash then
                    wName = wb.name
                    break
                end
            end
            table.insert(myWeapons, {
                hash = hash,
                name = wName,
                value = value
            })
        end
    end

    -- Pour simplifier, on demande les points au serveur via un callBack ou Event synchronisé ? 
    -- On va envoyer ce qu'on a, et le serveur mettra à jour nos points dès qu'on checkera.
    -- On utilise un Request Points
    TriggerServerEvent('pvp_market:requestPoints')

    SendNUIMessage({
        action = 'openMarket',
        catalog = Config.WeaponsBuy,
        inventory = myWeapons
    })
end

RegisterNetEvent('pvp_market:updatePoints')
AddEventHandler('pvp_market:updatePoints', function(pts)
    SendNUIMessage({ action = 'setPoints', points = pts })
end)

RegisterNetEvent('pvp_market:notify')
AddEventHandler('pvp_market:notify', function(type, msg)
    SendNUIMessage({ action = 'notify', type = type, text = msg })
    -- Si c'est un refresh (ex: on vient de vendre/acheter on refresh l'inventory localement)
    if marketOpen then
        local pPed = PlayerPedId()
        local myWeapons = {}
        for hash, value in pairs(Config.WeaponsSellValues) do
            if HasPedGotWeapon(pPed, hash, false) then
                local wName = "Arme Inconnue"
                for _, wb in ipairs(Config.WeaponsBuy) do
                    if GetHashKey(wb.hash) == hash then
                        wName = wb.name break
                    end
                end
                table.insert(myWeapons, { hash = hash, name = wName, value = value })
            end
        end
        SendNUIMessage({ action = 'updateInventory', inventory = myWeapons })
    end
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
