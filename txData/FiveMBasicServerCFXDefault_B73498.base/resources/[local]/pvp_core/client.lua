-- ==============================================
-- CLIENT.LUA - Le coeur du PVP
-- Ce fichier tourne sur le PC de chaque joueur
-- ==============================================

-- Désactive le respawn automatique de spawnmanager (sinon il re-TP le joueur)
Citizen.CreateThread(function()
    exports.spawnmanager:setAutoSpawn(false)
end)

-- Quand le joueur apparaît pour la première fois, on lui donne un pistolet
AddEventHandler('playerSpawned', function()
    Citizen.Wait(1000)
    GiveWeaponToPed(PlayerPedId(), GetHashKey('WEAPON_PISTOL'), 250, false, true)
end)



-- ==============================================
-- 1. HEADSHOT = MORT INSTANTANEE + PVP ACTIF
-- ==============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        
        -- ACTIVE LE PVP : permet aux joueurs de se tirer dessus
        NetworkSetFriendlyFireOption(true)
        SetCanAttackFriendly(ped, true, false)

        -- Active les dégâts critiques sur notre personnage
        SetPedSuffersCriticalHits(ped, true)
        
        -- Désactive la régénération automatique de la vie
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    end
end)

-- Ce code écoute les "événements de dégâts" du jeu
-- Quand quelqu'un nous tire dessus, on vérifie si la balle a touché la tête
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        
        -- On vérifie que c'est NOUS qui avons pris la balle
        if victim == PlayerPedId() then
            -- On demande au jeu quel os du corps a été touché
            local boneHit, bone = GetPedLastDamageBone(victim)
            
            -- 31086 = c'est le numéro de l'os de la tête dans GTA (SKEL_Head)
            if bone == 31086 then
                -- Balle dans la tête = 0 points de vie = MORT
                SetEntityHealth(victim, 0)
            end
        end
    end
end)


-- ==============================================
-- 2. RESPAWN INSTANTANE (pas d'écran noir)
-- ==============================================

-- Liste de points de spawn aléatoires dans Los Santos
-- Le joueur réapparaîtra à un de ces endroits au hasard
local spawnPoints = {
    {x = -1037.0, y = -2736.0, z = 20.0},   -- Aéroport
    {x = 215.0,   y = -932.0,  z = 30.7},   -- Centre-ville
    {x = -547.0,  y = -204.0,  z = 38.2},    -- Près du Maze Bank
    {x = 802.0,   y = -1024.0, z = 26.3},    -- Mission Row
    {x = -1205.0, y = -1560.0, z = 4.6},     -- Plage de Santa Monica
}

-- Ce code surveille si le joueur est mort
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        
        if IsEntityDead(ped) then
            -- Détecte qui nous a tué
            local killer = GetPedSourceOfDeath(ped)
            local killerId = 0
            
            if killer and DoesEntityExist(killer) then
                if IsPedAPlayer(killer) then
                    killerId = NetworkGetPlayerIndexFromPed(killer)
                    if killerId then
                        killerId = GetPlayerServerId(killerId)
                    else
                        killerId = 0
                    end
                end
            end
            
            -- Envoie l'événement au serveur pour tracker les stats
            TriggerServerEvent('pvp_core:playerKilled', killerId)
            
            -- On attend 2 secondes pour que le joueur voie qu'il est mort
            Citizen.Wait(2000)
            
            -- Cherche la safezone la plus proche
            local deathCoords = GetEntityCoords(ped)
            local spawnX, spawnY, spawnZ, spawnHeading
            
            local success, nearestZone = pcall(function()
                return exports['pvp_safezone']:GetNearestSafezone(deathCoords)
            end)
            
            if success and nearestZone then
                -- Respawn à la safezone la plus proche avec la bonne direction
                spawnX = nearestZone.x
                spawnY = nearestZone.y
                spawnZ = nearestZone.z
                spawnHeading = nearestZone.heading or 0.0
            else
                -- Fallback : spawn aléatoire si aucune safezone
                local spawn = spawnPoints[math.random(#spawnPoints)]
                spawnX = spawn.x
                spawnY = spawn.y
                spawnZ = spawn.z
                spawnHeading = 0.0
            end
            
            -- On fait réapparaître le joueur dans la bonne direction
            NetworkResurrectLocalPlayer(spawnX, spawnY, spawnZ, spawnHeading, true, false)
            
            -- On remet la vie au maximum
            SetEntityHealth(PlayerPedId(), 200)
            
            -- On nettoie le sang sur le personnage
            ClearPedBloodDamage(PlayerPedId())
            
            -- On s'assure que le joueur n'est PAS invincible après un respawn (la safezone le remettra)
            SetPlayerInvincible(PlayerId(), false)
            
            -- On donne un pistolet temporaire pour pouvoir se battre
            GiveWeaponToPed(PlayerPedId(), GetHashKey('WEAPON_PISTOL'), 250, false, true)
            
            -- Petite pause pour éviter les bugs
            Citizen.Wait(500)
        end
    end
end)


-- ==============================================
-- 3. DESACTIVATION DE L'IA DE GTA
-- ==============================================

-- Supprime les voitures civiles et les piétons (PNJ)
-- Cela tourne à chaque image (frame) du jeu pour être efficace
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Pas de voitures civiles qui roulent
        SetVehicleDensityMultiplierThisFrame(0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        
        -- Pas de voitures garées sur le trottoir
        SetParkedVehicleDensityMultiplierThisFrame(0.0)
        
        -- Pas de piétons (les gens qui marchent dans la rue)
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        
        -- Pas de camions poubelle, bateaux, trains
        SetGarbageTrucks(false)
        SetRandomBoats(false)
        SetRandomTrains(false)
    end
end)

-- Supprime la police, les ambulances, les pompiers
-- Et empêche d'avoir des "étoiles" (wanted level)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Vérifie chaque seconde (pas besoin de plus)
        
        -- Désactive les 12 types de services d'urgence (police, ambulance, pompiers, etc.)
        for i = 1, 12 do
            EnableDispatchService(i, false)
        end
        
        -- Supprime toutes les étoiles de recherche (wanted level = 0)
        SetMaxWantedLevel(0)
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        ClearPlayerWantedLevel(PlayerId())
    end
end)
