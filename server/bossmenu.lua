-- Built-in Boss Menu server (merged from rsg-bossmenu)
local RSGCore = exports['rsg-core']:GetCoreObject()
local Accounts = {}
local ConfigBoss = Config.BossMenu or {}

RegisterNetEvent('jobcreator:bossmenu:server:openinventory', function(stashName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = locale('boss', 'sv_storage'), maxweight = ConfigBoss.StorageMaxWeight or 4000000, slots = ConfigBoss.StorageMaxSlots or 50 }
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

local function GetAccount(account)
    return Accounts[account] or 0
end

local function AddMoney(account, amount)
    if not Accounts[account] then Accounts[account] = 0 end
    Accounts[account] = Accounts[account] + amount
    MySQL.insert('INSERT INTO management_funds (job_name, amount, type) VALUES (:job_name, :amount, :type) ON DUPLICATE KEY UPDATE amount = :amount', { ['job_name'] = account, ['amount'] = Accounts[account], ['type'] = 'boss' })
end

local function RemoveMoney(account, amount)
    local isRemoved = false
    if amount > 0 then
        if not Accounts[account] then Accounts[account] = 0 end
        if Accounts[account] >= amount then
            Accounts[account] = Accounts[account] - amount
            isRemoved = true
        end
        MySQL.update('UPDATE management_funds SET amount = ? WHERE job_name = ? and type = "boss"', { Accounts[account], account })
    end
    return isRemoved
end

if MySQL then
    MySQL.ready(function()
        local bossmenu = MySQL.query.await('SELECT job_name,amount FROM management_funds WHERE type = "boss"', {})
        if bossmenu then
            for _, v in ipairs(bossmenu) do
                Accounts[v.job_name] = v.amount
            end
        end
    end)
end

RegisterNetEvent('jobcreator:bossmenu:server:withdrawMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.job.isboss then return end
    local job = Player.PlayerData.job.name
    if RemoveMoney(job, amount) then
        Player.Functions.AddMoney('cash', amount, locale('boss', 'sv_24'))
        TriggerEvent('rsg-log:server:CreateLog', 'bossmenu', locale('boss', 'sv_25'), 'blue', Player.PlayerData.name .. locale('boss', 'sv_26') .. ' $' .. amount .. ' (' .. job .. ')', false)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_27') .. ': $ ' .. amount, type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_28'), type = 'error', duration = 5000 })
    end
end)

RegisterNetEvent('jobcreator:bossmenu:server:depositMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.job.isboss then return end
    if Player.Functions.RemoveMoney('cash', amount) then
        local job = Player.PlayerData.job.name
        AddMoney(job, amount)
        TriggerEvent('rsg-log:server:CreateLog', 'bossmenu', locale('boss', 'sv_29'), 'blue', Player.PlayerData.name .. locale('boss', 'sv_30') .. ' $' .. amount .. ' (' .. job .. ')', false)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_31') .. ': $ ' .. amount, type = 'success', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_32'), type = 'error', duration = 5000 })
    end
end)

RSGCore.Functions.CreateCallback('jobcreator:bossmenu:server:GetAccount', function(_, cb, jobname)
    cb(GetAccount(jobname))
end)

RSGCore.Functions.CreateCallback('jobcreator:bossmenu:server:GetEmployees', function(source, cb, jobname)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.job.isboss then cb({}) return end
    local employees = {}
    local players = MySQL.query.await("SELECT * FROM `players` WHERE `job` LIKE '%" .. jobname .. "%'", {})
    if players and players[1] then
        for _, value in pairs(players) do
            local isOnline = RSGCore.Functions.GetPlayerByCitizenId(value.citizenid)
            if isOnline then
                employees[#employees + 1] = {
                    empSource = isOnline.PlayerData.citizenid,
                    grade = isOnline.PlayerData.job.grade,
                    isboss = isOnline.PlayerData.job.isboss,
                    name = '🟢 ' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
                }
            else
                local jobDec = json.decode(value.job)
                local charDec = json.decode(value.charinfo)
                employees[#employees + 1] = {
                    empSource = value.citizenid,
                    grade = jobDec and jobDec.grade or { level = 0, name = '' },
                    isboss = jobDec and jobDec.isboss or false,
                    name = '❌ ' .. (charDec and (charDec.firstname .. ' ' .. charDec.lastname) or 'Unknown')
                }
            end
        end
        table.sort(employees, function(a, b) return a.grade.level > b.grade.level end)
    end
    cb(employees)
end)

