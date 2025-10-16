fx_version 'cerulean'
game 'gta5'

author 'NorthEast Development'
description 'Fingerprint Scanner (Tablet UI) - ESX / ND_Core / Standalone'
version '3.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/scan.mp3',
    'html/sounds/match.mp3'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}
