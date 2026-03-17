-- Built-in Boss Menu client (merged from rsg-bossmenu)
local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerJob = RSGCore.Functions.GetPlayerData().job
local CurrentBossLocations = {}
local ConfigBoss = Config.BossMenu or {}
local function L(k) return locale('boss', k) end

local function CoordsFromTable(t)
    if not t or type(t) ~= 'table' then return vector3(0, 0, 0) end
    return vector3(tonumber(t.x) or 0, tonumber(t.y) or 0, tonumber(t.z) or 0)
end

local function ApplyBossLocations()
    for _, v in pairs(CurrentBossLocations) do
        pcall(function() exports['rsg-core']:deletePrompt(v.id) end)
    end
    for _, v in pairs(CurrentBossLocations) do
        local c = CoordsFromTable(v.coords)
        local jobFilter = (v.job and v.job ~= '') and v.job or nil
        exports['rsg-core']:createPrompt(v.id, c, RSGCore.Shared.Keybinds[ConfigBoss.Keybind or 'J'], L('cl_open') .. ' ' .. (v.name or 'Boss Menu'), {
            type = 'client',
            event = 'jobcreator:bossmenu:client:mainmenu',
            args = jobFilter and { jobFilter } or {},
        })
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerJob = RSGCore.Functions.GetPlayerData().job
        SetTimeout(500, function() TriggerServerEvent('jobcreator:server:requestLocations') end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, v in pairs(CurrentBossLocations) do
            pcall(function() exports['rsg-core']:deletePrompt(v.id) end)
        end
    end
end)

