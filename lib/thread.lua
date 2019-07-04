--@EXT lib
local thread = {}

function thread.create(func)
    return sys.thread_create(func)
end
return thread