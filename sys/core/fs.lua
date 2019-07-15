--@EXT sys
local aex_int = sys.get_internal_table()
local mounts  = aex_int.mounts
local handles = {}

aex_int.file_handles = handles

local function getMount(path)
    local mount, path_r, most, cnt = nil, nil, 0, 6666666
    for k, v in pairs(mounts) do
        cnt = #string.split(k, '/')

        k = string.sub(k, 1, #k - 1)

        if k == string.sub(path, 1, #k) and cnt > most then
            path_r, most, mount = string.sub(path, #k), cnt, v
        end
    end
    return mount, path_r
end

function sys.fs_open(path, mode)
    aex_int.assertType(path, 'string')
    if not mode then mode = 'r' end

    if aex_int.dev[path] then
        local dev_base = aex_int.dev[path]
        local dev_io   = {}

        if not dev_io.open then
            function dev_io.open(self) return true end
        end
        if not dev_io.close then
            function dev_io.close(self) end
        end

        for k, v in pairs(dev_base) do
            dev_io[k] = v
        end

        local ret = dev_io:open()

        if not ret then
            return nil, aex_int.result.resource_or_device_busy_error
        else
            -- do method replacement
        end

        dev_io.path     = path
        dev_io.isDevice = true
        dev_io.type     = aex_int.dev_marks[path]
        return dev_io
    end

    local mount, path_r = getMount(path)
    if not mount then return nil, aex_int.result.no_such_file_or_directory end

    local ret = {}
    local fd, r = mount:fd_open(path_r, mode)

    if not fd then return nil, r end

    if mode == 'r' then
        function ret:read(len)
            len = len or '*a'
            return mount:fd_read(fd, len)
        end
    elseif mode == 'w' then
        function ret:write(str)
            if not str then return end
            return mount:fd_write(fd, str)
        end
    end

    function ret:seek(op, offset)
        return mount:fd_seek(fd, op, offset)
    end
    function ret:flush()
        return mount:fd_flush(fd)
    end
    function ret:close()
        mount:fd_close(fd)
        ret = nil
    end

    if aex_int.started then
        handles[sys.get_running_pid()] = handles[sys.get_running_pid()] or {}
        handles[sys.get_running_pid()][fd] = ret
    end

    ret.path = path

    return ret
end
function sys.fs_exists(path)
    aex_int.assertType(path, 'string')

    if aex_int.dev[path] then    return true end
    if aex_int.mounts[path .. '/'] then return true end
    if aex_int.mounts[path] then return true end

    local mount, path_r = getMount(path)
    if not mount then return false end

    return mount:fileExists(path_r)
end
function sys.fs_list(path)
    aex_int.assertType(path, 'string')

    local mount, path_r = getMount(path)
    if not mount then return nil end

    local l = mount:fileList(path_r)

    if path[#path] ~= '/' then path = path .. '/' end

    local spr = string.split(path, '/')
    local cnt = table.concat(spr, '/', 1, #spr - 1)

    for k, _ in pairs(aex_int.dev) do
        local sp = string.split(k, '/')

        if cnt == table.concat(sp, "/", 1, #sp - 1) then
            table.insert(l, {name = sp[#sp], type = 'dev'})
        end
    end
    for k, _ in pairs(aex_int.mounts) do
        local sp = string.split(k, '/')

        if cnt == table.concat(sp, "/", 1, #sp - 2) and path ~= k then
            table.insert(l, {name = sp[#sp - 1] .. '/', type = 'mnt'})
        end
    end
    for k, v in pairs(l) do
        if v.type == 'dir' and v.name[#v.name] ~= '/' then l[k].name = v.name .. '/' end
    end
    return l
end
function sys.fs_delete(path)
    aex_int.assertType(path, 'string')

    local mount, path_r = getMount(path)
    if not mount then return nil end

    return mount:fileDelete(path_r)
end
function sys.fs_mkdir(path)
    aex_int.assertType(path, 'string')

    local mount, path_r = getMount(path)
    if not mount then return nil end

    return mount:dirCreate(path_r)
end
function sys.fs_size(path)
    aex_int.assertType(path, 'string')

    local mount, path_r = getMount(path)
    if not mount then return nil end

    return mount:fileSize(path_r)
end
function sys.fs_type(path)
    aex_int.assertType(path, 'string')

    if aex_int.dev[path] then return 'dev' end
    if aex_int.mounts[path .. '/'] then return 'mnt' end
    if aex_int.mounts[path] then return 'mnt' end

    local mount, path_r = getMount(path)
    if not mount then return nil end

    return mount:fileType(path_r)
end
function sys.fs_mount(dev_path, path)
    if not dev_path or not path then error('sys.fs_mount: Missing arguments') end

    local dev = sys.fs_open(dev_path)

    if not dev then return false, aex_int.result.file_not_found_error end
    if aex_int.dev_marks[dev_path] ~= 'storage' then return false, aex_int.result.invalid_device_error end

    if mounts[path] then return false, aex_int.result.access_denied_error end

    for k, v in pairs(mounts) do
        if v.path == dev_path then return false, aex_int.result.already_mounted_error end
    end

    if   path[1] ~= '/'   then path = '/' .. path end
    if path[#path] ~= '/' then path = path .. '/' end
    mounts[path] = dev

    return true
end
function sys.fs_unmount(path)
    if not path then error('sys.fs_unmount: Missing arguments') end

    if   path[1] ~= '/'   then path = '/' .. path end
    if path[#path] ~= '/' then path = path .. '/' end

    if path == '/' then return false, aex_int.result.doing_this_would_make_the_system_unstable_error end

    if not mounts[path] then return false, aex_int.result.file_not_found_error end

    -- implement busy checks

    mounts[path]:close()
    mounts[path] = nil

    return true
end
function sys.fs_get_mounts()
    local ret = {}
    for mount, drive in pairs(mounts) do
        ret[mount] = {path = drive.path}
    end
    return ret
end

aex_int.syshook.add('process_end', 'fs handle disposal', function(pid)
    if handles[pid] then

        for k, v in pairs(handles[pid]) do
            v:close()
        end
        handles[pid] = nil
    end
end)