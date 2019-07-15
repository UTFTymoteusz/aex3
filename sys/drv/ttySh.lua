--@EXT drv
info = {
    full_name = 'Serial Hub Driver',
    name = 'ttySh',
    type = 'hub',
    provider = 'Tymkboi',
    version  = '1.0',
    disallow_disable = true,
}

local aex_int = sys.get_internal_table()
local hal  = aex_int.hal
local boot = aex_int.boot

local tty_write = hal.serial.write
local tty_read  = hal.serial.read
local tty_clear = hal.serial.clear

local devid = 0

local function enable_internal()

    for _, id in pairs(hal.serial.get_all_ids()) do

        sys.add_device('ttyS' .. devid, {
            open = function(self)
                tty_clear(id)
                return true
            end,
            write = function(self, str)
                tty_write(id, str)
            end,
            read = function(self, len)
                local b, c = '', ''
                if not len or len == '*a' then
                    while #b == 0 do
                        b = b .. tty_read(id)
                        waitOne()
                    end
                    return b
                else
                    while #b < len do
                        b = b .. tty_read(id, len - #b)
                        waitOne()
                    end
                    return b
                end
            end,
        }, 'ttyS')
        sys.drvmgr_claim('ttyS' .. devid, driver)

        devid = devid + 1
        ::xcontinue::
    end
end

function load()

end
function unload()

end
function enable()
    enable_internal()
    return true
end
function disable()
    return false
end