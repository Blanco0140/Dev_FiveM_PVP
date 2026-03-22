Config = {}

-- Modèle du Pnj Marchand
Config.PedModel = "u_m_y_mani"

Config.WeaponsBuy = {
    { hash = "weapon_pistol",          name = "Pistolet",           price = 500 },
    { hash = "weapon_combatpistol",    name = "Pistolet Combat",    price = 800 },
    { hash = "weapon_heavypistol",     name = "Pistolet Lourd",     price = 1200 },
    { hash = "weapon_microsmg",        name = "Micro SMG",          price = 1500 },
    { hash = "weapon_smg",             name = "SMG",                price = 2500 },
    { hash = "weapon_assaultrifle",    name = "Fusil d'assaut",     price = 4000 },
    { hash = "weapon_carbinerifle",    name = "Carabine",           price = 5000 },
    { hash = "weapon_advancedrifle",   name = "Fusil Avancé",       price = 6500 },
    { hash = "weapon_pumpshotgun",     name = "Shotgun Pompe",      price = 3500 },
    { hash = "weapon_sniperrifle",     name = "Sniper",             price = 8000 },
    { hash = "weapon_heavysniper",     name = "Sniper Lourd",       price = 15000 },
    { hash = "weapon_rpg",             name = "RPG",                price = 25000 },
}

Config.WeaponsSellValues = {
    [GetHashKey("weapon_pistol")]          = 100,
    [GetHashKey("weapon_combatpistol")]    = 150,
    [GetHashKey("weapon_heavypistol")]     = 250,
    [GetHashKey("weapon_microsmg")]        = 300,
    [GetHashKey("weapon_smg")]             = 500,
    [GetHashKey("weapon_assaultrifle")]    = 800,
    [GetHashKey("weapon_carbinerifle")]    = 1000,
    [GetHashKey("weapon_advancedrifle")]   = 1300,
    [GetHashKey("weapon_pumpshotgun")]     = 700,
    [GetHashKey("weapon_sniperrifle")]     = 1500,
    [GetHashKey("weapon_heavysniper")]     = 3000,
    [GetHashKey("weapon_rpg")]             = 5000,
}

-- Valeur par défaut pour une arme qu'on vend mais qui n'est pas listée ci-dessus
Config.DefaultSellValue = 50

-- La commande admin pour ajouter / enlever un marché
Config.AdminCommandAdd = "marketadd"
Config.AdminCommandRemove = "marketremove"
