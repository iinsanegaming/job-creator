local RSGCore = exports['rsg-core']:GetCoreObject()
local CustomJobs = {}
local CustomGangs = {}
local DataPath = nil

local function GetDataPath()
    if DataPath then return DataPath end
    DataPath = GetResourcePath(GetCurrentResourceName()) .. '/' .. Config.DataFile
    return DataPath
end

local function EnsureDataDir()
    local path = GetDataPath()
    local dir = path:match('^(.+)/[^/]+$')
    if dir and not io.open(dir, 'r') then
        os.execute('mkdir "' .. dir:gsub('/', '\\') .. '" 2>nul')
    end
end

local function LoadCustomData()
    local path = GetDataPath()
    local f = io.open(path, 'r')
    if not f then
        CustomJobs = {}
        CustomGangs = {}
        return
    end
    local content = f:read('*a')
    f:close()
    if content and content ~= '' then
        local ok, data = pcall(json.decode, content)
        if ok and data then
            CustomJobs = data.jobs or {}
            CustomGangs = data.gangs or {}
        end
    end
end

local function SaveCustomData()
    EnsureDataDir()
    local path = GetDataPath()
    local data = { jobs = CustomJobs, gangs = CustomGangs }
    local f = io.open(path, 'w')
    if f then
        f:write(json.encode(data))
        f:close()
    end
end

-- Boss / Gang menu locations (placed from NUI)
local LocationsPath = nil
local BossLocations = {}
local GangLocations = {}

local function GetLocationsPath()
    if LocationsPath then return LocationsPath end
    LocationsPath = GetResourcePath(GetCurrentResourceName()) .. '/' .. (Config.LocationsFile or 'data/boss_gang_locations.json')
    return LocationsPath
end

local function CoordsToTable(v)
    if type(v) == 'table' and v.x and v.y and v.z then return { x = v.x, y = v.y, z = v.z } end
    if type(v) == 'vector3' or (type(v) == 'userdata' and v.x) then return { x = v.x, y = v.y, z = v.z } end
    return { x = 0, y = 0, z = 0 }
end

local function TableToCoords(t)
    if not t or type(t) ~= 'table' then return vector3(0, 0, 0) end
    return vector3(tonumber(t.x) or 0, tonumber(t.y) or 0, tonumber(t.z) or 0)
end

local function LoadLocations()
    local path = GetLocationsPath()
    local dir = path:match('^(.+)/[^/]+$')
    if dir and not io.open(dir, 'r') then
        os.execute('mkdir "' .. dir:gsub('/', '\\') .. '" 2>nul')
    end
    local f = io.open(path, 'r')
    if f then
        local content = f:read('*a')
        f:close()
        if content and content ~= '' then
            local ok, data = pcall(json.decode, content)
            if ok and data then
                BossLocations = data.bossLocations or {}
                GangLocations = data.gangLocations or {}
                for _, loc in ipairs(BossLocations) do
                    if loc.coords and type(loc.coords) == 'table' then
                        loc.coords = TableToCoords(loc.coords)
                    end
                end
                for _, loc in ipairs(GangLocations) do
                    if loc.coords and type(loc.coords) == 'table' then
                        loc.coords = TableToCoords(loc.coords)
                    end
                end
                return
            end
        end
    end
    -- Fallback to Config defaults
    local cfgBoss = Config.BossMenu and Config.BossMenu.BossLocations or {}
    local cfgGang = Config.GangMenu and Config.GangMenu.GangLocations or {}
    BossLocations = {}
    GangLocations = {}
    for i, v in ipairs(cfgBoss) do
        BossLocations[i] = {
            id = v.id or ('jobcreator_boss_' .. i),
            name = v.name or 'Boss Menu',
            job = v.job or '',
            coords = type(v.coords) == 'vector3' and v.coords or TableToCoords(v.coords),
            showblip = v.showblip == true,
        }
    end
    for i, v in ipairs(cfgGang) do
        GangLocations[i] = {
            id = v.id or ('jobcreator_gang_' .. i),
            name = v.name or 'Gang Menu',
            gang = v.gang or '',
            blipname = v.blipname or v.name or 'Gang Menu',
            coords = type(v.coords) == 'vector3' and v.coords or TableToCoords(v.coords),
            showblip = v.showblip == true,
            blipforall = v.blipforall == true,
        }
    end
    SaveLocations()
