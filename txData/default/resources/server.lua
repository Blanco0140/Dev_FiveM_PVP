-- Ce code s'exécute côté serveur (pour la sécurité et la base de données)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local player = source
    local identifier = nil

    -- On cherche la licence Rockstar du joueur (son identifiant unique)
    for k, v in ipairs(GetPlayerIdentifiers(player)) do
        if string.match(v, 'license:') then
            identifier = v
            break
        end
    end

    if identifier then
        -- On interroge la base de données pour voir s'il y est déjà
        local exist = MySQL.query.await('SELECT identifier FROM users WHERE identifier = ?', {identifier})
        
        -- S'il n'y est pas (c'est sa toute première connexion au serveur)
        if not exist[1] then
            -- On l'ajoute ! L'argent et l'XP se mettent à 0 automatiquement
            MySQL.insert.await('INSERT INTO users (identifier) VALUES (?)', {identifier})
            print('^2[PVP] Nouveau joueur enregistre en base de donnees : ' .. name .. '^7')
        else
            -- S'il existe déjà
            print('^4[PVP] Connexion d un joueur connu : ' .. name .. '^7')
        end
    else
        print('^1[PVP] Erreur : Impossible de trouver la licence Rockstar du joueur ' .. name .. '^7')
    end
end)
