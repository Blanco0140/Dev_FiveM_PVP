Config = {}

-- Durée du sac sur la map en secondes
Config.BagLifetime = 60

-- Distance pour interagir avec le sac (en unités)
Config.InteractDistance = 1.5

-- Modèle du sac (prop)
Config.BagModel = 'prop_ld_dl_bag_01' -- Sac de sport duffel (loot bag FiveM)

-- Activer les notifications
Config.Notifications = true

-- Couleur du marker (RGBA)
Config.MarkerColor = { r = 255, g = 165, b = 0, a = 180 }

-- Hauteur du texte 3D (bas, juste au-dessus du sol)
Config.TextOffset = 0.15

-- Afficher le marker orange (false = désactivé)
Config.ShowMarker = false

-- Weapons à exclure du loot (le joueur les garde toujours)
Config.ExcludedWeapons = {
    -- 'WEAPON_UNARMED', -- Poings
}

-- Si true, les armes tombées incluent les munitions restantes
Config.IncludeAmmo = true
