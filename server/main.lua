local activeBoomboxes = {}
local playlists = {}
local playerBoomboxes = {} -- Rastrear qual boombox pertence a cada jogador


-- Função para salvar dados em JSON
function SaveBoomboxData()
    local file = io.open('resources/art_sound/boomboxes.json', 'w')
    if file then
        file:write(json.encode(activeBoomboxes, {indent = true}))
        file:close()
    end
end


-- Função para carregar dados do JSON
function LoadBoomboxData()
    local file = io.open('resources/art_sound/boomboxes.json', 'r')
    if file then
        local content = file:read('*a')
        file:close()
        if content and content ~= '' then
            activeBoomboxes = json.decode(content) or {}
        end
    end
end


-- Carregar dados ao iniciar o resource
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadBoomboxData()
        print('[Boombox] Dados carregados do JSON')
    end
end)


-- Salvar dados ao parar o resource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SaveBoomboxData()
        print('[Boombox] Dados salvos no JSON')
    end
end)


-- Gerar código aleatório para playlist
function GenerateShareCode()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local code = ''
    for i = 1, Config.ShareCodeLength do
        local rand = math.random(1, #chars)
        code = code .. chars:sub(rand, rand)
    end
    return code
end


-- Spawnar caixa de som
RegisterNetEvent('boombox:server:spawn', function(coords, heading)
    local src = source
    
    -- Verificar se já tem boombox
    if playerBoomboxes[src] then
        local oldId = playerBoomboxes[src]
        if activeBoomboxes[tostring(oldId)] then
            local oldBoombox = activeBoomboxes[tostring(oldId)]
            
            -- Se estava carregando e tocando, NÃO destruir o som
            if not oldBoombox.isCarried then
                -- Deletar antiga (não estava carregando)
                exports.xsound:Destroy(-1, 'boombox_' .. oldId)
                TriggerClientEvent('boombox:client:delete', -1, oldId)
            end
            
            activeBoomboxes[tostring(oldId)] = nil
        end
    end
    
    -- Criar nova boombox com ID = source do jogador
    local boomboxId = src
    
    activeBoomboxes[tostring(boomboxId)] = {
        id = boomboxId,
        owner = src,
        ownerName = GetPlayerName(src),
        coords = coords,
        heading = heading,
        currentUrl = nil,
        volume = Config.DefaultVolume,
        playing = false,
        inVehicle = false,
        vehicle = nil,
        isCarried = false,
        createdAt = os.time()
    }
    
    playerBoomboxes[src] = boomboxId
    SaveBoomboxData()
    
    TriggerClientEvent('boombox:client:spawn', -1, boomboxId, src, coords, heading)
    print('[Boombox] Caixa ' .. boomboxId .. ' criada para ' .. GetPlayerName(src))
end)


-- Spawnar em veículo
RegisterNetEvent('boombox:server:spawnInVehicle', function(vehicle)
    local src = source
    
    -- Verificar se já tem boombox
    if playerBoomboxes[src] then
        local oldId = playerBoomboxes[src]
        if activeBoomboxes[tostring(oldId)] then
            -- Deletar antiga
            exports.xsound:Destroy(-1, 'boombox_' .. oldId)
            TriggerClientEvent('boombox:client:delete', -1, oldId)
            activeBoomboxes[tostring(oldId)] = nil
        end
    end
    
    local boomboxId = src
    
    activeBoomboxes[tostring(boomboxId)] = {
        id = boomboxId,
        owner = src,
        ownerName = GetPlayerName(src),
        currentUrl = nil,
        volume = Config.DefaultVolume,
        playing = false,
        inVehicle = true,
        vehicle = vehicle,
        createdAt = os.time()
    }
    
    playerBoomboxes[src] = boomboxId
    SaveBoomboxData()
    
    TriggerClientEvent('boombox:client:spawnInVehicle', -1, boomboxId, src, vehicle)
    print('[Boombox] Caixa ' .. boomboxId .. ' criada no veículo para ' .. GetPlayerName(src))
end)


-- Pegar caixa de som (deleta)
RegisterNetEvent('boombox:server:pickup', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        -- Parar música
        if activeBoomboxes[boomboxKey].playing then
            exports.xsound:Destroy(-1, 'boombox_' .. boomboxId)
        end
        
        -- Deletar
        TriggerClientEvent('boombox:client:pickupDelete', -1, boomboxId)
        activeBoomboxes[boomboxKey] = nil
        playerBoomboxes[src] = nil
        SaveBoomboxData()
        
        print('[Boombox] Caixa ' .. boomboxId .. ' pegada e deletada')
    end
end)


-- Deletar caixa de som permanentemente
RegisterNetEvent('boombox:server:delete', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        if activeBoomboxes[boomboxKey].playing then
            exports.xsound:Destroy(-1, 'boombox_' .. boomboxId)
        end
        
        TriggerClientEvent('boombox:client:delete', -1, boomboxId)
        activeBoomboxes[boomboxKey] = nil
        playerBoomboxes[src] = nil
        SaveBoomboxData()
        
        print('[Boombox] Caixa ' .. boomboxId .. ' deletada (distância)')
    end
end)


-- Tocar música
RegisterNetEvent('boombox:server:playWithDuration')
AddEventHandler('boombox:server:playWithDuration', function(boomboxId, url, duration)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        local boombox = activeBoomboxes[boomboxKey]
        
        if boombox.playing then
            exports.xsound:Destroy(-1, 'boombox_' .. boomboxId)
        end
        
        boombox.currentUrl = url
        boombox.playing = true
        SaveBoomboxData()
        
        if boombox.inVehicle then
            TriggerClientEvent('boombox:client:playInVehicle', -1, boomboxId, url, boombox.volume)
        else
            exports.xsound:PlayUrlPos(-1, 'boombox_' .. boomboxId, url, boombox.volume, boombox.coords, false)
            exports.xsound:Distance(-1, 'boombox_' .. boomboxId, Config.MaxDistance)
        end
        
        TriggerClientEvent('boombox:client:updateStatus', -1, boomboxId, true, url)
        print('[Boombox] Tocando música no boombox ' .. boomboxId)
    end
end)


-- Pausar música
RegisterNetEvent('boombox:server:pause', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        exports.xsound:Pause(-1, 'boombox_' .. boomboxId)
        activeBoomboxes[boomboxKey].playing = false
        SaveBoomboxData()
        TriggerClientEvent('boombox:client:updateStatus', -1, boomboxId, false, activeBoomboxes[boomboxKey].currentUrl)
    end
end)


-- Retomar música
RegisterNetEvent('boombox:server:resume', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        exports.xsound:Resume(-1, 'boombox_' .. boomboxId)
        activeBoomboxes[boomboxKey].playing = true
        SaveBoomboxData()
        TriggerClientEvent('boombox:client:updateStatus', -1, boomboxId, true, activeBoomboxes[boomboxKey].currentUrl)
    end
end)


-- Parar música
RegisterNetEvent('boombox:server:stop', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        exports.xsound:Destroy(-1, 'boombox_' .. boomboxId)
        activeBoomboxes[boomboxKey].playing = false
        activeBoomboxes[boomboxKey].currentUrl = nil
        SaveBoomboxData()
        TriggerClientEvent('boombox:client:updateStatus', -1, boomboxId, false, nil)
    end
end)


-- Ajustar volume
RegisterNetEvent('boombox:server:setVolume', function(boomboxId, volume)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        activeBoomboxes[boomboxKey].volume = volume
        SaveBoomboxData()
        exports.xsound:setVolume(-1, 'boombox_' .. boomboxId, volume)
    end
end)


-- Salvar playlist
RegisterNetEvent('boombox:server:savePlaylist', function(playlistData)
    local code = GenerateShareCode()
    playlists[code] = playlistData
    TriggerClientEvent('boombox:client:shareCode', source, code)
end)


-- Carregar playlist
RegisterNetEvent('boombox:server:loadPlaylist', function(code)
    local src = source
    if playlists[code] then
        TriggerClientEvent('boombox:client:loadedPlaylist', src, playlists[code])
    else
        TriggerClientEvent('boombox:client:notify', src, 'Código de playlist inválido!')
    end
end)


-- Atualizar posição (veículo ou CARREGADA)
CreateThread(function()
    while true do
        Wait(500)
        for id, boombox in pairs(activeBoomboxes) do
            if boombox.playing then
                if boombox.inVehicle then
                    TriggerClientEvent('boombox:client:updateVehiclePosition', -1, tonumber(id))
                elseif boombox.isCarried then
                    -- ADICIONAR: Atualizar posição da boombox carregada
                    TriggerClientEvent('boombox:client:updateCarriedPosition', -1, tonumber(id), boombox.owner)
                end
            end
        end
    end
end)



-- Salvar automaticamente a cada 5 minutos
CreateThread(function()
    while true do
        Wait(300000)
        SaveBoomboxData()
        print('[Boombox] Dados salvos automaticamente')
    end
end)


-- Limpar boombox quando jogador desconectar
AddEventHandler('playerDropped', function(reason)
    local src = source
    local boomboxId = playerBoomboxes[src]
    
    if boomboxId then
        local boomboxKey = tostring(boomboxId)
        if activeBoomboxes[boomboxKey] then
            exports.xsound:Destroy(-1, 'boombox_' .. boomboxId)
            TriggerClientEvent('boombox:client:delete', -1, boomboxId)
            activeBoomboxes[boomboxKey] = nil
        end
        playerBoomboxes[src] = nil
        print('[Boombox] Caixa ' .. boomboxId .. ' deletada (player desconectou)')
    end
end)


-- Pegar e carregar (música continua tocando)
RegisterNetEvent('boombox:server:pickupCarry', function(boomboxId)
    local src = source
    local boomboxKey = tostring(boomboxId)
    
    if activeBoomboxes[boomboxKey] and activeBoomboxes[boomboxKey].owner == src then
        local boombox = activeBoomboxes[boomboxKey]
        
        -- NÃO parar música, só marcar como "carregada"
        boombox.isCarried = true
        boombox.coords = nil -- Remover coordenadas fixas
        SaveBoomboxData()
        
        -- Avisar todos pra deletar o objeto visual
        TriggerClientEvent('boombox:client:pickupDelete', -1, boomboxId)
        
        -- Avisar o dono pra carregar
        TriggerClientEvent('boombox:client:carryBoombox', src, boomboxId)
        
        print('[Boombox] Caixa ' .. boomboxId .. ' sendo carregada (música continua)')
    end
end)


