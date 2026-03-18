-- Built-in Gang Menu server (merged from rsg-gangmenu)
local RSGCore = exports['rsg-core']:GetCoreObject()
local GangAccounts = {}
local ConfigGang = Config.GangMenu or {}

RegisterNetEvent('jobcreator:gangmenu:server:openinventory', function(stashName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = locale('gang', 'sv_storage'), maxweight = ConfigGang.StorageMaxWeight or 4000000, slots = ConfigGang.StorageMaxSlots or 50 }
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

local function GetGangAccount(account)
    return GangAccounts[account] or 0
end

local function AddGangMoney(account, amount)
    if not GangAccounts[account] then GangAccounts[account] = 0 end
    GangAccounts[account] = GangAccounts[account] + amount
    MySQL.insert('INSERT INTO management_funds (job_name, amount, type) VALUES (:job_name, :amount, :type) ON DUPLICATE KEY UPDATE amount = :amount', { ['job_name'] = account, ['amount'] = GangAccounts[account], ['type'] = 'gang' })
end

local function RemoveGangMoney(account, amount)
    local isRemoved = false
    if amount > 0 then
        if not GangAccounts[account] then GangAccounts[account] = 0 end
        if GangAccounts[account] >= amount then
            GangAccounts[account] = GangAccounts[account] - amount
            isRemoved = true
        end
        MySQL.update('UPDATE management_funds SET amount = ? WHERE job_name = ? and type = "gang"', { GangAccounts[account], account })
    end
    return isRemoved
end

if MySQL then
    MySQL.ready(function()
        local gangmenu = MySQL.query.await('SELECT job_name,amount FROM management_funds WHERE type = "gang"', {})
        if gangmenu then
            for _, v in ipairs(gangmenu) do
                GangAccounts[v.job_name] = v.amount
            end
        end
    end)
end

RegisterNetEvent('jobcreator:gangmenu:server:withdrawMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.gang.isboss then return end
    local gang = Player.PlayerData.gang.name
    if RemoveGangMoney(gang, amount) then
        Player.Functions.AddMoney('cash', amount, locale('gang', 'sv_24'))
        TriggerEvent('rsg-log:server:CreateLog', 'gangmenu', locale('gang', 'sv_25'), 'yellow', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('gang', 'sv_51') .. ' $ ' .. amount .. ' (' .. gang .. ')', false)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_27') .. ': $ ' .. amount, type = 'inform', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_28'), type = 'error', duration = 5000 })
    end
end)

RegisterNetEvent('jobcreator:gangmenu:server:depositMoney', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.gang.isboss then return end
    if Player.Functions.RemoveMoney('cash', amount) then
        local gang = Player.PlayerData.gang.name
        AddGangMoney(gang, amount)
        TriggerEvent('rsg-log:server:CreateLog', 'gangmenu', locale('gang', 'sv_29'), 'yellow', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('gang', 'sv_52') .. ' $ ' .. amount .. ' (' .. gang .. ')', false)
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_31') .. ': $ ' .. amount, type = 'inform', duration = 5000 })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_32'), type = 'error', duration = 5000 })
    end
end)

RSGCore.Functions.CreateCallback('jobcreator:gangmenu:server:GetAccount', function(_, cb, GangName)
    cb(GetGangAccount(GangName))
end)

RSGCore.Functions.CreateCallback('jobcreator:gangmenu:server:GetEmployees', function(source, cb, gangname)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.gang.isboss then cb({}) return end
    local employees = {}
    local players = MySQL.query.await("SELECT * FROM `players` WHERE `gang` LIKE '%" .. gangname .. "%'", {})
    if players and players[1] then
        for _, value in pairs(players) do
            local isOnline = RSGCore.Functions.GetPlayerByCitizenId(value.citizenid)
            if isOnline then
                employees[#employees + 1] = {
                    empSource = isOnline.PlayerData.citizenid,
                    grade = isOnline.PlayerData.gang.grade,
                    isboss = isOnline.PlayerData.gang.isboss,
                    name = '🟢' .. isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname
                }
            else
                local gangDec = json.decode(value.gang)
                local charDec = json.decode(value.charinfo)
                employees[#employees + 1] = {
                    empSource = value.citizenid,
                    grade = gangDec and gangDec.grade or { level = 0, name = '' },
                    isboss = gangDec and gangDec.isboss or false,
                    name = '❌' .. (charDec and (charDec.firstname .. ' ' .. charDec.lastname) or 'Unknown')
                }
            end
        end
    end
    cb(employees)
end)

RegisterNetEvent('jobcreator:gangmenu:server:GradeUpdate', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Employee = RSGCore.Functions.GetPlayerByCitizenId(data.cid)
    if not Player or not Player.PlayerData.gang.isboss then return end
    if data.grade > Player.PlayerData.gang.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_33'), type = 'error', duration = 5000 }) return end
    if Employee then
        if Employee.Functions.SetGang(Player.PlayerData.gang.name, data.grade) then
            TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_34'), type = 'inform', duration = 5000 })
            TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, { title = locale('gang', 'sv_35') .. ': ' .. data.gradename .. '.', type = 'inform', duration = 5000 })
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_36'), type = 'error', duration = 5000 })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_37'), type = 'error', duration = 5000 })
    end
end)

