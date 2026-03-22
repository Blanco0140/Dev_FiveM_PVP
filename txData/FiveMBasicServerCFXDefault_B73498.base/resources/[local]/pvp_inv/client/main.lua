-- ================================================
--  PVP INVENTORY - Client FINAL
-- ================================================

local inventoryOpen = false
local myPlayerId    = PlayerId()
local myPedCache    = nil
local pedCacheTick  = 0

-- shortcuts[1..5] = hash (number) ou nil
local shortcuts = {}

local function GetPed()
    local tick = GetGameTimer()
    if tick - pedCacheTick > 1000 then
        myPedCache   = PlayerPedId()
        pedCacheTick = tick
    end
    return myPedCache
end

local weaponData = {
    [GetHashKey("weapon_pistol")]            = { name = "Pistolet",           cat = "Pistolets" },
    [GetHashKey("weapon_pistol_mk2")]        = { name = "Pistolet MK2",       cat = "Pistolets" },
    [GetHashKey("weapon_combatpistol")]      = { name = "Pistolet Combat",    cat = "Pistolets" },
    [GetHashKey("weapon_appistol")]          = { name = "Pistolet AP",        cat = "Pistolets" },
    [GetHashKey("weapon_heavypistol")]       = { name = "Pistolet Lourd",     cat = "Pistolets" },
    [GetHashKey("weapon_snspistol")]         = { name = "Pistolet SNS",       cat = "Pistolets" },
    [GetHashKey("weapon_microsmg")]          = { name = "Micro SMG",          cat = "SMG" },
    [GetHashKey("weapon_smg")]               = { name = "SMG",                cat = "SMG" },
    [GetHashKey("weapon_smg_mk2")]           = { name = "SMG MK2",            cat = "SMG" },
    [GetHashKey("weapon_assaultsmg")]        = { name = "SMG Assault",        cat = "SMG" },
    [GetHashKey("weapon_combatpdw")]         = { name = "PDW Combat",         cat = "SMG" },
    [GetHashKey("weapon_assaultrifle")]      = { name = "Fusil d'assaut",     cat = "Fusils" },
    [GetHashKey("weapon_assaultrifle_mk2")]  = { name = "Fusil d'assaut MK2", cat = "Fusils" },
    [GetHashKey("weapon_carbinerifle")]      = { name = "Carabine",           cat = "Fusils" },
    [GetHashKey("weapon_carbinerifle_mk2")]  = { name = "Carabine MK2",       cat = "Fusils" },
    [GetHashKey("weapon_advancedrifle")]     = { name = "Fusil Avancé",       cat = "Fusils" },
    [GetHashKey("weapon_specialcarbine")]    = { name = "Carabine Spéciale",  cat = "Fusils" },
    [GetHashKey("weapon_bullpuprifle")]      = { name = "Bullpup Rifle",      cat = "Fusils" },
    [GetHashKey("weapon_sniperrifle")]       = { name = "Sniper",             cat = "Snipers" },
    [GetHashKey("weapon_heavysniper")]       = { name = "Sniper Lourd",       cat = "Snipers" },
    [GetHashKey("weapon_heavysniper_mk2")]   = { name = "Sniper Lourd MK2",   cat = "Snipers" },
    [GetHashKey("weapon_marksmanrifle")]     = { name = "Fusil Précision",    cat = "Snipers" },
    [GetHashKey("weapon_pumpshotgun")]       = { name = "Shotgun Pompe",      cat = "Shotguns" },
    [GetHashKey("weapon_sawnoffshotgun")]    = { name = "Shotgun Scié",       cat = "Shotguns" },
    [GetHashKey("weapon_assaultshotgun")]    = { name = "Shotgun Assault",    cat = "Shotguns" },
    [GetHashKey("weapon_bullpupshotgun")]    = { name = "Shotgun Bullpup",    cat = "Shotguns" },
    [GetHashKey("weapon_heavyshotgun")]      = { name = "Shotgun Lourd",      cat = "Shotguns" },
    [GetHashKey("weapon_grenadelauncher")]   = { name = "Lance-grenades",     cat = "Lourdes" },
    [GetHashKey("weapon_rpg")]               = { name = "RPG",                cat = "Lourdes" },
    [GetHashKey("weapon_minigun")]           = { name = "Minigun",            cat = "Lourdes" },
    [GetHashKey("weapon_grenade")]           = { name = "Grenade",            cat = "Explosifs" },
    [GetHashKey("weapon_smokegrenade")]      = { name = "Grenade Fumigène",   cat = "Explosifs" },
    [GetHashKey("weapon_molotov")]           = { name = "Molotov",            cat = "Explosifs" },
    [GetHashKey("weapon_knife")]             = { name = "Couteau",            cat = "Mêlée" },
    [GetHashKey("weapon_bat")]               = { name = "Batte",              cat = "Mêlée" },
    [GetHashKey("weapon_knuckle")]           = { name = "Coup de Poing",      cat = "Mêlée" },
}

local WHEEL_CONTROLS = { 157, 158, 159, 160, 161, 162, 163, 164, 165 }
local CTRL_COUNT     = #WHEEL_CONTROLS
local UNARMED        = GetHashKey("weapon_unarmed")

-- ================================================
--  COMMANDE FALLBACK /inv
-- ================================================
RegisterCommand('inv', function()
    if not inventoryOpen then OpenInventory() end
end, false)

-- ================================================
--  THREAD : désactive roulette + détecte TAB
-- ================================================
CreateThread(function()
    while true do
        -- Lire TAB avant de le bloquer
        if not inventoryOpen and IsDisabledControlJustPressed(0, 37) then
            OpenInventory()
        end

        -- Bloquer weapon wheel natif
        DisableControlAction(0, 37, true)
        HideHudComponentThisFrame(20)
        for i = 1, CTRL_COUNT do
            DisableControlAction(0, WHEEL_CONTROLS[i], true)
        end

        Wait(0)
    end
end)

