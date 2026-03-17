-- Built-in Gang Menu client (merged from rsg-gangmenu)
local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerGang = RSGCore.Functions.GetPlayerData().gang
local isFromCommand = false
local CurrentGangLocations = {}
local ConfigGang = Config.GangMenu or {}
local function L(k) return locale('gang', k) end

local function CoordsFromTable(t)
    if not t or type(t) ~= 'table' then return vector3(0, 0, 0) end
    return vector3(tonumber(t.x) or 0, tonumber(t.y) or 0, tonumber(t.z) or 0)
end

local function ApplyGangLocations()
    for _, v in pairs(CurrentGangLocations) do
        pcall(function() exports['rsg-core']:deletePrompt(v.id) end)
    end
    for _, v in pairs(CurrentGangLocations) do
        local c = CoordsFromTable(v.coords)
        local gangFilter = (v.gang and v.gang ~= '') and v.gang or nil
        exports['rsg-core']:createPrompt(v.id, c, RSGCore.Shared.Keybinds[ConfigGang.Keybind or 'J'], L('cl_open') .. ' ' .. (v.name or 'Gang Menu'), {
            type = 'client',
            event = 'jobcreator:gangmenu:client:mainmenu',
            args = gangFilter and { gangFilter } or {},
        })
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerGang = RSGCore.Functions.GetPlayerData().gang
        SetTimeout(600, function() TriggerServerEvent('jobcreator:server:requestLocations') end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, v in pairs(CurrentGangLocations) do
            pcall(function() exports['rsg-core']:deletePrompt(v.id) end)
        end
    end
end)

RegisterNetEvent('jobcreator:client:receiveLocations', function(bossLocations, gangLocations)
    CurrentGangLocations = gangLocations or {}
    ApplyGangLocations()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerGang = RSGCore.Functions.GetPlayerData().gang
end)

RegisterNetEvent('RSGCore:Client:OnGangUpdate', function(GangInfo)
    PlayerGang = GangInfo
end)

local function comma_valueGang(amount)
    local formatted = tostring(amount)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

RegisterNetEvent('jobcreator:gangmenu:client:mainmenu', function(gangFilter)
    if not PlayerGang or not PlayerGang.name or not PlayerGang.isboss then return end
    if gangFilter and gangFilter ~= '' and PlayerGang.name ~= gangFilter then return end
    isFromCommand = false
    lib.registerContext({
        id = 'jobcreator_gang_mainmenu',
        title = L('cl_1'),
        options = {
            { title = L('cl_2'), description = L('cl_3'), icon = 'fa-solid fa-list', event = 'jobcreator:gangmenu:client:employeelist', arrow = true },
            { title = L('cl_4'), description = L('cl_5'), icon = 'fa-solid fa-hand-holding', event = 'jobcreator:gangmenu:client:HireMenu', arrow = true },
            { title = L('cl_6'), description = L('cl_7'), icon = 'fa-solid fa-box-open', event = 'jobcreator:gangmenu:client:Stash', arrow = true },
            { title = L('cl_8'), description = L('cl_9'), icon = 'fa-solid fa-sack-dollar', event = 'jobcreator:gangmenu:client:SocietyMenu', arrow = true },
        }
    })
    lib.showContext('jobcreator_gang_mainmenu')
end)

RegisterNetEvent('jobcreator:gangmenu:client:employeelist', function()
    RSGCore.Functions.TriggerCallback('jobcreator:gangmenu:server:GetEmployees', function(result)
        local options = {}
        for _, v in pairs(result or {}) do
            options[#options + 1] = {
                title = v.name,
                description = v.grade and v.grade.name or '',
                icon = 'fa-solid fa-circle-user',
                event = 'jobcreator:gangmenu:client:ManageEmployee',
                args = { player = v, work = PlayerGang },
                arrow = true,
            }
        end
        lib.registerContext({
            id = 'jobcreator_gang_employeelist_menu',
            title = L('cl_10'),
            menu = isFromCommand and 'jobcreator_gang_commandmenu' or 'jobcreator_gang_mainmenu',
            onBack = function() end,
            position = 'top-right',
            options = options
        })
        lib.showContext('jobcreator_gang_employeelist_menu')
    end, PlayerGang.name)
end)

RegisterNetEvent('jobcreator:gangmenu:client:ManageEmployee', function(data)
    local options = {}
    local sharedGangs = (RSGCore.Shared and RSGCore.Shared.Gangs) or {}
    local gangGrades = (data.work and data.work.name and sharedGangs[data.work.name] and sharedGangs[data.work.name].grades) or {}
    for k, v in pairs(gangGrades) do
        options[#options + 1] = {
            title = L('cl_11') .. ' ' .. v.name,
            description = L('cl_12') .. ': ' .. k,
            icon = 'fa-solid fa-file-pen',
            serverEvent = 'jobcreator:gangmenu:server:GradeUpdate',
            args = { cid = data.player.empSource, grade = tonumber(k), gradename = v.name },
        }
    end
    options[#options + 1] = {
        title = L('cl_13'),
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'jobcreator:gangmenu:server:FireMember',
        args = data.player.empSource,
        iconColor = 'red'
    }
    lib.registerContext({
        id = 'jobcreator_managemembers_menu',
        title = L('cl_14'),
        menu = 'jobcreator_gang_employeelist_menu',
        onBack = function() end,
        position = 'top-right',
        options = options
    })
    lib.showContext('jobcreator_managemembers_menu')
end)

