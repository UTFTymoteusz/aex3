local fs   = require('fs')
local sh   = require('sh')
local ansi = require('ansi')
local proc = require('proc')
local res  = require('res')

local p = sh.parseArgs(sh.getArgs())
local args = p.args

local sx, sy = io.stdout:getSize()
local cx, cy = 1, 1
local scroll = 0

local buffer = {''}
local file = args[1]

local status_last_len = 0

proc.registerSignalHandler('stop', function() return true end)

if not file then
    stderr:writeln('edit: No filename specified')
    return
end
if fs.exists(file) then
    buffer, rr = fs.readln(args[1])

    if not buffer then
        io.write(ansi.clear(), ansi.cursorPos(2, 2), '! Error reading file: ' .. res.translate(rr) .. ' !')
        sleep(2000)

        return
    end
end

local function clear()
    io.write(ansi.clear())
end
local function drawPosition(add)
    if add then
        add = add .. '  '
        status_last_len = #add
    else
        add = string.rep(' ', status_last_len)
        status_last_len = 0
    end

    local str = string.format(add .. '^S Save ^C Exit  %i, %i  ', cx, cy)
    io.write(ansi.cursorPos(sx - #str + 1, sy), str)
end
local function cursor()
    drawPosition()
    io.write(ansi.cursorPos(cx, cy - scroll))
end
local function drawStatusBar()
    local str = '  Editing: ' .. file
    io.write(ansi.cursorPos(1, sy), str .. string.rep(' ', sx - #str))
    drawPosition()
end
local function drawLine(y, clear)

    io.write(ansi.cursorPos(1, y - scroll))
    io.write(string.sub((buffer[y] or '') .. '  ', 1, sx))

    if clear then
        io.write(string.rep(' ', sx - #(buffer[y] or '') - 2))
    end
end
local function drawLines()
    io.write(ansi.cursorPos(1, 1))

    for i = 1 + scroll, sy - 1 + scroll do

        if buffer[i] then
            io.writeln(string.sub(buffer[i], 1, sx))
        end
    end
end

local function scrollUp()
    scroll = scroll - 1

    io.write(ansi.scrollDown(1))
    drawLine(1 + scroll, true)
end
local function scrollDown()
    scroll = scroll + 1

    io.write(ansi.scrollUp(1))
    drawLine(sy + scroll - 1, true)
end

local s_byte  = string.byte
local m_clamp = math.clamp

local function moveUp(amnt)
    local amnt = amnt or 1

    for i = 1, amnt do
        cy = m_clamp(cy - 1, 1, #buffer)

        if cy > 2 and ((cy - scroll) < 3) then
            scrollUp()
        end
        if cy == 1 then break end
    end
    drawStatusBar()
    cursor()
end
local function moveDown(amnt)
    local amnt = amnt or 1

    for i = 1, amnt do
        cy = m_clamp(cy + 1, 1, #buffer)

        if (cy - scroll) > (sy - 3) then
            scrollDown()
        end
        if cy == #buffer then break end
    end
    drawStatusBar()
    cursor()
end

clear()
drawLines()
drawStatusBar()
cursor()

local k, b, line
while true do

    k = io.read()
    b = s_byte(k)

    if b >= 32 and b <= 126 then
        cx = m_clamp(cx, 1, #buffer[cy] + 1)

        line = buffer[cy]
        buffer[cy] = string.sub(line, 1, cx - 1) .. k .. string.sub(line, cx)
        cx = cx + 1

        drawLine(cy)
        cursor()
    elseif b == 8 then
        cx = m_clamp(cx, 1, #buffer[cy] + 1)
        line = buffer[cy]

        if cx == 1 then

            if cy > 1 then
                cx = #buffer[cy - 1] + 1
                buffer[cy - 1] = buffer[cy - 1] .. buffer[cy]
                table.remove(buffer, cy)
                cy = m_clamp(cy - 1, 1, #buffer)

                clear()
                drawLines()
                drawStatusBar()
                cursor()
            end
        else
            buffer[cy] = string.sub(line, 1, cx - 2) .. string.sub(line, cx)
            cx = m_clamp(cx - 1, 1, #buffer[cy] + 1)

            drawLine(cy)
            cursor()
        end
    elseif b == 10 or b == 13 then
        line = buffer[cy]

        buffer[cy] = string.sub(line, 1, cx - 1)
        table.insert(buffer, cy + 1, string.sub(line, cx))

        cx = 1
        cy = m_clamp(cy + 1, 1, #buffer)

        clear()
        drawLines()
        drawStatusBar()
        cursor()
    elseif b == 252 then -- arrow up
        moveUp()
    elseif b == 253 then -- arrow down
        moveDown()
    elseif b == 254 then -- arrow left
        cx = m_clamp(cx - 1, 1, #buffer[cy] + 1)
        cursor()
    elseif b == 255 then -- arrow right
        cx = m_clamp(cx + 1, 1, #buffer[cy] + 1)
        cursor()
    elseif b == 151 then -- arrow up
        moveUp(12)
    elseif b == 152 then -- arrow down
        moveDown(12)
    elseif b == 19 then
        local df, rr = fs.open(file, 'w')

        if not df then
            drawPosition('Failed to save: ' .. res.translate(rr))
        else
            for k, v in pairs(buffer) do
                df:write(v)

                if k == #buffer then break end
                df:write('\n')
            end

            df:flush()
            df:close()
            drawPosition('Saved!')
        end
    end
end