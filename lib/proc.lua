--@EXT lib
local proc = {}

function proc.create(path, args, dir, sec_assoc)
    return sys.process_create(path, args, dir, sec_assoc)
end
function proc.replace(path, args, dir, sec_assoc)
    return sys.process_replace(path, args, dir, sec_assoc)
end
function proc.info(pid)
    return sys.process_get_info(pid)
end
function proc.list()
    return sys.process_list()
end
return proc