--@EXT km
local aex_int = sys.get_internal_table()

function require(lib)
    if not lib then return nil end

    local lib_paths = {}

    if string.sub(lib, 1, 2) == './' then
        table.add(lib_paths, {lib, lib .. '.lib'}) end

    table.add(lib_paths, {'/lib/' .. lib, '/lib/' .. lib .. '.lib'})

    local fd = nil

    for _, p in pairs(lib_paths) do
        fd = sys.fs_open(p, 'r')
        if not fd then goto xcontinue end

        local code = fd:read('*a')
        local rr
        code, rr = loadstring(code, p)

        fd:close()

        if not code then error(rr)
        elseif type(code) == 'function' then
            setfenv(code, getfenv())
        else error(code) end
        do return code() end
        ::xcontinue::
    end
    return nil
end