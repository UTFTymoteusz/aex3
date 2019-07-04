--@EXT lib
local os = {}
function os.getHostname()
    return sys.get_hostname()
end
function os.setHostname(hostname)
    return sys.set_hostname(hostname)
end
function os.reset()
    return sys.reset()
end
return os