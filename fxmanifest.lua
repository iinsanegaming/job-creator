fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'iiNSANE Gaming - Job & Gang Creator'
description 'Job and Gang Creator + Boss Menu + Gang Menu for RedM RSG-Core'
version '2.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
}

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua',
    'client/bossmenu.lua',
    'client/gangmenu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/bossmenu.lua',
    'server/gangmenu.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'rsg-core',
    'ox_lib',
    'oxmysql',
    'rsg-inventory',
}
