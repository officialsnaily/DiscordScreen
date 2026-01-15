fx_version 'cerulean'
game 'gta5'

author 'Team Snaily, Anton\'s workshop'
description 'Send screenshots to Discord with player info (Secure Server Upload)'
version '1.1.0'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua',
    'server_upload.js'
}

shared_script 'config.lua'

dependency 'screenshot-basic'
