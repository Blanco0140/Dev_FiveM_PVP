-- ============================================================
--  PVP CHEST — Client
-- ============================================================

local isOpen = false
local isNear = false

local function CloseChest()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

-- ─── L'inventaire est géré serveur ────────────────────────────
-- ─── plus besoin de GetPedWeapons ────────────────────────────

-- ─── Spawn des props ─────────────────────────────────────────
Citizen.CreateThread(function()
    local model = GetHashKey('prop_mil_crate_01')  -- hors boucle : calculé une seule fois
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end

    for _, loc in ipairs(Config.Locations) do
        local prop = CreateObject(model, loc.x, loc.y, loc.z, false, true, false)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)
        SetEntityInvincible(prop, true)
    end

    SetModelAsNoLongerNeeded(model)  -- libère après tous les spawns
end)

-- ─── Thread 1 : proximité + texte ────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local pos   = GetEntityCoords(PlayerPedId())
        isNear      = false

        for _, loc in ipairs(Config.Locations) do
            local dx   = pos.x - loc.x
            local dy   = pos.y - loc.y
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist < 15.0 then
                sleep  = 0
                isNear = true

                if dist < Config.Radius + 1.0 then
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextScale(0.0, 0.45)
                    SetTextColour(255, 255, 255, 215)
                    SetTextDropShadow()
                    SetTextEntry('STRING')
                    AddTextComponentString('~INPUT_CONTEXT~ Ouvrir le coffre')
                    DrawText(0.5, 0.85)
                end

                if dist > Config.Radius + 2.0 and isOpen then
                    CloseChest()
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- ─── Thread 2 : touche E ─────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        if isNear and not isOpen then
            Citizen.Wait(0)
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 51) then
                TriggerServerEvent('pvpChest:open')
            end
        elseif isOpen then
            Citizen.Wait(0)
            if IsControlJustPressed(0, 200) then
                CloseChest()
            end
        else
            Citizen.Wait(500)
        end
    end
end)

-- ─── Callbacks NUI ───────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    CloseChest()
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('pvpChest:deposit', data.uuid)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('pvpChest:withdraw', data.uuid)
    cb('ok')
end)

-- ─── Réponses serveur ────────────────────────────────────────
RegisterNetEvent('pvpChest:update', function(inventory, chest)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'update', inventory = inventory, chest = chest })
end)
