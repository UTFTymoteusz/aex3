--@EXT lib
local ansi_p

local tty = {}
if chipset.Components.GPU then
    gpu = wire.getWirelink(chipset.Components.GPU[1])

    local x, y = 0, 0
    local function putchar(byte)
        if byte == 10 then
            x = 0
            y = y + 1
        elseif byte == 13 then
            x = 0
        elseif byte == 8 then
            if x > 0 then
                x = x - 1
                gpu[x + (y * 127)] = 32
            end
        else
            if x == 127 then
                x = 0
                y = y + 1
            end

            gpu[x + (y * 127)] = byte
            x = x + 1
        end
        if y > 50 then
            y = 50
            gpu[0xFFFF] = 0x10
        end
        gpu[0xFFFC] = x + (y * 127)
    end

    local s_byte = string.byte

    function tty.setAnsi(tbl)
        ansi_p = tbl
    end
    function tty.write(str)
        if ansi_p then
            local a = ansi_p:feed(str)
            if a then
                local i = 0
                for k, v in pairs(a) do
                    i = v[1]
                    if i == 0 then
                        local str = v[2]
                        for i = 1, #str do
                            putchar(s_byte(str[i]))
                        end
                    else
                        if i == 72 then
                            if v[2] == '[' then
                                if v[3] then x = v[3] - 1 end
                                if v[4] then y = v[4] - 1 end

                                gpu[0xFFFC] = x + (y * 127)
                            end
                        elseif i == 74 then
                            if v[2] == '[' then
                                tty.clear()
                            end
                        elseif i == 83 then
                            if v[2] == '[' then
                                -- scroll up
                                local amnt = v[3] or 1
                                
                                for i = 1, amnt do gpu[0xFFFF] = 0x10 end
                            end
                        elseif i == 84 then
                            if v[2] == '[' then
                                -- scroll down
                                local amnt = v[3] or 1
                                
                                for i = 1, amnt do gpu[0xFFFF] = 0x11 end
                            end
                        else
                            --printTable(v)
                        end
                    end
                end
            end
            return
        end

        str = tostring(str)
        for i = 1, #str do
            putchar(s_byte(str[i]))
        end
    end
    function tty.writeln(str)
        str = tostring(str)
        tty.write(str or '')
        tty.write('\r\n')
    end
    function tty.clear()
        gpu[0xFFFF] = 0x21
        x, y = 0, 0
    end
end
return tty