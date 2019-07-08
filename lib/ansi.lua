--@EXT lib
local ansi = {}
local esc = string.char(27)
local function seq(cat, ...)
    local args = {...}
    for k, v in pairs(args) do
        if not v then args[k] = '' end
    end
    return esc .. cat .. table.concat(args, ';', 1, #args - 1) .. args[#args]
end
function ansi.clear()
    return seq('[', 2, 'J')
end
function ansi.cursorPos(x, y)
    return seq('[', x, y, 'H')
end
function ansi.colorFgRGB(r, g, b)
    return seq('[', 38, 2, r, g, b, 'm')
end
function ansi.colorBgRGB(r, g, b)
    return seq('[', 48, 2, r, g, b, 'm')
end
function ansi.resetg(r, g, b)
    return ansi.colorFgRGB(255, 255, 255) .. ansi.colorBgRGB(0, 0, 0) -- for now
    --return seq('[', 0, 'm')
end
function ansi.getParser()
    local state, c, b, buffer, ret = 0, nil, nil, '', nil
    return {
        feed = function(self, str)
            ret = nil

            for i = 1, #str do
                c = str[i]
                b = string.byte(c)

                if state == 0 then
                    if c == esc then
                        if #buffer > 0 then
                            if not ret then ret = {} end
                            table.add(ret, {{0, buffer}})
                            buffer = ''
                        end
                        state = 1
                        goto xcontinue
                    end
                    buffer = buffer .. c
                elseif state == 1 then
                    buffer = buffer .. c

                    if b > 59 and #buffer > 2 then
                        if not ret then ret = {} end

                        local args_p = string.split(string.sub(buffer, 2, #buffer - 1), ';')
                        for k, v in pairs(args_p) do
                            if #v == 0 then
                                args_p[k] = false
                            else args_p[k] = tonumber(v) end
                        end
                        table.add(ret, {{b, buffer[1], unpack(args_p)}})
                        buffer = ''

                        state = 0
                        goto xcontinue
                    end
                end
                ::xcontinue::
            end
            if #buffer > 0 and state == 0 then
                if not ret then ret = {} end
                table.add(ret, {{0, buffer}})
                buffer = ''
            end
            return ret
        end,
    }
end
return ansi