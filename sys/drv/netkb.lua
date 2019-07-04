--@EXT drv
sys.thread_create(function()
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