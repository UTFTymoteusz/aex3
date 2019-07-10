--@EXT drv
info = {
    full_name = 'Pseudo Devices Driver',
    name = 'pdevs',
    type = 'pseudo',
    provider = 'Tymkboi',
    version  = '1.0',
}

local thread

local random_buffer, random_last
local hal_core

function load()
    local aex_int = sys.get_internal_table()
    hal_core = aex_int.hal.core
end
function unload()

end
function enable()
    random_last, random_buffer = 0, ''

    thread = sys.thread_create(function()
        while true do
            while random_last < hal_core.time() do
                if #random_buffer >= 1024 then random_last = hal_core.time() break end

                random_last = random_last + 0.025
                random_buffer = random_buffer .. string.char(math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255))
            end
            sleep(100)
        end
    end)

    sys.add_device('null', function()
        return {
            write = function(self, data) end,
            read = function(self, len)
                return ''
            end,
        }
    end)
    sys.drvmgr_claim('null')

    sys.add_device('zero', function()
        return {
            write = function(self, data) end,
            read = function(self, len)
                if len then return string.rep('\0', len)
                else return '\0' end
            end,
        }
    end)
    sys.drvmgr_claim('zero')

    sys.add_device('random', function()
        return {
            write = function(self, data) end,
            read = function(self, len)
                if len then
                    local ret = string.sub(random_buffer, 1, len)
                    random_buffer = string.sub(random_buffer, len + 1)

                    len = len - #ret
                    local next
                    while len > 0 do
                        next = string.sub(random_buffer, 1, len)
                        random_buffer = string.sub(random_buffer, len + 1)

                        ret = ret .. next
                        len = len - #next
                        waitOne()
                    end
                    return ret
                else
                    while #random_buffer == 0 do waitOne() end

                    local ret = random_buffer
                    random_buffer = ''

                    return ret
                end
            end,
        }
    end)
    sys.drvmgr_claim('random')

    sys.add_device('urandom', function()
        local buff
        return {
            write = function(self, data) end,
            read = function(self, len)
                len = len and len or 4
                buff = ''
                for i = 1, len do
                    buff = buff .. string.char(math.random(0, 255))
                end
                return buff
            end,
        }
    end)
    sys.drvmgr_claim('urandom')

    return true
end
function disable()
    thread:abort()

    sys.remove_device('null')
    sys.remove_device('zero')
    sys.remove_device('random')
    sys.remove_device('urandom')

    return true
end