-- ================================================
--  OUVRIR INVENTAIRE
-- ================================================
function OpenInventory()
    inventoryOpen = true
    SetTimecycleModifier('hud_def_blur')
    TriggerServerEvent('pvp_inv:requestPoints')
    local ped     = GetPed()
    local weapons = {}
    local wCount  = 0

    for hash, data in next, weaponData do
        if HasPedGotWeapon(ped, hash, false) then
            wCount = wCount + 1
            local ammo    = GetAmmoInPedWeapon(ped, hash)
            local _, clip = GetAmmoInClip(ped, hash)
            weapons[wCount] = {
                hash = hash,
                name = data.name,
                cat  = data.cat,
                ammo = ammo,
                clip = clip,
            }
        end
    end

    local nearbyPlayers = {}
    local npCount       = 0
    local myCoords      = GetEntityCoords(ped, false)
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

    -- Sérialise les shortcuts pour le NUI
    local shortcutsSend = {}
    for i = 1, 5 do
        local hash = shortcuts[i]
        if hash then
            local d = weaponData[hash]
            shortcutsSend[i] = {
                hash = hash,
                name = d and d.name or "Arme",
                cat  = d and d.cat  or ""
            }
        end
    end

    SendNUIMessage({
        action        = 'openInventory',
        weapons       = weapons,
        nearbyPlayers = nearbyPlayers,
        shortcuts     = shortcutsSend
    })

    SetNuiFocus(true, true)
end

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
    SetCurrentPedWeapon(GetPed(), data.hash, true)
    cb('ok')
end)

RegisterNUICallback('dropWeapon', function(data, cb)
    RemoveWeaponFromPed(GetPed(), data.hash)
    -- Nettoie le slot si bindé (mais ne vide pas si arme retirée ailleurs)
    for i = 1, 5 do
        if shortcuts[i] == data.hash then shortcuts[i] = nil end
    end
    TriggerServerEvent('pvp_inv:dropWeapon', data.hash)
    cb('ok')
end)

RegisterNUICallback('bindShortcut', function(data, cb)
    local slot = tonumber(data.slot)
    local hash = tonumber(data.hash)
    if slot and slot >= 1 and slot <= 5 and hash then
        shortcuts[slot] = hash
    end
    cb('ok')
end)

RegisterNUICallback('unbindShortcut', function(data, cb)
    local slot = tonumber(data.slot)
    if slot and slot >= 1 and slot <= 5 then
        shortcuts[slot] = nil
    end
    cb('ok')
end)

-- Toggle depuis clic slot (inventaire ouvert, NuiFocus=true)
RegisterNUICallback('shortcutKey', function(data, cb)
    local slot = tonumber(data.slot)
    if slot then toggleSlot(slot) end
    cb('ok')
end)

-- Raccourcis 1-5 via RegisterKeyMapping
-- Methode FiveM officielle : fonctionne avec ou sans SetNuiFocus
-- Le joueur peut reconfigurer dans Echap > Paramètres > Touches

local function toggleSlot(i)
    local hash = shortcuts[i]
    if not hash then return end
    local ped = GetPed()
    if not HasPedGotWeapon(ped, hash, false) then return end
    if GetSelectedPedWeapon(ped) == hash then
        SetCurrentPedWeapon(ped, UNARMED, true)
    else
        SetCurrentPedWeapon(ped, hash, true)
    end
end

for i = 1, 5 do
    local slot = i
    RegisterKeyMapping('+sc' .. slot, 'Raccourci arme ' .. slot, 'keyboard', tostring(slot))
    RegisterCommand('+sc' .. slot, function() toggleSlot(slot) end, false)
    RegisterCommand('-sc' .. slot, function() end, false)
end

RegisterNUICallback('giveWeapon', function(data, cb)
    TriggerServerEvent('pvp_inv:giveWeapon', data.targetId, data.hash, data.ammo)
    cb('ok')
end)

RegisterNUICallback('requestTrade', function(data, cb)
    TriggerServerEvent('pvp_inv:requestTrade', data.targetId, data.hash, data.ammo)
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

RegisterNetEvent('pvp_inv:receiveWeapon', function(fromName, weaponHash, ammo)
    GiveWeaponToPed(GetPed(), weaponHash, ammo, false, false)
    local d = weaponData[weaponHash]
    notify("✅ " .. fromName .. " vous a donné : " .. (d and d.name or "Arme"), 'success')
end)

RegisterNetEvent('pvp_inv:tradeRequest', function(tradeId, fromName, fromId, weaponHash, ammo)
    local d = weaponData[weaponHash]
    SendNUIMessage({
        action     = 'tradeRequest',
        tradeId    = tradeId,
        fromName   = fromName,
        weaponName = d and d.name or "Arme",
        ammo       = ammo
    })
end)

RegisterNetEvent('pvp_inv:tradeAccepted', function(_, weaponHash, ammo)
    GiveWeaponToPed(GetPed(), weaponHash, ammo, false, false)
    local d = weaponData[weaponHash]
    notify("✅ Trade accepté ! Reçu : " .. (d and d.name or "Arme"), 'success')
end)

RegisterNetEvent('pvp_inv:tradeDeclined', function()
    notify("❌ Trade refusé.", 'error')
end)

-- Quand une arme est retirée (don/trade) : vide aussi le bind
RegisterNetEvent('pvp_inv:removeWeapon', function(weaponHash)
    RemoveWeaponFromPed(GetPed(), weaponHash)
    for i = 1, 5 do
        if shortcuts[i] == weaponHash then shortcuts[i] = nil end
    end
end)
