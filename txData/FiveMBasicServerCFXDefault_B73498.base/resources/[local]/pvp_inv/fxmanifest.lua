fx_version 'cerulean'
game 'gta5'

author 'PVP Server'
description 'Inventaire PVP - Style Extinction'
version '3.0.0'

client_scripts { 'client/main.lua' }
server_scripts { 
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua' 
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
