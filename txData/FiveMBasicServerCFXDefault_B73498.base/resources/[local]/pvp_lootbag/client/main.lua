-- ============================================
--        LOOTBAG SYSTEM - CLIENT SIDE v2.1
-- ============================================

local activeBags   = {}
local isLooting    = false

-- ============================================
-- Notification native
-- ============================================

local function notify(msg)
    if not Config.Notifications then return end
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, true)
end

-- ============================================
-- Texte 3D flottant
-- ============================================

local function drawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local cam = GetGameplayCamCoords()
    local dist = #(cam - vector3(x, y, z))
    if dist < 0.01 then return end

    local scale = (1.0 / dist) * 1.4 * ((1.0 / GetGameplayCamFov()) * 100.0)

    SetTextScale(0.0, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

-- ============================================
-- Marker cylindrique
-- ============================================

local function drawMarker(x, y, z)
    if not Config.ShowMarker then return end
    DrawMarker(
        2,
        x, y, z - 0.9,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.5, 0.5, 0.3,
        Config.MarkerColor.r,
        Config.MarkerColor.g,
        Config.MarkerColor.b,
        Config.MarkerColor.a,
        false, false, 2, false, nil, nil, false
    )
end

-- ============================================
-- Spawn du sac cote client
-- ============================================

RegisterNetEvent('lootbag:spawnBag')
AddEventHandler('lootbag:spawnBag', function(bagId, coords, weapons)
    local bx = coords.x
    local by = coords.y
    local bz = coords.z

    -- Stocker immediatement pour que le marker s'affiche sans attendre le prop
    activeBags[bagId] = {
        object    = nil,
        coords    = vector3(bx, by, bz),
        weapons   = weapons,
        spawnTime = GetGameTimer()
    }

    CreateThread(function()
        -- Liste de props, prop_ld_dl_bag_01 est dans le DLC mpheist (chargement plus long)
        local propList = {
            'prop_ld_dl_bag_01',
            'prop_ld_dl_bag_01b',
            'prop_money_bag_01',
            'prop_cs_cardbox_01',
        }

        local model = nil
        for _, propName in ipairs(propList) do
            local hash = GetHashKey(propName)
            RequestModel(hash)
            local t = 0
            while not HasModelLoaded(hash) and t < 80 do  -- 8s max par prop
                Wait(100)
                t = t + 1
            end
            if HasModelLoaded(hash) then
                model = hash
                print('[LootBag] Prop charge : ' .. propName)
                break
            else
                print('[LootBag] Prop indisponible : ' .. propName)
                SetModelAsNoLongerNeeded(hash)
            end
        end

        if not activeBags[bagId] then
            if model then SetModelAsNoLongerNeeded(model) end
            return
        end

        if not model then
            print('[LootBag] Aucun prop disponible pour sac #' .. tostring(bagId) .. ' (marker actif)')
            return
        end

        local obj = CreateObjectNoOffset(model, bx, by, bz, false, false, false)

        if not DoesEntityExist(obj) then
            print('[LootBag] Echec creation objet pour sac #' .. tostring(bagId))
            SetModelAsNoLongerNeeded(model)
            return
        end

        SetEntityCollision(obj, false, false)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(model)

        if activeBags[bagId] then
            activeBags[bagId].object = obj
        else
            DeleteObject(obj)
        end

        print('[LootBag] Sac #' .. tostring(bagId) .. ' spawne.')
    end)
end)

-- ============================================
-- Suppression du sac
-- ============================================

RegisterNetEvent('lootbag:removeBag')
AddEventHandler('lootbag:removeBag', function(bagId)
    if activeBags[bagId] then
        local obj = activeBags[bagId].object
        if obj and DoesEntityExist(obj) then
            DeleteObject(obj)
        end
        activeBags[bagId] = nil
    end
end)

-- ============================================
-- Resultat du loot (retour serveur)
-- ============================================

RegisterNetEvent('lootbag:lootResult')
AddEventHandler('lootbag:lootResult', function(success, bagId, weaponCount, errorMsg)
    isLooting = false

    if not success then
        notify('~r~' .. tostring(errorMsg or 'Impossible de looter ce sac.'))
        return
    end

    if weaponCount and weaponCount > 0 then
        notify('~g~' .. weaponCount .. ' arme(s) recuperee(s) !')
    end
end)

-- ============================================
-- Collecte des armes a la mort
-- ============================================

local function collectAndSendWeapons()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('lootbag:playerDied', {
        x = coords.x, y = coords.y, z = coords.z
    })
    print('[LootBag] Signale la mort au serveur (inventaire virtuel).')
end

-- ============================================
-- Thread : detection de mort
-- ============================================

local isDead       = false
local deathHandled = false

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        local dead = IsEntityDead(ped) or IsPedFatallyInjured(ped)

        if dead then
            if not deathHandled then
                deathHandled = true
                isDead       = true
                collectAndSendWeapons()
            end
        else
            if isDead then
                isDead       = false
                deathHandled = false
            end
        end
    end
end)

-- ============================================
-- Thread principal : affichage + interaction
-- ============================================

CreateThread(function()
    while true do

        if next(activeBags) == nil then
            Wait(500)
        else
            Wait(0)

            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearestBag   = nil
            local nearestDist  = Config.InteractDistance

            for bagId, bag in pairs(activeBags) do
                local bx = bag.coords.x
                local by = bag.coords.y
                local bz = bag.coords.z

                local elapsed   = (GetGameTimer() - bag.spawnTime) / 1000
                local remaining = math.max(0, Config.BagLifetime - math.floor(elapsed))

                drawMarker(bx, by, bz)
                drawText3D(bx, by, bz + Config.TextOffset, '~y~[LOOT] ~r~' .. remaining .. 's')

                local dist = #(playerCoords - bag.coords)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestBag  = bagId
                end
            end

            if nearestBag and activeBags[nearestBag] then
                local nb = activeBags[nearestBag]
                drawText3D(
                    nb.coords.x,
                    nb.coords.y,
                    nb.coords.z + Config.TextOffset + 0.3,
                    '~g~[E] ~w~Recuperer le sac'
                )

                if IsControlJustReleased(0, 38) and not isLooting then
                    isLooting = true
                    TriggerServerEvent('lootbag:lootBag', nearestBag)
                    -- Securite : debloquer isLooting si le serveur ne repond pas
                    CreateThread(function()
                        Wait(5000)
                        isLooting = false
                    end)
                end
            end
        end

    end
end)
