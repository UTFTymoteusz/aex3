--@EXT drv
local aex_int = sys.get_internal_table()
local hal  = aex_int.hal
local boot = aex_int.boot

local tty_write = hal.serial.write
local tty_read  = hal.serial.read
local tty_clear = hal.serial.clear

local devid = 0

local driver = {}

local function enable()

    for _, id in pairs(hal.serial.get_all_ids()) do

        sys.add_device('ttyS' .. devid, function()
            tty_clear(id)
            return {
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
            }
        end)
        sys.mark_device('ttyS' .. devid, 'ttyS')
        sys.drvmgr_claim('ttyS' .. devid, driver)

        devid = devid + 1
        ::xcontinue::
    end
end

driver.full_name = 'Serial Hub Driver'
driver.name = 'ttySh'
driver.type = 'hub'
driver.provider = 'Tymkboi'
driver.version  = '1.0'
driver.disallow_disable = true

function driver.load()

end
function driver.unload()

end
function driver.enable()
    enable()
    return true
end
function driver.disable()
    return false
end

return driver