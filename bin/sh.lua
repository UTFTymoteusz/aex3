local ansi = require('ansi')
local fs   = require('fs')
local os   = require('os')
local proc = require('proc')
local res  = require('res')
local sh   = require('sh')
local thread = require('thread')

proc.registerSignalHandler('stop', function() return true end)

local current_dir = '/'

if fs.exists('/home/' .. sh.getUser() .. '/') then current_dir = '/home/' .. sh.getUser() .. '/' end

local function exec(entry)
    local paths = {
        '/bin/%f',
        '/bin/%f.lua',
        current_dir .. '%f',
        current_dir .. '%f.lua',
    }
    local tokens, exec = {}, {}
    local ptr, c, strbuf = 0, nil, ''

    local function verify()
        if #strbuf > 0 then
            if strbuf == ';' or strbuf == '|' or strbuf == '>>' or strbuf == '<<' or strbuf == '>' or strbuf == '<' then
                tokens[#tokens + 1] = {str = strbuf, type = 'key'}
            else
                tokens[#tokens + 1] = {str = strbuf, type = 'str'}
            end
            strbuf = ''
        end
    end
    while ptr < #entry do
        ptr = ptr + 1
        c = entry[ptr]

        if c == ' ' then
            verify()
        elseif c == '"' then
            while ptr < #entry do
                ptr = ptr + 1
                c = entry[ptr]

                if c == '\\' then
                    ptr = ptr + 1
                    strbuf = strbuf .. entry[ptr]
                elseif c == '"' then
                    break
                else
                    strbuf = strbuf .. c
                end
            end
        else strbuf = strbuf .. c end
    end
    verify()

    local exb = {}
    local function fin()
        local args = table.copy(exb)
        table.remove(args, 1)

        local bin, p = nil
        for k, v in pairs(paths) do
            p = string.replace(v, '%f', exb[1])
            if fs.exists(p) then
                bin = p
                break
            end
        end

        if not bin then return false, string.format("sh: '%s' not found", exb[1]) end
        exec[#exec + 1] = {bin = bin, args = args}

        return true
    end
    for k, v in pairs(tokens) do
        if v.type == 'key' then
            if v.str == '|' or v.str == ';' then local s, r = fin() if not s then return s, r end -- to do
            else

            end
        else exb[#exb + 1] = v.str end
    end
    local s, r = fin()
    if not s then return s, r end

    for k, v in pairs(exec) do
        if fs.getExtension(v.bin) ~= 'lua' then io.writeln('sh: ' .. v.bin .. ': Not an executable') goto xcontinue end

        local pp, err = proc.create(v.bin, v.args, current_dir)

        if type(err) == 'number' then err = res.translate(err) end
        if not pp then io.writeln('sh: ' .. v.bin .. ': ' .. (err or 'Unknown error')) goto xcontinue end

        local input_th = thread.create(function()
            local c, b
            while true do
                c = io.read(1)
                if #c == 0 then return end

                b = string.byte(c)

                if (b == 3) then
                    io.write('^C')
                    pp:stop()
                elseif (b == 23) then
                    io.write('^W')
                    pp:abort()
                else pp.stdin:write(c) end
            end
        end)
        pp.stdout:bind(io.stdout)
        pp.stderr:bind(io.stderr)

        pp:start()
        pp:wait()

        input_th:abort()

        ::xcontinue::
    end
    return true
end
local corefuncs = {}
function corefuncs.cd(args)
    local dir = table.concat(args, " ")
    local origdir = dir
    dir = fs.translate(current_dir, dir)

    io.writeln()
    if dir[#dir] ~= '/' then dir = dir .. '/' end
    if not fs.exists(dir) then
        stderr:writeln('sh: cd: ' .. origdir .. ': No such file or directory')
    else current_dir = dir end
end
function corefuncs.whoami(args)
    io.writeln()
    io.writeln(sh.getUser())
end
function corefuncs.tty(args)
    io.writeln()
    io.writeln(sh.getTTY())
end
function corefuncs.cls()
    io.write(ansi.clear(), ansi.cursorPos(1, 1))
end
corefuncs.clear = corefuncs.cls
while true do
    io.write('\r', ansi.colorFgRGB(0,255,0), sh.getUser() .. '@' .. os.getHostname(), ansi.resetg(), ':', ansi.colorFgRGB(0,0,255), current_dir, ansi.resetg(), ' ')

    local str = io.readln(true)
    if #str == 0 then goto xcontinue end

    do
        local c = string.trim(str)
        if c == 'exit' then
            io.writeln()
            return
        else
            args = string.split(str, ' ')
            local cmd = args[1]
            table.remove(args, 1)

            if corefuncs[cmd] then
                corefuncs[cmd](args)
                goto xcontinue
            end
        end
    end

    io.writeln()
    local s, r = exec(str)

    if not s then io.writeln(r) end

    --io.writeln() -- make this smarter later
    ::xcontinue::
end