end

function SaveLocations()
    EnsureDataDir()
    local path = GetLocationsPath()
    local outBoss = {}
    local outGang = {}
    for _, loc in ipairs(BossLocations) do
        outBoss[#outBoss + 1] = {
            id = loc.id,
            name = loc.name,
            job = loc.job or '',
            coords = CoordsToTable(loc.coords),
            showblip = loc.showblip == true,
        }
    end
    for _, loc in ipairs(GangLocations) do
        outGang[#outGang + 1] = {
            id = loc.id,
            name = loc.name,
            gang = loc.gang or '',
            blipname = loc.blipname or loc.name,
            coords = CoordsToTable(loc.coords),
            showblip = loc.showblip == true,
            blipforall = loc.blipforall == true,
        }
    end
    local f = io.open(path, 'w')
    if f then
        f:write(json.encode({ bossLocations = outBoss, gangLocations = outGang }))
        f:close()
    end
end

-- Pull all jobs from RSG-Core shared jobs (shared/jobs.lua + any added at runtime)
local function SerializeJobs()
    local core = exports['rsg-core']:GetCoreObject()
    local sharedJobs = (core and core.Shared and core.Shared.Jobs) or {}
    local out = {}
    for name, job in pairs(sharedJobs) do
        local custom = CustomJobs[name]
        if custom and custom.deleted then
            -- This job was explicitly deleted via the creator; hide it from the UI list.
        else
        local grades = {}
        for level, g in pairs(job.grades or {}) do
            grades[#grades + 1] = {
                level = tonumber(level),
                name = g.name or '',
                payment = g.payment or 0,
                isboss = g.isboss or false,
            }
        end
        table.sort(grades, function(a, b) return a.level < b.level end)
        out[name] = {
            name = name,
            label = job.label or name,
            defaultDuty = job.defaultDuty ~= false,
            offDutyPay = job.offDutyPay or false,
            type = job.type or Config.DefaultJobType or 'none',
            grades = grades,
        }
        end
    end
    return out
end

-- Pull all gangs from RSG-Core shared gangs (shared/gangs.lua + any added at runtime)
local function SerializeGangs()
    local core = exports['rsg-core']:GetCoreObject()
    local sharedGangs = (core and core.Shared and core.Shared.Gangs) or {}
    local out = {}
    for name, gang in pairs(sharedGangs) do
        local custom = CustomGangs[name]
        if custom and custom.deleted then
            -- This gang was explicitly deleted via the creator; hide it from the UI list.
        else
            local grades = {}
            for level, g in pairs(gang.grades or {}) do
                grades[#grades + 1] = {
                    level = tonumber(level),
                    name = g.name or '',
                    payment = g.payment or 0,
                    isboss = g.isboss or false,
                }
            end
            table.sort(grades, function(a, b) return a.level < b.level end)
            out[name] = {
                name = name,
                label = gang.label or name,
                grades = grades,
            }
        end
    end
    return out
end

local function RegisterCustomJobs()
    for name, job in pairs(CustomJobs) do
        if job.deleted then
            goto continue_job
        end
        local grades = {}
        for _, g in ipairs(job.grades or {}) do
            grades[tostring(g.level)] = {
                name = g.name or 'Grade ' .. g.level,
                payment = tonumber(g.payment) or 0,
                isboss = g.isboss or false,
            }
        end
        local ok, err = pcall(function()
            exports['rsg-core']:AddJob(name, {
                label = job.label or name,
                defaultDuty = job.defaultDuty ~= false,
                offDutyPay = job.offDutyPay or false,
                type = job.type or Config.DefaultJobType or 'none',
                grades = grades,
            })
        end)
        if not ok then
            print(('[job-creator] Failed to add job %s: %s'):format(name, tostring(err)))
        end
        ::continue_job::
    end
