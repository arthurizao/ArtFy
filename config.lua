Config = {}

-- Modelo da caixa de som
Config.BoomboxModel = 'prop_boombox_01'

-- Distância máxima do audio 
Config.MaxDistance = 10.0

-- Volume padrão (0.0 a 1.0)
Config.DefaultVolume = 0.5

-- Preço da caixa de som (se quiser sistema de compra)
Config.BoomboxPrice = 500

-- Distância para interação
Config.InteractionDistance = 2.0

-- Animações
Config.Animations = {
    carry = {
        dict = 'move_weapon@jerrycan@generic',
        anim = 'idle',
        flag = 51,  
        bone = 57005,
        offsetX = 0.27,
        offsetY = 0.0,
        offsetZ = 0.0,
        rotX = 0.0,
        rotY = 263.0,
        rotZ = 58.0
    },
    place = {
        dict = 'pickup_object',
        anim = 'pickup_low',
        flag = 48
    }
}


-- Permitir uso em veículos
Config.AllowInVehicles = true

-- Sistema de playlists
Config.EnablePlaylists = true

-- Códigos de compartilhamento (6 caracteres aleatórios)
Config.ShareCodeLength = 6

-- CONFIGURAÇÕES DA INTERFACE 
Config.UI = {
    -- Título do app
    Title = 'ArtFy',
    
    -- Descrição
    Description = 'Suas Músicas e playlists',

    -- Logo = 'https://i.ibb.co/WvcH68MD/a.png',  -- URL da imagem (se não for usar deixe comentado)
    
    -- Cor principal (hex sem #)
    PrimaryColor = '1E90FF',
    
    -- Exemplos de cores:
    -- Verde: 1DB954
    -- Azul: 1E90FF
    -- Roxo: 9146FF
    -- Rosa: FF1493
    -- Laranja: FF6B35
    -- Vermelho: E63946
}
