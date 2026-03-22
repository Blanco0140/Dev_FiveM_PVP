fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'PVP Market - Achat et Vente darmes'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/Weapons/*.png',
    'html/img/Weapons/*.jpg',
    'html/img/Weapons/*.jpeg'
}
