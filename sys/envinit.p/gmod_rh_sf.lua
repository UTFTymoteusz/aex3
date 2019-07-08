--@EXT lib
local aex_int = sys.get_internal_table()
local s, r = sys.drvmgr_load('/sys/drv/gwirekb.drv')
if not s then 
    aex_int.printk(r)
    sleep(1000)
end

local dev = sys.fs_open('/dev/tty0')
dev:setSize(127, 51)
dev:close()