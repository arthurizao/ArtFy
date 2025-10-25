local myBoomboxId = nil
local myBoomboxObject = nil
local activeBoomboxes = {}
local lastPosition = nil
local carryingBoombox = false  
local carriedBoomboxId = nil   



-- Carregar animações
function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

-- Notificação
function Notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

RegisterNetEvent('boombox:client:notify', function(msg)
    Notify(msg)
end)

-- Receber spawn do servidor
RegisterNetEvent('boombox:client:spawn', function(boomboxId, owner, coords, heading)
    if activeBoomboxes[boomboxId] then
        print('[Boombox] Caixa ' .. boomboxId .. ' já existe, ignorando...')
        return
    end

    local boombox = CreateObject(GetHashKey(Config.BoomboxModel), coords.x, coords.y, coords.z, true, false, false)
    SetEntityHeading(boombox, heading)
    PlaceObjectOnGroundProperly(boombox)
    FreezeEntityPosition(boombox, true)

    activeBoomboxes[boomboxId] = {
        object = boombox,
        owner = owner,
        coords = coords,
        playing = false,
        inVehicle = false
    }

    -- Se é minha boombox, guardar referência
    if owner == GetPlayerServerId(PlayerId()) then
        myBoomboxId = boomboxId
        myBoomboxObject = boombox
        lastPosition = coords
    end

    print('[Boombox] Caixa ' .. boomboxId .. ' criada')
end)

-- Receber spawn em veículo
RegisterNetEvent('boombox:client:spawnInVehicle', function(boomboxId, owner, vehicle)
    activeBoomboxes[boomboxId] = {
        owner = owner,
        playing = false,
        inVehicle = true,
        vehicle = NetToVeh(vehicle)
    }

    if owner == GetPlayerServerId(PlayerId()) then
        myBoomboxId = boomboxId
    end
end)

-- Deletar caixa permanentemente
RegisterNetEvent('boombox:client:delete', function(boomboxId)
    if activeBoomboxes[boomboxId] then
        if activeBoomboxes[boomboxId].object then
            DeleteObject(activeBoomboxes[boomboxId].object)
        end
        activeBoomboxes[boomboxId] = nil
    end

    if myBoomboxId == boomboxId then
        myBoomboxId = nil
        myBoomboxObject = nil
        lastPosition = nil
    end
end)

-- Atualizar status
RegisterNetEvent('boombox:client:updateStatus', function(boomboxId, playing, url)
    if activeBoomboxes[boomboxId] then
        activeBoomboxes[boomboxId].playing = playing
        activeBoomboxes[boomboxId].url = url
    end
end)

-- Tocar em veículo
RegisterNetEvent('boombox:client:playInVehicle', function(boomboxId, url, volume)
    if activeBoomboxes[boomboxId] and activeBoomboxes[boomboxId].inVehicle then
        local vehicle = activeBoomboxes[boomboxId].vehicle
        if DoesEntityExist(vehicle) then
            local coords = GetEntityCoords(vehicle)
            exports.xsound:PlayUrlPos('boombox_' .. boomboxId, url, volume, coords, false)
            exports.xsound:Distance('boombox_' .. boomboxId, Config.MaxDistance)
        end
    end
end)

-- Atualizar posição do veículo
RegisterNetEvent('boombox:client:updateVehiclePosition', function(boomboxId)
    if activeBoomboxes[boomboxId] and activeBoomboxes[boomboxId].inVehicle then
        local vehicle = activeBoomboxes[boomboxId].vehicle
        if DoesEntityExist(vehicle) then
            local coords = GetEntityCoords(vehicle)
            exports.xsound:Position('boombox_' .. boomboxId, coords)
        end
    end
end)

-- Recriar caixa no chão
RegisterNetEvent('boombox:client:recreateBoombox', function(boomboxId, coords, heading)
    if activeBoomboxes[boomboxId] and activeBoomboxes[boomboxId].object then
        DeleteObject(activeBoomboxes[boomboxId].object)
    end

    local boombox = CreateObject(GetHashKey(Config.BoomboxModel), coords.x, coords.y, coords.z, true, false, false)
    SetEntityHeading(boombox, heading)
    PlaceObjectOnGroundProperly(boombox)
    FreezeEntityPosition(boombox, true)

    if activeBoomboxes[boomboxId] then
        activeBoomboxes[boomboxId].object = boombox
        activeBoomboxes[boomboxId].coords = coords
    else
        activeBoomboxes[boomboxId] = {
            object = boombox,
            coords = coords,
            playing = false,
            inVehicle = false
        }
    end

    if myBoomboxId == boomboxId then
        myBoomboxObject = boombox
        lastPosition = coords
    end
end)

