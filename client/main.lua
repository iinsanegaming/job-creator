local isOpen = false
local pendingSaveJobCb = nil
local pendingSaveGangCb = nil
local pendingDeleteJobCb = nil
local pendingDeleteGangCb = nil

local function OpenCreator()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        showBossMenu = Config.ShowBossMenuButton ~= false,
        showGangMenu = Config.ShowGangMenuButton ~= false,
    })
    TriggerServerEvent('jobcreator:server:requestData')
end

local function CloseCreator()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.OpenCommand or 'jobcreator', function()
    local RSGCore = exports['rsg-core']:GetCoreObject()
    RSGCore.Functions.TriggerCallback('jobcreator:server:hasPermission', function(hasPermission)
        if not hasPermission then
            if lib and lib.notify then
                lib.notify({ title = 'Job & Gang Creator', description = 'This is locked to specific characters.', type = 'error', duration = 5000 })
            end
            return
        end
        OpenCreator()
    end)
end, false)

RegisterNetEvent('jobcreator:client:receiveData', function(data)
    SendNUIMessage({ action = 'setData', data = data })
    if data.bossLocations or data.gangLocations then
        TriggerEvent('jobcreator:client:receiveLocations', data.bossLocations or {}, data.gangLocations or {})
    end
end)

RegisterNetEvent('jobcreator:client:saveJobResult', function(result)
    if pendingSaveJobCb then
        pendingSaveJobCb(result)
        pendingSaveJobCb = nil
    end
end)

RegisterNetEvent('jobcreator:client:saveGangResult', function(result)
    if pendingSaveGangCb then
        pendingSaveGangCb(result)
        pendingSaveGangCb = nil
    end
end)

RegisterNetEvent('jobcreator:client:deleteJobResult', function(result)
    if pendingDeleteJobCb then
        pendingDeleteJobCb(result)
        pendingDeleteJobCb = nil
    end
end)

RegisterNetEvent('jobcreator:client:deleteGangResult', function(result)
    if pendingDeleteGangCb then
        pendingDeleteGangCb(result)
        pendingDeleteGangCb = nil
    end
end)

RegisterNUICallback('close', function(_, cb)
    CloseCreator()
    cb('ok')
end)

-- Open built-in Boss Menu (close creator first so ox_lib context can show)
RegisterNUICallback('openBossMenu', function(_, cb)
    CloseCreator()
    TriggerEvent('jobcreator:bossmenu:client:mainmenu')
    cb('ok')
end)

-- Open built-in Gang Menu (same as /gangmenu command)
RegisterNUICallback('openGangMenu', function(_, cb)
    CloseCreator()
    TriggerEvent('jobcreator:gangmenu:client:commandmenu')
    cb('ok')
end)

RegisterNUICallback('saveJob', function(data, cb)
    pendingSaveJobCb = cb
    TriggerServerEvent('jobcreator:server:saveJob', data)
end)

RegisterNUICallback('saveGang', function(data, cb)
    pendingSaveGangCb = cb
    TriggerServerEvent('jobcreator:server:saveGang', data)
end)

RegisterNUICallback('deleteJob', function(data, cb)
    pendingDeleteJobCb = cb
    TriggerServerEvent('jobcreator:server:deleteJob', data.name)
end)

RegisterNUICallback('deleteGang', function(data, cb)
    pendingDeleteGangCb = cb
    TriggerServerEvent('jobcreator:server:deleteGang', data.name)
end)

-- Place boss/gang menu locations from NUI (at current position)
RegisterNUICallback('addBossLocationAtPosition', function(payload, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('jobcreator:server:addBossLocation', {
        name = payload.name or 'Boss Menu',
        job = payload.job or '',
        showblip = payload.showblip == true,
        coords = { x = coords.x, y = coords.y, z = coords.z },
    })
    cb({ success = true })
end)

RegisterNUICallback('addGangLocationAtPosition', function(payload, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('jobcreator:server:addGangLocation', {
        name = payload.name or 'Gang Menu',
        gang = payload.gang or '',
        blipname = payload.blipname or payload.name or 'Gang Menu',
        showblip = payload.showblip == true,
        blipforall = payload.blipforall == true,
        coords = { x = coords.x, y = coords.y, z = coords.z },
    })
    cb({ success = true })
end)

RegisterNUICallback('removeBossLocation', function(data, cb)
    if data.id then TriggerServerEvent('jobcreator:server:removeBossLocation', data.id) end
    cb({ success = true })
end)

RegisterNUICallback('removeGangLocation', function(data, cb)
    if data.id then TriggerServerEvent('jobcreator:server:removeGangLocation', data.id) end
    cb({ success = true })
end)

-- ESC to close (client fallback when NUI doesn't capture key)
CreateThread(function()
    while true do
        Wait(200)
        if isOpen then
            if IsControlJustReleased(0, 322) then -- ESC
                CloseCreator()
            end
        end
    end
end)