end

local function RegisterCustomGangs()
    for name, gang in pairs(CustomGangs) do
        if gang.deleted then
            goto continue_gang
        end
        local grades = {}
        for _, g in ipairs(gang.grades or {}) do
            grades[tostring(g.level)] = {
                name = g.name or 'Grade ' .. g.level,
                payment = tonumber(g.payment) or 0,
                isboss = g.isboss or false,
            }
        end
        local ok, err = pcall(function()
            exports['rsg-core']:AddGang(name, {
                label = gang.label or name,
                grades = grades,
            })
        end)
        if not ok then
            print(('[job-creator] Failed to add gang %s: %s'):format(name, tostring(err)))
        end
        ::continue_gang::
    end
end

CreateThread(function()
    Wait(1000)
    LoadCustomData()
    LoadLocations()
    RegisterCustomJobs()
    RegisterCustomGangs()
end)

local function HasPermission(source)
    local allowed = Config.AllowedCitizenIds
    if not allowed or type(allowed) ~= 'table' or #allowed == 0 then return true end
    local player = RSGCore.Functions.GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.citizenid then return false end
    local cid = player.PlayerData.citizenid
    for i = 1, #allowed do
        if allowed[i] == cid then return true end
    end
    return false
end

RSGCore.Functions.CreateCallback('jobcreator:server:hasPermission', function(source, cb)
    cb(HasPermission(source))
end)

