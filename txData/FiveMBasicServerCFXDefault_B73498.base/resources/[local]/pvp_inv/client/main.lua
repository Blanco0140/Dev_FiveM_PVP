-- ================================================
--  PVP INVENTORY - Client (UUID VERSION)
-- ================================================

local inventoryOpen = false
local myPlayerId    = PlayerId()

local MyInventory   = {}
local EquippedUUID  = nil

local shortcuts     = {} -- 1..5 = uuid

local UNARMED = GetHashKey("weapon_unarmed")
local WHEEL_CONTROLS = { 157, 158, 159, 160, 161, 162, 163, 164, 165 }

-- ================================================
-- INITIALISATION 
-- ================================================
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('pvp_inv:requestData')
end)

RegisterNetEvent('pvp_inv:updateInventory', function(inv)
    MyInventory = inv
    
    -- Verification : l'arme equipee existe-t-elle toujours ?
    if EquippedUUID then
        local found = false
        for _, it in ipairs(MyInventory) do
            if it.uuid == EquippedUUID then found = true break end
        end
        if not found then
            SetCurrentPedWeapon(PlayerPedId(), UNARMED, true)
            EquippedUUID = nil
        end
    end

    if inventoryOpen then
        RefreshUI()
    end
end)

-- ================================================
-- SYSTEME D'EQUIPEMENT (UUID)
-- ================================================
local function SaveCurrentAmmo()
    if not EquippedUUID then return end
    local ped = PlayerPedId()
    for _, item in ipairs(MyInventory) do
        if item.uuid == EquippedUUID then
            local _, clip = GetAmmoInClip(ped, item.hash)
            local ammo = GetAmmoInPedWeapon(ped, item.hash)
            TriggerServerEvent('pvp_inv:updateItemAmmo', item.uuid, ammo)
            item.ammo = ammo
            break
        end
    end
end

local function UnequipCurrent()
    if not EquippedUUID then return end
    SaveCurrentAmmo()
    local ped = PlayerPedId()
    -- On trouve le hash pour le retirer proprement afin qu'il ne reste pas natif
    for _, item in ipairs(MyInventory) do
        if item.uuid == EquippedUUID then
            RemoveWeaponFromPed(ped, item.hash)
            break
        end
    end
    SetCurrentPedWeapon(ped, UNARMED, true)
    EquippedUUID = nil
end

RegisterNetEvent('pvp_inv:doEquip', function(uuid, hash, ammo)
    if EquippedUUID and EquippedUUID ~= uuid then
        UnequipCurrent()
    end
    EquippedUUID = uuid
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, hash, ammo, false, true)
    SetCurrentPedWeapon(ped, hash, true)
end)

local function ToggleUUID(uuid)
    if EquippedUUID == uuid then
        UnequipCurrent()
    else
        TriggerServerEvent('pvp_inv:equipItem', uuid)
    end
end

-- ================================================
-- BLOCK NATIVE WEAPON WHEEL
-- ================================================
CreateThread(function()
    while true do
        if not inventoryOpen and IsDisabledControlJustPressed(0, 37) then
            OpenInventory()
        end
        DisableControlAction(0, 37, true)
        HideHudComponentThisFrame(20)
        for i = 1, #WHEEL_CONTROLS do
            DisableControlAction(0, WHEEL_CONTROLS[i], true)
        end
        Wait(0)
    end
end)

-- ================================================
--  OUVRIR INVENTAIRE
-- ================================================
function RefreshUI()
    local ped = PlayerPedId()
    local nearbyPlayers = {}
    local npCount = 0
    local myCoords = GetEntityCoords(ped, false)
    local activePlayers = GetActivePlayers()

    for i = 1, #activePlayers do
        local player = activePlayers[i]
        if player ~= myPlayerId then
            local dist = #(myCoords - GetEntityCoords(GetPlayerPed(player), false))
            if dist <= 10.0 then
                npCount = npCount + 1
                nearbyPlayers[npCount] = {
                    id   = GetPlayerServerId(player),
                    name = GetPlayerName(player),
                    dist = math.floor(dist * 10 + 0.5) / 10
                }
            end
        end
    end

    local shortcutsSend = {}
    for i = 1, 5 do
        local u = shortcuts[i]
        if u then
            for _, item in ipairs(MyInventory) do
                if item.uuid == u then
                    shortcutsSend[i] = {
                        uuid = u,
                        hash = item.hash,
                        name = item.name,
                        cat  = "Arme"
                    }
                    break
                end
            end
        end
    end

    -- Update ammo du current equipé juste pour l'UI
    if EquippedUUID then
        for _, item in ipairs(MyInventory) do
            if item.uuid == EquippedUUID then
                item.ammo = GetAmmoInPedWeapon(ped, item.hash)
                break
            end
        end
    end

    SendNUIMessage({
        action        = 'openInventory',
        weapons       = MyInventory,
        nearbyPlayers = nearbyPlayers,
        shortcuts     = shortcutsSend
    })
