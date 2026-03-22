Config = {}

-- Modèle du Pnj Marchand
Config.PedModel = "u_m_y_mani"

Config.WeaponsBuy = {
    { hash = "weapon_appistol",        name = "Pistolet AP",        price = 700 },
    { hash = "weapon_heavypistol",     name = "Pistolet Lourd",     price = 1000 },
    { hash = "weapon_pistol50",        name = "Pistolet .50",       price = 1200 },
    { hash = "weapon_snspistol",       name = "Pistolet SNS",       price = 600 },
    { hash = "weapon_machinepistol",   name = "Machine Pistol",     price = 1500 },
    { hash = "weapon_marksmanpistol",  name = "Marksman Pistol",    price = 1800 },
    { hash = "weapon_microsmg",        name = "Micro SMG",          price = 2000 },
    { hash = "weapon_minismg",         name = "Mini SMG",           price = 2200 },
    { hash = "weapon_smg",             name = "SMG",                price = 2500 },
    { hash = "weapon_smg_mk2",         name = "SMG MK2",            price = 3500 },
    { hash = "weapon_combatpdw",       name = "PDW Combat",         price = 2800 },
    { hash = "weapon_assaultrifle",    name = "Fusil d'assaut",     price = 4500 },
    { hash = "weapon_compactrifle",    name = "Fusil Compact",      price = 4000 },
    { hash = "weapon_specialcarbine",  name = "Carabine Spéciale",  price = 6000 },
    { hash = "weapon_tacticalrifle",   name = "Fusil Tactique",     price = 6500 },
    { hash = "weapon_combatmg",        name = "Combat MG",          price = 8000 },
    { hash = "weapon_sawnoffshotgun",  name = "Shotgun Scié",       price = 3000 },
}

Config.WeaponsSellValues = {
    [GetHashKey("weapon_appistol")]         = 200,
    [GetHashKey("weapon_heavypistol")]      = 300,
    [GetHashKey("weapon_pistol50")]         = 400,
    [GetHashKey("weapon_snspistol")]        = 150,
    [GetHashKey("weapon_machinepistol")]    = 500,
    [GetHashKey("weapon_marksmanpistol")]   = 600,
    [GetHashKey("weapon_microsmg")]         = 650,
    [GetHashKey("weapon_minismg")]          = 700,
    [GetHashKey("weapon_smg")]              = 800,
    [GetHashKey("weapon_smg_mk2")]          = 1100,
    [GetHashKey("weapon_combatpdw")]        = 900,
    [GetHashKey("weapon_assaultrifle")]     = 1500,
    [GetHashKey("weapon_compactrifle")]     = 1300,
    [GetHashKey("weapon_specialcarbine")]   = 2000,
    [GetHashKey("weapon_tacticalrifle")]    = 2100,
    [GetHashKey("weapon_combatmg")]         = 2500,
    [GetHashKey("weapon_sawnoffshotgun")]   = 1000,
}

-- Valeur par défaut pour une arme qu'on vend mais qui n'est pas listée ci-dessus
Config.DefaultSellValue = 50

-- La commande admin pour ajouter / enlever un marché
Config.AdminCommandAdd = "marketadd"
Config.AdminCommandRemove = "marketremove"
