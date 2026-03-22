fx_version 'cerulean'
game 'gta5'

author 'Blanco & AI'
description 'Script principal du serveur PVP Headshot'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

export 'GetPlayerPoints'
export 'AddPlayerPoints'
export 'RemovePlayerPoints'