RegisterNetEvent('jobcreator:gangmenu:client:HireMenu', function()
    RSGCore.Functions.TriggerCallback('jobcreator:gangmenu:getplayers', function(players)
        local options = {}
        for _, v in pairs(players or {}) do
            if v and v.sourceplayer ~= GetPlayerServerId(PlayerId()) then
                options[#options + 1] = {
                    title = v.name,
                    description = L('cl_15') .. ': ' .. v.citizenid .. ' - ' .. L('cl_16') .. ': ' .. v.sourceplayer,
                    icon = 'fa-solid fa-user-check',
                    serverEvent = 'jobcreator:gangmenu:server:HireMember',
                    args = v.sourceplayer,
                    arrow = true
                }
            end
        end
        lib.registerContext({
            id = 'jobcreator_hiremembers_menu',
            title = L('cl_4'),
            menu = isFromCommand and 'jobcreator_gang_commandmenu' or 'jobcreator_gang_mainmenu',
            onBack = function() end,
            position = 'top-right',
            options = options
        })
        lib.showContext('jobcreator_hiremembers_menu')
    end)
end)

RegisterNetEvent('jobcreator:gangmenu:client:Stash', function()
    TriggerServerEvent('jobcreator:gangmenu:server:openinventory', 'gang_' .. PlayerGang.name)
end)

RegisterNetEvent('jobcreator:gangmenu:client:SocietyMenu', function()
    RSGCore.Functions.TriggerCallback('jobcreator:gangmenu:server:GetAccount', function(cb)
        lib.registerContext({
            id = 'jobcreator_gangsociety_menu',
            menu = 'jobcreator_gang_mainmenu',
            title = L('cl_17') .. ': $ ' .. comma_valueGang(cb or 0),
            options = {
                { title = L('cl_18'), description = L('cl_19'), icon = 'fa-solid fa-money-bill-transfer', event = 'jobcreator:gangmenu:client:SocetyDeposit', args = RSGCore.Functions.GetPlayerData().money and RSGCore.Functions.GetPlayerData().money.cash or 0, iconColor = 'green', arrow = true },
                { title = L('cl_20'), description = L('cl_21'), icon = 'fa-solid fa-money-bill-transfer', event = 'jobcreator:gangmenu:client:SocetyWithDraw', args = comma_valueGang(cb or 0), iconColor = 'red', arrow = true },
            }
        })
        lib.showContext('jobcreator_gangsociety_menu')
    end, PlayerGang.name)
end)

RegisterNetEvent('jobcreator:gangmenu:client:SocetyDeposit', function(money)
    local input = lib.inputDialog(L('cl_22') .. ': $ ' .. tostring(money), {
        { label = L('cl_23'), type = 'number', required = true, icon = 'fa-solid fa-dollar-sign' },
    })
    if input then TriggerServerEvent('jobcreator:gangmenu:server:depositMoney', tonumber(input[1])) end
end)

RegisterNetEvent('jobcreator:gangmenu:client:SocetyWithDraw', function(money)
    local input = lib.inputDialog(L('cl_22') .. ': $ ' .. tostring(money), {
        { label = L('cl_23'), type = 'number', required = true, icon = 'fa-solid fa-dollar-sign' },
    })
    if input then TriggerServerEvent('jobcreator:gangmenu:server:withdrawMoney', tonumber(input[1])) end
end)

RegisterNetEvent('jobcreator:gangmenu:client:commandmenu', function()
    if not PlayerGang or not PlayerGang.name or not PlayerGang.isboss then return end
    isFromCommand = true
    lib.registerContext({
        id = 'jobcreator_gang_commandmenu',
        title = L('cl_1'),
        options = {
            { title = L('cl_2'), description = L('cl_3'), icon = 'fa-solid fa-list', event = 'jobcreator:gangmenu:client:employeelist', arrow = true },
            { title = L('cl_4'), description = L('cl_5'), icon = 'fa-solid fa-hand-holding', event = 'jobcreator:gangmenu:client:HireMenu', arrow = true },
        }
    })
    lib.showContext('jobcreator_gang_commandmenu')
end)

RegisterCommand('gangmenu', function()
    if not PlayerGang or not PlayerGang.name or not PlayerGang.isboss then
        lib.notify({ title = L('cl_1'), description = L('cl_cmd_error'), type = 'error', duration = 5000 })
        return
    end
    TriggerEvent('jobcreator:gangmenu:client:commandmenu')
end, false)