-- Comando /som 
RegisterCommand('som', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- Se está carregando boombox, colocar no chão automaticamente
    if carryingBoombox then
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local spawnCoords = vector3(coords.x + forward.x * 1.5, coords.y + forward.y * 1.5, coords.z)
        
        -- Deletar objeto na mão
        if myBoomboxObject then
            DeleteObject(myBoomboxObject)
            myBoomboxObject = nil
        end
        
        -- Criar no servidor
        TriggerServerEvent('boombox:server:spawn', spawnCoords, heading)
        
        -- Parar animação
        ClearPedTasks(playerPed)
        carryingBoombox = false
        carriedBoomboxId = nil
        
        Wait(500)
        if myBoomboxId then
            OpenBoomboxMenu(myBoomboxId)
        end
        
        return
    end
    
    -- Se está no veículo
    if vehicle ~= 0 then
        -- Se já tem boombox no carro, abrir menu
        if myBoomboxId and activeBoomboxes[myBoomboxId] and activeBoomboxes[myBoomboxId].inVehicle then
            OpenBoomboxMenu(myBoomboxId)
        else
            -- Criar boombox no carro
            TriggerServerEvent('boombox:server:spawnInVehicle', VehToNet(vehicle))
            Wait(500)
            if myBoomboxId then
                OpenBoomboxMenu(myBoomboxId)
            end
        end
    else
        -- Se está a pé
        if myBoomboxId and activeBoomboxes[myBoomboxId] and not activeBoomboxes[myBoomboxId].inVehicle then
            -- Já tem boombox no chão, só abrir menu
            OpenBoomboxMenu(myBoomboxId)
        else
            -- Criar boombox no chão
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            local spawnCoords = vector3(coords.x + forward.x * 1.5, coords.y + forward.y * 1.5, coords.z)
            
            TriggerServerEvent('boombox:server:spawn', spawnCoords, heading)
            Wait(500)
            if myBoomboxId then
                OpenBoomboxMenu(myBoomboxId)
            end
        end
    end
end)


-- Abrir menu NUI
function OpenBoomboxMenu(boomboxId)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        boomboxId = boomboxId,
        config = Config.UI 
    })
end

-- Thread de interação
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        -- Se está carregando boombox
        if carryingBoombox then
            DrawText3D(coords.x, coords.y, coords.z + 1.0, '[E] Colocar no Chão | [G] Guardar')
            
            if IsControlJustPressed(0, 38) then -- E - Colocar no chão
                local heading = GetEntityHeading(playerPed)
                local forward = GetEntityForwardVector(playerPed)
                local spawnCoords = vector3(coords.x + forward.x * 1.5, coords.y + forward.y * 1.5, coords.z)
                
                -- Deletar objeto na mão
                if myBoomboxObject then
                    DeleteObject(myBoomboxObject)
                    myBoomboxObject = nil
                end
                
                -- Criar no servidor
                TriggerServerEvent('boombox:server:spawn', spawnCoords, heading)
                
                -- Parar animação
                ClearPedTasks(playerPed)
                carryingBoombox = false
                carriedBoomboxId = nil
                
                Notify('Caixa de som colocada no chão!')
            end
            
            if IsControlJustPressed(0, 47) then -- G - Guardar
                TriggerServerEvent('boombox:server:delete', carriedBoomboxId)
                
                if myBoomboxObject then
                    DeleteObject(myBoomboxObject)
                    myBoomboxObject = nil
                end
                
                ClearPedTasks(playerPed)
                carryingBoombox = false
                carriedBoomboxId = nil
                
                Notify('Caixa de som guardada!')
            end
        else
            -- Verificar se tem boombox perto
            for id, boombox in pairs(activeBoomboxes) do
                if not boombox.inVehicle and boombox.object then
                    local dist = #(coords - boombox.coords)
                    
                    if dist < Config.InteractionDistance then
                        DrawText3D(boombox.coords.x, boombox.coords.y, boombox.coords.z + 0.5, '[H] Pegar Caixa')

                        if IsControlJustPressed(0, 74) then -- H - Pegar direto
                            if id == myBoomboxId then
                                TriggerServerEvent('boombox:server:pickupCarry', id)
                            else
                                Notify('Esta não é sua caixa de som!')
                            end
                        end
                    end
                end
            end
        end
    end
end)



-- Thread para deletar boombox se distanciar muito
CreateThread(function()
    while true do
        Wait(2000)
        
        if myBoomboxId and myBoomboxObject and lastPosition then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Só checar se não está no veículo
            if vehicle == 0 then
                local coords = GetEntityCoords(playerPed)
                local dist = #(coords - lastPosition)
                
                if dist > Config.MaxDistance then
                    print('[Boombox] Distância máxima atingida (' .. dist .. 'm), deletando...')
                    TriggerServerEvent('boombox:server:delete', myBoomboxId)
                end
            end
        end
    end
end)

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- Callbacks NUI
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