RegisterNetEvent('jobcreator:client:receiveLocations', function(bossLocations, gangLocations)
    CurrentBossLocations = bossLocations or {}
    ApplyBossLocations()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerJob = RSGCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

local function comma_value(amount)
    local formatted = tostring(amount)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

RegisterNetEvent('jobcreator:bossmenu:client:mainmenu', function(jobFilter)
    if not PlayerJob or not PlayerJob.name or not PlayerJob.isboss then return end
    if jobFilter and jobFilter ~= '' and PlayerJob.name ~= jobFilter then return end
    lib.registerContext({
        id = 'jobcreator_boss_mainmenu',
        title = L('cl_1'),
        options = {
            { title = L('cl_2'), description = L('cl_3'), icon = 'fa-solid fa-list', event = 'jobcreator:bossmenu:client:employeelist', arrow = true },
            { title = L('cl_4'), description = L('cl_5'), icon = 'fa-solid fa-hand-holding', event = 'jobcreator:bossmenu:client:HireMenu', arrow = true },
            { title = L('cl_6'), description = L('cl_7'), icon = 'fa-solid fa-box-open', event = 'jobcreator:bossmenu:client:Stash', arrow = true },
            { title = L('cl_8'), description = L('cl_9'), icon = 'fa-solid fa-sack-dollar', event = 'jobcreator:bossmenu:client:SocietyMenu', arrow = true },
        }
    })
    lib.showContext('jobcreator_boss_mainmenu')
end)

RegisterNetEvent('jobcreator:bossmenu:client:employeelist', function()
    RSGCore.Functions.TriggerCallback('jobcreator:bossmenu:server:GetEmployees', function(result)
        local options = {}
        for _, v in pairs(result or {}) do
            options[#options + 1] = {
                title = v.name,
                description = v.grade and v.grade.name or '',
                icon = 'fa-solid fa-circle-user',
                event = 'jobcreator:bossmenu:client:ManageEmployee',
                args = { player = v, work = PlayerJob },
                arrow = true,
            }
        end
        lib.registerContext({
            id = 'jobcreator_employeelist_menu',
            title = L('cl_10'),
            menu = 'jobcreator_boss_mainmenu',
            onBack = function() end,
            position = 'top-right',
            options = options
        })
        lib.showContext('jobcreator_employeelist_menu')
    end, PlayerJob.name)
end)

RegisterNetEvent('jobcreator:bossmenu:client:ManageEmployee', function(data)
    local options = {}
    local sharedJobs = (RSGCore.Shared and RSGCore.Shared.Jobs) or {}
    local jobGrades = (data.work and data.work.name and sharedJobs[data.work.name] and sharedJobs[data.work.name].grades) or {}
    for k, v in pairs(jobGrades) do
        options[#options + 1] = {
            title = L('cl_11') .. ' ' .. v.name,
            description = L('cl_12') .. ': ' .. k,
            icon = 'fa-solid fa-file-pen',
            serverEvent = 'jobcreator:bossmenu:server:GradeUpdate',
            args = { cid = data.player.empSource, grade = tonumber(k), gradename = v.name },
        }
    end
    options[#options + 1] = {
        title = L('cl_13'),
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'jobcreator:bossmenu:server:FireEmployee',
        args = data.player.empSource,
        iconColor = 'red'
    }
    lib.registerContext({
        id = 'jobcreator_manageemployee_menu',
        title = L('cl_14'),
        menu = 'jobcreator_employeelist_menu',
        onBack = function() end,
        position = 'top-right',
        options = options
    })
    lib.showContext('jobcreator_manageemployee_menu')
end)

RegisterNetEvent('jobcreator:bossmenu:client:HireMenu', function()
    RSGCore.Functions.TriggerCallback('jobcreator:bossmenu:getplayers', function(players)
        local options = {}
        for _, v in pairs(players or {}) do
            if v and v.sourceplayer ~= GetPlayerServerId(PlayerId()) then
                options[#options + 1] = {
                    title = v.name,
                    description = L('cl_15') .. ': ' .. v.citizenid .. ' - ' .. L('cl_16') .. ': ' .. v.sourceplayer,
                    icon = 'fa-solid fa-user-check',
                    serverEvent = 'jobcreator:bossmenu:server:HireEmployee',
                    args = v.sourceplayer,
                    arrow = true
                }
            end
        end
        lib.registerContext({
            id = 'jobcreator_hireemployees_menu',
            title = L('cl_4'),
            menu = 'jobcreator_boss_mainmenu',
            onBack = function() end,
            position = 'top-right',
            options = options
        })
        lib.showContext('jobcreator_hireemployees_menu')
    end)
end)

RegisterNetEvent('jobcreator:bossmenu:client:Stash', function()
    TriggerServerEvent('jobcreator:bossmenu:server:openinventory', 'boss_' .. PlayerJob.name)
end)

RegisterNetEvent('jobcreator:bossmenu:client:SocietyMenu', function()
    RSGCore.Functions.TriggerCallback('jobcreator:bossmenu:server:GetAccount', function(cb)
        lib.registerContext({
            id = 'jobcreator_society_menu',
            menu = 'jobcreator_boss_mainmenu',
            title = L('cl_17') .. ' $: ' .. comma_value(cb or 0),
            options = {
                { title = L('cl_18'), description = L('cl_19'), icon = 'fa-solid fa-money-bill-transfer', event = 'jobcreator:bossmenu:client:SocetyDeposit', args = RSGCore.Functions.GetPlayerData().money and RSGCore.Functions.GetPlayerData().money.cash or 0, iconColor = 'green', arrow = true },
                { title = L('cl_20'), description = L('cl_21'), icon = 'fa-solid fa-money-bill-transfer', event = 'jobcreator:bossmenu:client:SocetyWithDraw', args = comma_value(cb or 0), iconColor = 'red', arrow = true },
            }
        })
        lib.showContext('jobcreator_society_menu')
    end, PlayerJob.name)
end)

RegisterNetEvent('jobcreator:bossmenu:client:SocetyDeposit', function(money)
    local input = lib.inputDialog(L('cl_22') .. ': $ ' .. tostring(money), {
        { label = L('cl_23'), type = 'number', required = true, icon = 'fa-solid fa-dollar-sign' },
    })
    if input then TriggerServerEvent('jobcreator:bossmenu:server:depositMoney', tonumber(input[1])) end
end)

RegisterNetEvent('jobcreator:bossmenu:client:SocetyWithDraw', function(money)
    local input = lib.inputDialog(L('cl_22') .. ': $ ' .. tostring(money), {
        { label = L('cl_23'), type = 'number', required = true, icon = 'fa-solid fa-dollar-sign' },
    })
    if input then TriggerServerEvent('jobcreator:bossmenu:server:withdrawMoney', tonumber(input[1])) end
end)
