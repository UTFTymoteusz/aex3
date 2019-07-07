--@EXT lib
local aex_int = sys.get_internal_table()

function sys.drvmgr_load(path)
    if aex_int.started and sys.get_running_pid() ~= 0 then
        return aex_int.runInKernel(function()
            sys.drvmgr_load(path)
        end)
    end
    if sys.fs_exists and not sys.fs_exists(path) then
        return nil, 'No such file or directory'
    end
    local code = aex_int.readFile(path)
    code, rr = loadstring(code, path)

    if not code then
        return nil, tostring(rr)
    elseif type(code) == 'string' then
        return nil, tostring(code)
    end

    setfenv(code, getfenv())

    local s, drv, ax, bx, cx, dx = pcall(code)

    if not s then   return nil, tostring(drv) end
    if not drv then return nil, 'Invalid driver file (no table returned)' end
    if type(drv) ~= 'table' then
        return nil, 'Invalid driver file (table not returned, got ' .. type(drv) .. ')'
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
        if not drv[index] then return nil, 'Missing fields in driver table (' .. index .. ', type ' .. typew .. ')' end
        if type(drv[index]) ~= typew then return nil, 'Invalid fields in driver table (' .. index .. ' has to be of type ' .. typew .. ')' end
    end

    if not drv.description then
        drv.description = 'Not present'
    end
    aex_int.driver_id_counter = aex_int.driver_id_counter + 1
    local nid = aex_int.driver_id_counter

    aex_int.drivers[nid] = {
        base = drv,
        enabled = true,
        owned = {}
    }
    do
        local env = table.copy(getfenv(sys.drvmgr_load)) -- Limited trust

        setfenv(drv.load,    env)
        setfenv(drv.unload,  env)
        setfenv(drv.enable,  env)
        setfenv(drv.disable, env)

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
        return nil, 'Invalid driver id'
    end
    local s, r = pcall(drv.base.disable)
    if not s then return nil, 'Driver error: ' .. r end
    s, r = pcall(drv.base.unload)
    if not s then return nil, 'Driver error: ' .. r end

    aex_int.drivers[id] = nil

    return true
end
function sys.drvmgr_enable(id)
    local drv = aex_int.drivers[id]
    if not drv then
        return nil, 'Invalid driver id'
    end
    local s, r = pcall(drv.base.enable)
    if not s then return nil, 'Driver error: ' .. r end
    drv.enabled = true

    return true
end
function sys.drvmgr_disable(id)
    local drv = aex_int.drivers[id]
    if not drv then
        return nil, 'Invalid driver id'
    end
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
        disallow_disable = drv.base.disallow_disable,
        enabled = drv.enabled,
        owned_devices = drv.owned,
    }
end
function sys.drvmgr_claim(name, driver)
    aex_int.assertType(name, 'string')
    aex_int.assertType(driver, 'table')

    if string.sub(name, 1, 5) ~= '/dev/' then name = '/dev/' .. name end

    for k, v in pairs(aex_int.drivers) do
        if v.base == driver then
            table.add(v.owned, {name})
            return true
        end
    end
    return false
end