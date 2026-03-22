-- ============================================================
--  PVP CHEST — Configuration
-- ============================================================
Config = {}

Config.Radius = 3.0

Config.Locations = {
    { x = 216.77,  y = -1388.40, z = 30.59 },
    { x = 1137.49, y = -1497.35, z = 34.84 },
}

-- Liste des armes (identique à pvp_inv)
Config.Weapons = {
    [GetHashKey("weapon_pistol")]            = { name = "Pistolet",            cat = "Pistolets" },
    [GetHashKey("weapon_pistol_mk2")]        = { name = "Pistolet MK2",        cat = "Pistolets" },
    [GetHashKey("weapon_combatpistol")]      = { name = "Pistolet Combat",     cat = "Pistolets" },
    [GetHashKey("weapon_appistol")]          = { name = "Pistolet AP",         cat = "Pistolets" },
    [GetHashKey("weapon_heavypistol")]       = { name = "Pistolet Lourd",      cat = "Pistolets" },
    [GetHashKey("weapon_snspistol")]         = { name = "Pistolet SNS",        cat = "Pistolets" },
    [GetHashKey("weapon_microsmg")]          = { name = "Micro SMG",           cat = "SMG" },
    [GetHashKey("weapon_smg")]               = { name = "SMG",                 cat = "SMG" },
    [GetHashKey("weapon_smg_mk2")]           = { name = "SMG MK2",             cat = "SMG" },
    [GetHashKey("weapon_assaultsmg")]        = { name = "SMG Assault",         cat = "SMG" },
    [GetHashKey("weapon_combatpdw")]         = { name = "PDW Combat",          cat = "SMG" },
    [GetHashKey("weapon_assaultrifle")]      = { name = "Fusil d'assaut",      cat = "Fusils" },
    [GetHashKey("weapon_assaultrifle_mk2")]  = { name = "Fusil d'assaut MK2",  cat = "Fusils" },
    [GetHashKey("weapon_carbinerifle")]      = { name = "Carabine",            cat = "Fusils" },
    [GetHashKey("weapon_carbinerifle_mk2")]  = { name = "Carabine MK2",        cat = "Fusils" },
    [GetHashKey("weapon_advancedrifle")]     = { name = "Fusil Avancé",        cat = "Fusils" },
    [GetHashKey("weapon_specialcarbine")]    = { name = "Carabine Spéciale",   cat = "Fusils" },
    [GetHashKey("weapon_bullpuprifle")]      = { name = "Bullpup Rifle",       cat = "Fusils" },
    [GetHashKey("weapon_sniperrifle")]       = { name = "Sniper",              cat = "Snipers" },
    [GetHashKey("weapon_heavysniper")]       = { name = "Sniper Lourd",        cat = "Snipers" },
    [GetHashKey("weapon_heavysniper_mk2")]   = { name = "Sniper Lourd MK2",    cat = "Snipers" },
    [GetHashKey("weapon_marksmanrifle")]     = { name = "Fusil Précision",     cat = "Snipers" },
    [GetHashKey("weapon_pumpshotgun")]       = { name = "Shotgun Pompe",       cat = "Shotguns" },
    [GetHashKey("weapon_sawnoffshotgun")]    = { name = "Shotgun Scié",        cat = "Shotguns" },
    [GetHashKey("weapon_assaultshotgun")]    = { name = "Shotgun Assault",     cat = "Shotguns" },
    [GetHashKey("weapon_bullpupshotgun")]    = { name = "Shotgun Bullpup",     cat = "Shotguns" },
    [GetHashKey("weapon_heavyshotgun")]      = { name = "Shotgun Lourd",       cat = "Shotguns" },
    [GetHashKey("weapon_grenadelauncher")]   = { name = "Lance-grenades",      cat = "Lourdes" },
    [GetHashKey("weapon_rpg")]               = { name = "RPG",                 cat = "Lourdes" },
    [GetHashKey("weapon_minigun")]           = { name = "Minigun",             cat = "Lourdes" },
    [GetHashKey("weapon_grenade")]           = { name = "Grenade",             cat = "Explosifs" },
    [GetHashKey("weapon_smokegrenade")]      = { name = "Grenade Fumigène",    cat = "Explosifs" },
    [GetHashKey("weapon_molotov")]           = { name = "Molotov",             cat = "Explosifs" },
    [GetHashKey("weapon_knife")]             = { name = "Couteau",             cat = "Mêlée" },
    [GetHashKey("weapon_bat")]               = { name = "Batte",               cat = "Mêlée" },
    [GetHashKey("weapon_knuckle")]           = { name = "Coup de Poing",       cat = "Mêlée" },
}