end

function OpenInventory()
    inventoryOpen = true
    SetTimecycleModifier('hud_def_blur')
    TriggerServerEvent('pvp_inv:requestPoints')
    RefreshUI()
    SetNuiFocus(true, true)
end

RegisterCommand('inv', function()
    if not inventoryOpen then OpenInventory() end
end, false)

-- ================================================
--  NUI CALLBACKS
-- ================================================
RegisterNUICallback('closeInventory', function(_, cb)
    inventoryOpen = false
    ClearTimecycleModifier()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('equipWeapon', function(data, cb)
    ToggleUUID(data.uuid)
    cb('ok')
end)

RegisterNUICallback('dropWeapon', function(data, cb)
    if EquippedUUID == data.uuid then UnequipCurrent() end
    for i = 1, 5 do if shortcuts[i] == data.uuid then shortcuts[i] = nil end end
    TriggerServerEvent('pvp_inv:dropItem', data.uuid)
    cb('ok')
end)

RegisterNUICallback('bindShortcut', function(data, cb)
    local slot = tonumber(data.slot)
    if slot and slot >= 1 and slot <= 5 and data.uuid then
        shortcuts[slot] = data.uuid
    end
    cb('ok')
end)

RegisterNUICallback('unbindShortcut', function(data, cb)
    local slot = tonumber(data.slot)
    if slot and slot >= 1 and slot <= 5 then shortcuts[slot] = nil end
    cb('ok')
end)

RegisterNUICallback('shortcutKey', function(data, cb)
    local slot = tonumber(data.slot)
    if slot and shortcuts[slot] then ToggleUUID(shortcuts[slot]) end
    cb('ok')
end)

for i = 1, 5 do
    local slot = i
    RegisterKeyMapping('+scUUID' .. slot, 'Raccourci arme ' .. slot, 'keyboard', tostring(slot))
    RegisterCommand('+scUUID' .. slot, function() 
        if shortcuts[slot] then ToggleUUID(shortcuts[slot]) end
    end, false)
    RegisterCommand('-scUUID' .. slot, function() end, false)
end

RegisterNUICallback('giveWeapon', function(data, cb)
    if EquippedUUID == data.uuid then UnequipCurrent() end
    TriggerServerEvent('pvp_inv:giveItem', data.targetId, data.uuid)
    cb('ok')
end)

RegisterNUICallback('requestTrade', function(data, cb)
    if EquippedUUID == data.uuid then UnequipCurrent() end
    TriggerServerEvent('pvp_inv:requestTrade', data.targetId, data.uuid)
    cb('ok')
end)

RegisterNUICallback('acceptTrade', function(data, cb)
    TriggerServerEvent('pvp_inv:acceptTrade', data.tradeId)
    cb('ok')
end)

RegisterNUICallback('declineTrade', function(data, cb)
    TriggerServerEvent('pvp_inv:declineTrade', data.tradeId)
    cb('ok')
end)

-- ================================================
--  EVENTS RÉSEAU → CLIENT
-- ================================================
local function notify(msg, ntype)
    SendNUIMessage({ action = 'notification', msg = msg, ntype = ntype })
end

RegisterNetEvent('pvp_inv:receivePoints', function(pts)
    SendNUIMessage({ action = 'setPoints', points = pts })
end)

RegisterNetEvent('pvp_inv:notifyTrade', function(msg, ntype)
    notify(msg, ntype)
end)

RegisterNetEvent('pvp_inv:tradeRequest', function(tradeId, fromName, fromId, weaponName, ammo)
    SendNUIMessage({
        action = 'tradeRequest',
        tradeId = tradeId,
        fromName = fromName,
        fromId = fromId,
        weaponName = weaponName .. " (" .. ammo .. " balles)"
    })
end)
