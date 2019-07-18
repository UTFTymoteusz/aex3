--@EXT lib
local x, y = 0, 0
local xsize = rh.ScreenX
local ysize = rh.ScreenY
local gpu = rh.GPU

local function putchar(byte)
    if byte == 10 then     
        x = 0
        y = y + 1
    elseif byte == 13 then x = 0
    elseif byte == 8 then
        if x > 0 then
            x = x - 1
            gpu[x + (y * xsize)] = 32
        end
    else
        gpu[x + (y * xsize)] = byte
        x = x + 1
        if x == xsize then
            x = 0
            y = y + 1
        end
    end
end

local ansi_p

local tty = {}
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
                        putchar(string.byte(str[i]))
                    end
                else
                    if i == 72 then
                        if v[2] == '[' then
                            if v[3] then x = v[3] - 1 end
                            if v[4] then y = v[4] - 1 end
                        end
                    elseif i == 74 then
                        if v[2] == '[' then tty.clear() end
                    elseif i == 109 then
                        if v[2] == '[' then
                            if v[3] == 38 then
                                if v[4] == 2 then rh.GPU:SetFGColor(v[5], v[6], v[7]) end
                            elseif v[3] == 48 then
                                if v[4] == 2 then rh.GPU:SetBGColor(v[5], v[6], v[7]) end
                            end
                        end
                    else printTable(v) end
                end
            end
        end
        return
    end

    str = tostring(str)
    for i = 1, #str do
        putchar(string.byte(str[i]))
    end
end
function tty.writeln(str)
    str = tostring(str)
    tty.write(str or '')
    tty.write('\r\n')
end
function tty.clear()
    rh.GPU:Clear()
    x, y = 0, 0
end
return tty