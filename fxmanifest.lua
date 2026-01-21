fx_version 'cerulean'
game 'gta5'

author 'Raytrix Scripts'
description 'Een aanpasbare spelerdoel-systeem voor FiveM-servers, waarmee beheerders doelen kunnen instellen die spelers kunnen bereiken voor beloningen.'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@oxmysql/lib/MySQL.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'images/*.png'
}

dependencies {
    'es_extended',
    'oxmysql'
}
