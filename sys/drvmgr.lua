--@EXT lib
local aex_int = sys.get_internal_table()

function sys.drvmgr_load(path)
    aex_int.assertType(path, 'string')

    if aex_int.started and sys.get_running_pid() ~= 0 then
        return aex_int.runInKernel(function()
            return sys.drvmgr_load(path)
        end)
    end
    if string.sub(path, 1, 9) ~= '/sys/drv/' then
        path = '/sys/drv/' .. path end
    if string.sub(path, #path - 3) ~= '.drv' then
        path = path .. '.drv'      end

    if sys.fs_exists and not sys.fs_exists(path) then
        return nil, 'No such file or directory' end

    local code = aex_int.readFile(path)
    code, rr = loadstring(code, path)

    if not code then
        return nil, tostring(rr)
    elseif type(code) == 'string' then
        return nil, tostring(code)
    end

    local env = table.copy(getfenv())
    local owned = {}

    env.sys.drvmgr_claim = function(name)
        aex_int.assertType(name, 'string')
    
        if string.sub(name, 1, 5) ~= '/dev/' then name = '/dev/' .. name end
        table.add(owned, {name})

        return true
    end
    setfenv(code, env)

    local s, r = pcall(code)

    if not s then return nil, tostring(drv) end
    if not env.info or type(env.info) ~= 'table' then 
        return nil, 'Driver did not set a global info table' end
    
    local drv = {
        full_name = env.info.full_name,
        name      = env.info.name,
        type      = env.info.type,
        provider  = env.info.provider,
        version   = env.info.version,

        load    = env.load,
        unload  = env.unload,
        enable  = env.enable,
        disable = env.disable,
    }

    for k, v in pairs(aex_int.drivers) do
        if drv.name == v.base.name then
            return nil, 'Specified driver does not allow multiple instances of itself' end
    end

    local required = {
        ['full_name'] = 'string',
        ['name']      = 'string',
        ['type']      = 'string',
        ['provider']  = 'string',
        ['version']   = 'string',

        ['load']    = 'function',
        ['unload']  = 'function',
        ['enable']  = 'function',
        ['disable'] = 'function',
    }
    for index, typew in pairs(required) do
        if not drv[index] then return nil, 'Missing globals in driver env (' .. index .. ', type ' .. typew .. ')' end
        if type(drv[index]) ~= typew then return nil, 'Invalid globals in driver env (' .. index .. ' has to be of type ' .. typew .. ')' end
    end

    if not drv.description then
        drv.description = 'Not present'
    end
    aex_int.driver_id_counter = aex_int.driver_id_counter + 1
    local nid = aex_int.driver_id_counter

    aex_int.drivers[nid] = {
        base = drv,
        enabled = true,
        owned = owned,
        disallow_disable = env.info.disallow_disable,
        allow_multiple_instances = env.info.allow_multiple_instances,
    }
    do
        local s, r
        s, r = pcall(drv.load)
        if not s then return nil, 'Driver error: ' .. r end
        s, r = pcall(drv.enable)
        if not s then return nil, 'Driver error: ' .. r end
    end
    return nid
end
function sys.drvmgr_unload(id)
    local drv = aex_int.drivers[id]
    if not drv then
        return false, 'Invalid driver id'
    end

    if drv.disallow_disable then
        return false, 'Driver cannot be unloaded' end

    local s, r
    if drv.enabled then
        s, r = pcall(drv.base.disable)
        if not s then return false, 'Driver error: ' .. r end
        drv.enabled = false
    end
    s, r = pcall(drv.base.unload)
    if not s then return false, 'Driver error: ' .. r end

    aex_int.drivers[id] = nil

    return true
end
function sys.drvmgr_enable(id)
    local drv = aex_int.drivers[id]
    if not drv then
        return false, 'Invalid driver id' end

    if drv.enabled then
        return false, 'Driver already enabled' end

    local s, r = pcall(drv.base.enable)
    if not s then return false, 'Driver error: ' .. r end
    drv.enabled = true

    return true
end
function sys.drvmgr_disable(id)
    local drv = aex_int.drivers[id]
    if not drv then
        return nil, 'Invalid driver id' end

    if not drv.enabled then
        return false, 'Driver already disabled' end
    if drv.disallow_disable then
        return false, 'Driver cannot be disabled' end

    local s, r = pcall(drv.base.disable)
    if not s then return nil, 'Driver error: ' .. r end
    drv.enabled = false

    return true
end
function sys.drvmgr_list()
    return table.getKeys(aex_int.drivers)
end
function sys.drvmgr_info(id)
    aex_int.assertType(id, 'number')

    local drv = aex_int.drivers[id]
    if not drv then
        return nil
    end

    return {
        full_name = drv.base.full_name,
        name = drv.base.name,
        type = drv.base.type,
        provider = drv.base.provider,
        version  = drv.base.version,
        disallow_disable = drv.disallow_disable,
        enabled = drv.enabled,
        owned_devices = drv.owned,
    }
end
function sys.drvmgr_claim(name)
    aex_int.assertType(name, 'string')
    return false
end