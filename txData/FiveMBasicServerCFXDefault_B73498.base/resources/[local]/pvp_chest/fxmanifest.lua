fx_version 'cerulean'
game 'gta5'

name        'pvp_chest'
description 'Coffre personnel armes — Standalone + oxmysql'
version     '2.0.0'
author      'Vous'

shared_scripts { 'config.lua' }
client_scripts { 'client.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/img/Weapons/*.png',
    'html/img/Weapons/*.jpg',
    'html/img/Weapons/*.jpeg'
}
