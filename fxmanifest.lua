fx_version 'cerulean'
lua54 'yes'
game 'gta5'
author 'LFScripts, Laugh'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'client/*.lua'
}

server_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'server/*.lua'
}