RegisterNUICallback('pickupCarry', function(data, cb)
    TriggerServerEvent('boombox:server:pickupCarry', data.boomboxId)
    cb('ok')
end)

RegisterNUICallback('pickupStore', function(data, cb)
    TriggerServerEvent('boombox:server:pickupStore', data.boomboxId)
    cb('ok')
end)

RegisterNUICallback('cancelPickup', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


RegisterNUICallback('play', function(data, cb)
    local url = data.url
    local duration = data.duration or 240
    
    TriggerServerEvent('boombox:server:playWithDuration', myBoomboxId, url, duration)
    cb('ok')
end)

RegisterNUICallback('pause', function(data, cb)
    TriggerServerEvent('boombox:server:pause', myBoomboxId)
    cb('ok')
end)

RegisterNUICallback('resume', function(data, cb)
    TriggerServerEvent('boombox:server:resume', myBoomboxId)
    cb('ok')
end)

RegisterNUICallback('stop', function(data, cb)
    TriggerServerEvent('boombox:server:stop', myBoomboxId)
    cb('ok')
end)

RegisterNUICallback('volume', function(data, cb)
    TriggerServerEvent('boombox:server:setVolume', myBoomboxId, data.volume)
    cb('ok')
end)

RegisterNUICallback('savePlaylist', function(data, cb)
    TriggerServerEvent('boombox:server:savePlaylist', data.playlist)
    cb('ok')
end)

RegisterNUICallback('loadPlaylist', function(data, cb)
    TriggerServerEvent('boombox:server:loadPlaylist', data.code)
    cb('ok')
end)

-- Receber código de compartilhamento
RegisterNetEvent('boombox:client:shareCode', function(code)
    SendNUIMessage({
        action = 'shareCode',
        code = code
    })
end)

-- Receber playlist carregada
RegisterNetEvent('boombox:client:loadedPlaylist', function(playlist)
    SendNUIMessage({
        action = 'loadedPlaylist',
        playlist = playlist
    })
end)

-- Quando pegar a boombox
RegisterNetEvent('boombox:client:pickupDelete', function(boomboxId)
    if activeBoomboxes[boomboxId] and activeBoomboxes[boomboxId].object then
        DeleteObject(activeBoomboxes[boomboxId].object)
        activeBoomboxes[boomboxId] = nil
    end
    
    myBoomboxId = nil
    myBoomboxObject = nil
    lastPosition = nil
    
    Notify('Caixa de som guardada!')
end)


-- Receber opção de pegar
RegisterNetEvent('boombox:client:showPickupMenu', function(boomboxId)
    -- Abrir menu NUI de escolha
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showPickupChoice',
        boomboxId = boomboxId
    })
end)

-- Carregar boombox
RegisterNetEvent('boombox:client:carryBoombox', function(boomboxId)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Criar objeto na mão
    RequestModel(Config.BoomboxModel)
    while not HasModelLoaded(Config.BoomboxModel) do
        Wait(10)
    end
    
    myBoomboxObject = CreateObject(GetHashKey(Config.BoomboxModel), coords.x, coords.y, coords.z, false, true, true)
    
    -- Usar animação da config
    local anim = Config.Animations.carry
    LoadAnimDict(anim.dict)
    TaskPlayAnim(playerPed, anim.dict, anim.anim, 8.0, 8.0, -1, anim.flag, 0, false, false, false)
    
    -- Usar posições da config
    AttachEntityToEntity(
        myBoomboxObject, 
        playerPed, 
        GetPedBoneIndex(playerPed, anim.bone),
        anim.offsetX, 
        anim.offsetY, 
        anim.offsetZ,
        anim.rotX, 
        anim.rotY, 
        anim.rotZ,
        true, true, false, true, 1, true
    )
    
    carryingBoombox = true
    carriedBoomboxId = boomboxId
    lastPosition = nil
    
    Notify('[E] Colocar no chão | [G] Guardar')
end)

-- Atualizar posição quando carregada
RegisterNetEvent('boombox:client:updateCarriedPosition', function(boomboxId, ownerServerId)
    if ownerServerId == GetPlayerServerId(PlayerId()) then
        -- Sou eu carregando
        local coords = GetEntityCoords(PlayerPedId())
        exports.xsound:Position('boombox_' .. boomboxId, coords)
    else
        -- Outro jogador carregando
        local ownerPed = GetPlayerPed(GetPlayerFromServerId(ownerServerId))
        if DoesEntityExist(ownerPed) then
            local coords = GetEntityCoords(ownerPed)
            exports.xsound:Position('boombox_' .. boomboxId, coords)
        end
    end
end)
