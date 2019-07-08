--@EXT drv
local thread
local driver = {}

driver.full_name = '.NET Keyboard Bridge'
driver.name = 'netkb'
driver.type = 'input'
driver.provider = 'Tymkboi'
driver.version  = '1.0'

function driver.load()

end
function driver.unload()

end
function driver.enable()
    thread = sys.thread_create(function()
        local kb_t = sys.input_add_device('netkb')
        local ckeys, bkeys, act = {}, {}

        local tt, key, ev
        while true do
            ev = rh.Input:LastEvent()

            if not ev then waitOne()
            else
                tt, key = ev[0], ev[1]

                if tt then kb_t:keyPress(key)
                else kb_t:keyRelease(key) end
            end
        end
    end)
    return true
end
function driver.disable()
    thread:abort()
    return true
end

return driver