RegisterNetEvent('jobcreator:bossmenu:server:GradeUpdate', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Employee = RSGCore.Functions.GetPlayerByCitizenId(data.cid)
    if not Player or not Player.PlayerData.job.isboss then return end
    if data.grade > Player.PlayerData.job.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_33'), type = 'error', duration = 5000 }) return end
    if Employee then
        if Employee.Functions.SetJob(Player.PlayerData.job.name, data.grade) then
            TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_34'), type = 'success', duration = 5000 })
            TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, { title = locale('boss', 'sv_35') .. ' ' .. data.gradename .. '.', type = 'success', duration = 5000 })
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_36'), type = 'error', duration = 5000 })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_37'), type = 'error', duration = 5000 })
    end
end)

RegisterNetEvent('jobcreator:bossmenu:server:FireEmployee', function(target)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Employee = RSGCore.Functions.GetPlayerByCitizenId(target)
    if not Player or not Player.PlayerData.job.isboss then return end
    if Employee then
        if target ~= Player.PlayerData.citizenid then
            if Employee.PlayerData.job.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_38'), type = 'error', duration = 5000 }) return end
            if Employee.Functions.SetJob('unemployed', 0) then
                TriggerEvent('rsg-log:server:CreateLog', 'bossmenu', locale('boss', 'sv_39'), 'red', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('boss', 'sv_40') .. ' ' .. Employee.PlayerData.charinfo.firstname .. ' ' .. Employee.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.job.name .. ')', false)
                TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_41'), type = 'success', duration = 5000 })
                TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, { title = locale('boss', 'sv_42'), type = 'error', duration = 5000 })
            else
                TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_43'), type = 'error', duration = 5000 })
            end
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_44'), type = 'error', duration = 5000 })
        end
    else
        local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
        if player and player[1] then
            local row = player[1]
            local jobDec = json.decode(row.job)
            if jobDec and jobDec.grade and jobDec.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_45'), type = 'error', duration = 5000 }) return end
            local core = exports['rsg-core']:GetCoreObject()
            local job = {
                name = 'unemployed',
                label = 'Unemployed',
                payment = (core.Shared and core.Shared.Jobs and core.Shared.Jobs.unemployed and core.Shared.Jobs.unemployed.grades and core.Shared.Jobs.unemployed.grades['0']) and core.Shared.Jobs.unemployed.grades['0'].payment or 500,
                onduty = true,
                isboss = false,
                grade = { name = 'Freelancer', level = 0 }
            }
            MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), target })
            TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_41'), type = 'success', duration = 5000 })
            local charDec = json.decode(row.charinfo)
            TriggerEvent('rsg-log:server:CreateLog', 'bossmenu', locale('boss', 'sv_39'), 'red', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('boss', 'sv_40') .. (charDec and (charDec.firstname .. ' ' .. charDec.lastname) or '') .. ' (' .. Player.PlayerData.job.name .. ')', false)
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_37'), type = 'error', duration = 5000 })
        end
    end
end)

RegisterNetEvent('jobcreator:bossmenu:server:HireEmployee', function(recruit)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(recruit)
    if not Player or not Player.PlayerData.job.isboss then return end
    if Target and Target.Functions.SetJob(Player.PlayerData.job.name, 0) then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('boss', 'sv_46') .. ' ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' ' .. locale('boss', 'sv_47') .. ' ' .. Player.PlayerData.job.label, type = 'success', duration = 5000 })
        TriggerClientEvent('ox_lib:notify', Target.PlayerData.source, { title = locale('boss', 'sv_48') .. ' ' .. Player.PlayerData.job.label, type = 'success', duration = 5000 })
        TriggerEvent('rsg-log:server:CreateLog', 'bossmenu', locale('boss', 'sv_49'), 'lightgreen', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) .. ' ' .. locale('boss', 'sv_50') .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' (' .. Player.PlayerData.job.name .. ')', false)
    end
end)

RSGCore.Functions.CreateCallback('jobcreator:bossmenu:getplayers', function(source, cb)
    local src = source
    local players = {}
    local PlayerPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(PlayerPed)
    for _, v in pairs(RSGCore.Functions.GetPlayers()) do
        local targetped = GetPlayerPed(v)
        local tCoords = GetEntityCoords(targetped)
        if PlayerPed ~= targetped and #(pCoords - tCoords) < 10 then
            local ped = RSGCore.Functions.GetPlayer(v)
            if ped then
                players[#players + 1] = {
                    id = v,
                    coords = GetEntityCoords(targetped),
                    name = ped.PlayerData.charinfo.firstname .. ' ' .. ped.PlayerData.charinfo.lastname,
                    citizenid = ped.PlayerData.citizenid,
                    sources = GetPlayerPed(ped.PlayerData.source),
                    sourceplayer = ped.PlayerData.source
                }
            end
        end
    end
    table.sort(players, function(a, b) return a.name < b.name end)
    cb(players)
end)
