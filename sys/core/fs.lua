--@EXT km
local aex_int = sys.get_internal_table()
local mounts  = aex_int.mounts

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
    if not path then error('sys.fs_open: Missing path') end
    if not mode then mode = 'r' end

    if aex_int.dev[path] then
        local dev_io = aex_int.dev[path]()

        if not dev_io.close then
            function dev_io.close(self) end
        end
        dev_io.path     = path
        dev_io.isDevice = true
        dev_io.type     = aex_int.dev_marks[path]
        return dev_io
    end

    local mount, path_r = getMount(path)
    if not mount then return nil, aex_int.result.no_such_file_or_directory end

    local ret = {position = 1}

    if mode == 'r' then
        local data, c = mount:fileRead(path_r)
        if not data or type(data) ~= 'string' then return nil, aex_int.result.no_such_file_or_directory end
            
        function ret.read(self, len)
            if not len then
                local dd = string.sub(data, ret.position)
                ret.position = #data + 1

                return dd
            end
            if len < 0 then return '' end

            local start = ret.position
            ret.position = math.clamp(ret.position + len, 1, #data + 1)

            return string.sub(data, start, len)
        end
        function ret.close(self)
            ret = nil
        end
    elseif mode == 'w' then
        local data = ''
        function ret.write(self, dw)
            if not dw then return end
            dw           = tostring(dw)
            ret.position = ret.position + #dw

            data = data .. dw
        end
        function ret.flush(self)
            mount:fileWrite(path_r, data)
        end
        function ret.close(self)
            ret:flush()
            ret = nil
        end
    end
    ret.path = path
    return ret
end
function sys.fs_exists(path)
    if not path then error('sys.fs_exists: Missing path') end

    if aex_int.dev[path] then    return true end
    if aex_int.mounts[path .. '/'] then return true end
    if aex_int.mounts[path] then return true end

    local mount, path_r = getMount(path)
    if not mount then return false end
    
    return mount:fileExists(path_r)
end
function sys.fs_list(path)
    if not path then error('sys.fs_list: Missing path') end

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
    if not path then error('sys.fs_delete: Missing path') end

    local mount, path_r = getMount(path)
    if not mount then return nil end
    
    return mount:fileDelete(path_r)
end
function sys.fs_mkdir(path)
    if not path then error('sys.fs_mkdir: Missing path') end

    local mount, path_r = getMount(path)
    if not mount then return nil end
    
    return mount:dirCreate(path_r)
end
function sys.fs_mount(dev_path, path)
    if not dev_path or not path then error('sys.fs_mount: Missing arguments') end

    local dev = sys.fs_open(dev_path)

    if not dev then return false, aex_int.result.file_not_found_error end
    if aex_int.dev_marks[dev_path] ~= 'hdd' then return false, aex_int.result.invalid_device_error end

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