local function SerializeLocationsForClient()
    local outBoss, outGang = {}, {}
    for _, loc in ipairs(BossLocations) do
        outBoss[#outBoss + 1] = { id = loc.id, name = loc.name, job = loc.job or '', coords = CoordsToTable(loc.coords), showblip = loc.showblip == true }
    end
    for _, loc in ipairs(GangLocations) do
        outGang[#outGang + 1] = { id = loc.id, name = loc.name, gang = loc.gang or '', blipname = loc.blipname or loc.name, coords = CoordsToTable(loc.coords), showblip = loc.showblip == true, blipforall = loc.blipforall == true }
    end
    return outBoss, outGang
end

local function BuildFullData()
    local sboss, sgang = SerializeLocationsForClient()
    return {
        jobs = SerializeJobs(),
        gangs = SerializeGangs(),
        customJobNames = CustomJobs,
        customGangNames = CustomGangs,
        bossLocations = sboss,
        gangLocations = sgang,
    }
end

RegisterNetEvent('jobcreator:server:requestData', function()
    local src = source
    if not HasPermission(src) then return end
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
end)

RegisterNetEvent('jobcreator:server:saveJob', function(data)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('jobcreator:client:saveJobResult', src, { success = false, message = 'No permission' })
        return
    end
    -- Same logic as NUI callback below, then send result to client
    local name = (data.name or ''):lower():gsub('%s+', '')
    if name == '' then
        TriggerClientEvent('jobcreator:client:saveJobResult', src, { success = false, message = 'Job name required' })
        return
    end
    local grades = {}
    for _, g in ipairs(data.grades or {}) do
        local level = tonumber(g.level)
        if level and level >= 0 then
            grades[#grades + 1] = {
                level = level,
                name = g.name or ('Grade ' .. level),
                payment = tonumber(g.payment) or 0,
                isboss = g.isboss or false,
            }
        end
    end
    table.sort(grades, function(a, b) return a.level < b.level end)
    if #grades == 0 then
        grades = { { level = 0, name = 'Freelancer', payment = 0, isboss = false } }
    end
    local job = {
        name = name,
        label = data.label or name,
        defaultDuty = data.defaultDuty ~= false,
        offDutyPay = data.offDutyPay or false,
        type = data.type or Config.DefaultJobType or 'none',
        grades = grades,
    }
    local rsgGrades = {}
    for _, g in ipairs(grades) do
        rsgGrades[tostring(g.level)] = { name = g.name, payment = g.payment, isboss = g.isboss }
    end
    local ok, err = pcall(function()
        exports['rsg-core']:AddJob(name, {
            label = job.label,
            defaultDuty = job.defaultDuty,
            offDutyPay = job.offDutyPay,
            type = job.type,
            grades = rsgGrades,
        })
    end)
    if not ok then
        TriggerClientEvent('jobcreator:client:saveJobResult', src, { success = false, message = tostring(err) })
        return
    end
    CustomJobs[name] = job
    SaveCustomData()
    TriggerClientEvent('jobcreator:client:saveJobResult', src, { success = true, message = 'Job saved' })
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
end)

RegisterNetEvent('jobcreator:server:saveGang', function(data)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('jobcreator:client:saveGangResult', src, { success = false, message = 'No permission' })
        return
    end
    local name = (data.name or ''):lower():gsub('%s+', '')
    if name == '' then
        TriggerClientEvent('jobcreator:client:saveGangResult', src, { success = false, message = 'Gang name required' })
        return
    end
    local grades = {}
    for _, g in ipairs(data.grades or {}) do
        local level = tonumber(g.level)
        if level and level >= 0 then
            grades[#grades + 1] = {
                level = level,
                name = g.name or ('Grade ' .. level),
                payment = tonumber(g.payment) or 0,
                isboss = g.isboss or false,
            }
        end
    end
    table.sort(grades, function(a, b) return a.level < b.level end)
    if #grades == 0 then
        grades = { { level = 0, name = 'Recruit', payment = 0, isboss = false } }
    end
    local gang = {
        name = name,
        label = data.label or name,
        grades = grades,
    }
    local rsgGrades = {}
    for _, g in ipairs(grades) do
        rsgGrades[tostring(g.level)] = { name = g.name, payment = g.payment, isboss = g.isboss }
    end
    local ok, err = pcall(function()
        exports['rsg-core']:AddGang(name, {
            label = gang.label,
            grades = rsgGrades,
        })
    end)
    if not ok then
        TriggerClientEvent('jobcreator:client:saveGangResult', src, { success = false, message = tostring(err) })
        return
    end
    CustomGangs[name] = gang
    SaveCustomData()
    TriggerClientEvent('jobcreator:client:saveGangResult', src, { success = true, message = 'Gang saved' })
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
end)

RegisterNetEvent('jobcreator:server:deleteJob', function(name)
    local src = source
    local function sendResult(result)
        TriggerClientEvent('jobcreator:client:deleteJobResult', src, result)
    end
    if not HasPermission(src) then
        sendResult({ success = false, message = 'No permission' })
        return
    end
    name = (name or ''):lower():gsub('%s+', '')
    local ok, err = pcall(function()
        if name ~= '' then
            -- Mark as deleted so SerializeJobs hides it and RegisterCustomJobs skips it.
            CustomJobs[name] = { deleted = true }
            local core = exports['rsg-core']:GetCoreObject()
            if core and core.Shared and core.Shared.Jobs then
                core.Shared.Jobs[name] = nil
            end
            SaveCustomData()
        end
        TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    end)
    if not ok then
        sendResult({ success = false, message = tostring(err) })
        return
    end
    sendResult({ success = true, message = 'Deleted' })
end)

RegisterNetEvent('jobcreator:server:deleteGang', function(name)
    local src = source
    local function sendResult(result)
        TriggerClientEvent('jobcreator:client:deleteGangResult', src, result)
    end
    if not HasPermission(src) then
        sendResult({ success = false, message = 'No permission' })
        return
    end
    name = (name or ''):lower():gsub('%s+', '')
    local ok, err = pcall(function()
        if name ~= '' then
            -- Mark as deleted so SerializeGangs / RegisterCustomGangs skip it.
            CustomGangs[name] = { deleted = true }
            local core = exports['rsg-core']:GetCoreObject()
            if core and core.Shared and core.Shared.Gangs then
                core.Shared.Gangs[name] = nil
            end
            SaveCustomData()
        end
        TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    end)
    if not ok then
        sendResult({ success = false, message = tostring(err) })
        return
    end
    sendResult({ success = true, message = 'Deleted' })
end)

-- Locations: request (for clients on start), add, remove
RegisterNetEvent('jobcreator:server:requestLocations', function()
    local src = source
    local sboss, sgang = SerializeLocationsForClient()
    TriggerClientEvent('jobcreator:client:receiveLocations', src, sboss, sgang)
end)

local function BroadcastLocations()
    local sboss, sgang = SerializeLocationsForClient()
    TriggerClientEvent('jobcreator:client:receiveLocations', -1, sboss, sgang)
end

RegisterNetEvent('jobcreator:server:addBossLocation', function(data)
    local src = source
    if not HasPermission(src) then return end
    local coords = type(data.coords) == 'table' and vector3(tonumber(data.coords.x) or 0, tonumber(data.coords.y) or 0, tonumber(data.coords.z) or 0) or vector3(0, 0, 0)
    local id = 'jobcreator_boss_' .. os.time() .. '_' .. math.random(100, 999)
    local jobName = (type(data.job) == 'string' and data.job ~= '' and data.job) or ''
    BossLocations[#BossLocations + 1] = {
        id = id,
        name = data.name or 'Boss Menu',
        job = jobName,
        coords = coords,
        showblip = data.showblip == true,
    }
    SaveLocations()
    BroadcastLocations()
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    TriggerClientEvent('ox_lib:notify', src, { title = 'Boss location added', type = 'success', duration = 3000 })
end)

RegisterNetEvent('jobcreator:server:removeBossLocation', function(id)
    local src = source
    if not HasPermission(src) then return end
    for i = #BossLocations, 1, -1 do
        if BossLocations[i].id == id then
            table.remove(BossLocations, i)
            break
        end
    end
    SaveLocations()
    BroadcastLocations()
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    TriggerClientEvent('ox_lib:notify', src, { title = 'Boss location removed', type = 'inform', duration = 3000 })
end)

RegisterNetEvent('jobcreator:server:addGangLocation', function(data)
    local src = source
    if not HasPermission(src) then return end
    local coords = type(data.coords) == 'table' and vector3(tonumber(data.coords.x) or 0, tonumber(data.coords.y) or 0, tonumber(data.coords.z) or 0) or vector3(0, 0, 0)
    local id = 'jobcreator_gang_' .. os.time() .. '_' .. math.random(100, 999)
    local gangName = (type(data.gang) == 'string' and data.gang ~= '' and data.gang) or ''
    GangLocations[#GangLocations + 1] = {
        id = id,
        name = data.name or 'Gang Menu',
        gang = gangName,
        blipname = data.blipname or data.name or 'Gang Menu',
        coords = coords,
        showblip = data.showblip == true,
        blipforall = data.blipforall == true,
    }
    SaveLocations()
    BroadcastLocations()
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    TriggerClientEvent('ox_lib:notify', src, { title = 'Gang location added', type = 'success', duration = 3000 })
end)

RegisterNetEvent('jobcreator:server:removeGangLocation', function(id)
    local src = source
    if not HasPermission(src) then return end
    for i = #GangLocations, 1, -1 do
        if GangLocations[i].id == id then
            table.remove(GangLocations, i)
            break
        end
    end
    SaveLocations()
    BroadcastLocations()
    TriggerClientEvent('jobcreator:client:receiveData', src, BuildFullData())
    TriggerClientEvent('ox_lib:notify', src, { title = 'Gang location removed', type = 'inform', duration = 3000 })
end)

