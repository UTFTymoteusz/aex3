--@EXT lib
local fs = {}

local get_info = sys.process_get_info

function fs.open(path, mode)
    path = fs.translate(get_info().dir, path)
    return sys.fs_open(path, mode)
end
function fs.read(path)
    path = fs.translate(get_info().dir, path)

    local fd, r = fs.open(path, 'r')
    if not fd then return fd, r end

    local dat = fd:read('*a')
    fd:close()

    return dat
end
function fs.readln(path)
    path = fs.translate(get_info().dir, path)

    local f, r = fs.read(path)
    if not f then return f, r end

    return string.split(f, '\n')
end
function fs.write(path, data)
    path = fs.translate(get_info().dir, path)

    local fd, r = fs.open(path, 'w')
    if not fd then return fd, r end

    fd:write(data)
    fd:flush()
    fd:close()

    return true
end
function fs.exists(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_exists(path)
end
function fs.list(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_list(path)
end
function fs.delete(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_delete(path)
end
function fs.makedir(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_mkdir(path)
end
function fs.size(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_size(path)
end
function fs.type(path)
    path = fs.translate(get_info().dir, path)
    return sys.fs_type(path)
end
function fs.copy(src_path, dst_path)
    local buffer

    local src_fd, cc = fs.open(src_path, 'r')
    if not src_fd then return false, cc, false end

    if fs.exists(dst_path) then

        if fs.type(dst_path) == 'dir' then
            return false, -0xFD03, true
        end
    end

    local dst_fd, cc = fs.open(dst_path, 'w')
    if not dst_fd then return false, cc, true end

    local buffer

    repeat
        buffer = src_fd:read(512)

        if #buffer == 0 then break end

        dst_fd:write(buffer)
    until false

    src_fd:close()

    dst_fd:flush()
    dst_fd:close()

    return true
end

function fs.translate(basedir, path)
    if not basedir or not path then return nil end

    if path[1] ~= '/' then
        path = basedir .. path
    end
    local split = string.split(path, '/')

    local i = 0
    local v
    while i < #split do
        i = i + 1
        v = split[i]

        if v == '..' then
            table.remove(split, i)
            i = i - 1
            table.remove(split, i)
            i = i - 1
        elseif v == '.' or string.trim(v) == '' then
            table.remove(split, i)
            i = i - 1
        end
    end
    path = table.concat(split, '/')

    if path[1] ~= '/' then
        path = '/' .. path
    end
    return path
end
function fs.getExtension(path)
    local exp = string.split(path, '.')
    if #exp == 0 then return nil end

    return exp[#exp]
end
function fs.getFilename(path)
    local dir = false

    if #path > 1 and path[#path] == '/' then dir = true path = string.sub(path, 1, #path - 1) end
    local split = string.split(path, '/')
    
    return split[#split] .. (dir and '/' or '')
end

function fs.mount(dev_path, path)
    return sys.fs_mount(dev_path, path)
end
function fs.unmount(path)
    return sys.fs_unmount(path)
end
function fs.getMounts()
    return sys.fs_get_mounts()
end
return fs