RegisterNetEvent('jobcreator:gangmenu:server:FireMember', function(target)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Employee = RSGCore.Functions.GetPlayerByCitizenId(target)
    if not Player or not Player.PlayerData.gang.isboss then return end
    if Employee then
        if target ~= Player.PlayerData.citizenid then
            if Employee.PlayerData.gang.grade.level > Player.PlayerData.gang.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_38'), type = 'error', duration = 5000 }) return end
            if Employee.Functions.SetGang('none', 0) then
                TriggerEvent('rsg-log:server:CreateLog', 'gangmenu', locale('gang', 'sv_39'), 'orange', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('gang', 'sv_40') .. ' ' .. Employee.PlayerData.charinfo.firstname .. ' ' .. Employee.PlayerData.charinfo.lastname .. ' (' .. Player.PlayerData.gang.name .. ')', false)
                TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_41'), type = 'inform', duration = 5000 })
                TriggerClientEvent('ox_lib:notify', Employee.PlayerData.source, { title = locale('gang', 'sv_42'), type = 'error', duration = 5000 })
            else
                TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_43'), type = 'error', duration = 5000 })
            end
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_44'), type = 'error', duration = 5000 })
        end
    else
        local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
        if player and player[1] then
            local row = player[1]
            local gangDec = json.decode(row.gang)
            if gangDec and gangDec.grade and gangDec.grade.level > Player.PlayerData.gang.grade.level then TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_38'), type = 'error', duration = 5000 }) return end
            local gang = {
                name = 'none',
                label = 'No Affiliation',
                payment = 0,
                onduty = true,
                isboss = false,
                grade = { name = nil, level = 0 }
            }
            MySQL.update('UPDATE players SET gang = ? WHERE citizenid = ?', { json.encode(gang), target })
            TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_41'), type = 'inform', duration = 5000 })
            local charDec = json.decode(row.charinfo)
            TriggerEvent('rsg-log:server:CreateLog', 'gangmenu', locale('gang', 'sv_39'), 'orange', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' ' .. locale('gang', 'sv_40') .. (charDec and (charDec.firstname .. ' ' .. charDec.lastname) or '') .. ' (' .. Player.PlayerData.gang.name .. ')', false)
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_37'), type = 'error', duration = 5000 })
        end
    end
end)

RegisterNetEvent('jobcreator:gangmenu:server:HireMember', function(recruit)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(recruit)
    if not Player or not Player.PlayerData.gang.isboss then return end
    if Target and Target.Functions.SetGang(Player.PlayerData.gang.name, 0) then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_46') .. ' ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' ' .. locale('gang', 'sv_47') .. ' ' .. Player.PlayerData.gang.label, type = 'inform', duration = 5000 })
        TriggerClientEvent('ox_lib:notify', Target.PlayerData.source, { title = locale('gang', 'sv_48') .. ' ' .. Player.PlayerData.gang.label, type = 'inform', duration = 5000 })
        TriggerEvent('rsg-log:server:CreateLog', 'gangmenu', locale('gang', 'sv_49'), 'yellow', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) .. ' ' .. locale('gang', 'sv_50') .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' (' .. Player.PlayerData.gang.name .. ')', false)
    end
end)

RSGCore.Functions.CreateCallback('jobcreator:gangmenu:getplayers', function(source, cb)
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

-- Online gang member blips support (client requests list of online members in the same gang)
RSGCore.Functions.CreateCallback('jobcreator:gangmenu:server:GetOnlineGangMembers', function(source, cb, gangName)
    local srcPlayer = RSGCore.Functions.GetPlayer(source)
    if not srcPlayer or not srcPlayer.PlayerData or not srcPlayer.PlayerData.gang then cb({}) return end

    local g = gangName or (srcPlayer.PlayerData.gang and srcPlayer.PlayerData.gang.name)
    if not g or g == '' or g == 'none' then cb({}) return end

    local members = {}
    for _, id in pairs(RSGCore.Functions.GetPlayers()) do
        local p = RSGCore.Functions.GetPlayer(id)
        if p and p.PlayerData and p.PlayerData.gang and p.PlayerData.gang.name == g then
            local first = p.PlayerData.charinfo and p.PlayerData.charinfo.firstname or ''
            local last = p.PlayerData.charinfo and p.PlayerData.charinfo.lastname or ''
            local name = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
            if name == '' then name = 'Unknown' end

            members[#members + 1] = {
                source = id,
                name = name,
            }
        end
    end

    table.sort(members, function(a, b) return a.name < b.name end)
    cb(members)
end)

-- Admin command to remove player from gang
RSGCore.Commands.Add('removegang', locale('gang', 'sv_admin_usage'), { { name = 'id', help = 'Player ID' }, { name = 'gang', help = 'Gang ID' } }, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    local gang = args[2]
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_43'), description = locale('gang', 'sv_admin_error'), type = 'error', duration = 5000 })
        return
    end
    if not RSGCore.Shared.Gangs[gang] then
        TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_43'), description = locale('gang', 'sv_admin_invalidgangid'), type = 'error', duration = 5000 })
        return
    end
    Player.Functions.SetGang('none', 0)
    TriggerClientEvent('ox_lib:notify', src, { title = locale('gang', 'sv_39'), description = locale('gang', 'sv_admin_remove'), type = 'success', duration = 5000 })
    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, { title = locale('gang', 'sv_39'), description = locale('gang', 'sv_42'), type = 'inform', duration = 7000 })
end, 'admin')
