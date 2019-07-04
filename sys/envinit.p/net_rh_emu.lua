--@EXT lib
local aex_int = sys.get_internal_table()

aex_int.loadSafe(aex_int.readFile('/sys/drv/netkb.drv'))

do 
    sys.thread_create(function()
        local lastx, lasty
        local dev = sys.fs_open('/dev/tty0')
        while true do
            if (rh.ScreenX ~= lastx) or (rh.ScreenY ~= lasty) then
                lastx, lasty = rh.ScreenX, rh.ScreenY
                dev:setSize(lastx, lasty)
            end
            waitOne()
        end
    end)
end