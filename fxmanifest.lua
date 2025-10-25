fx_version 'cerulean'
game 'gta5'

author 'ART'
description 'Sistema de Caixa de Som Integrado com youtube'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html'
    -- 'html/style.css',
    -- 'html/script.js'
}

dependencies {
    'xsound' -- Necessário para audio 3D
}
