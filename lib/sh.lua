--@EXT lib
local sh = {}
function sh.getProcessInfo(pid)
    local dat = sys.process_get_info(pid)
    return dat
end
function sh.getArgs()
    local dat = sh.getProcessInfo()
    return dat.args
end
function sh.getUser()
    local dat = sh.getProcessInfo()
    return dat.user
end
function sh.getDir()
    local dat = sh.getProcessInfo()
    return dat.dir
end
function sh.getTTY()
    return io.getstdout().path
end
function sh.getTTYSize()
    local x, y = io.getstdout():getSize()
    return x or 0, y or 0
end
return sh