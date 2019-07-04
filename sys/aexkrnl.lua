local aex_int = {
    boot = {
        kind     = boot.kind,
        readFile = boot.readFile,
        drive_id = boot.boot_drive_id,
        drive_name = '',
        tty      = nil,
    },
    dev       = {},
    dev_marks = {},
    mounts    = {},
    processes = {},
    threads_k = {},
    next_thread_k_id = 1,
}
local boot_kind = boot.kind

local function halt()
    repeat coroutine.wait(1)
    until false
end
waitOne = coroutine.yield
function sleep(ms)
    coroutine.wait(ms * 0.001)
end

local function seq(cat, ...)
    local args = {...}
    for k, v in pairs(args) do
        if not v then args[k] = '' end
    end
    return string.char(27) .. cat .. table.concat(args, ';', 1, #args - 1) .. args[#args]
end
local function rgb(r, g, b)
    local g = g
    local b = b
    if not g and not b then g, b = r, r end
    return seq('[', 38, 2, r, g, b, 'm')
end

function aex_int.assertType(val, typec, ignore_nil)
    if not val then 
        if ignore_nil then return end 
        error(string.format('Expected %s, got nil', typec), 3) 
    end
    if type(val) ~= typec then error(string.format('Expected %s, got %s', typec, type(val)), 3) end
end

local    log = {}
function log.none()   return '          ' end
function log.wait()   return rgb(127) .. ' [' .. rgb(225,225,0) .. ' WAIT ' .. rgb(127) .. '] ' .. rgb(255) end
function log.ok()     return rgb(127) .. ' [' .. rgb(0,225,0) ..   '  OK  ' .. rgb(127) .. '] ' .. rgb(255) end
function log.fail()   return rgb(127) .. ' [' .. rgb(225,0,0) ..   ' FAIL ' .. rgb(127) .. '] ' .. rgb(255) end
function log.load()   return rgb(127) .. ' [' .. rgb(0,225,225) .. ' LOAD ' .. rgb(127) .. '] ' .. rgb(255) end
function log.device() return rgb(127) .. ' [' .. rgb(225,127,0) .. 'DEVICE' .. rgb(127) .. '] ' .. rgb(255) end
function log.pad(i)   return string.rep(' ', i) end

aex_int.log = log

sys = {} -- syscalls, hooray
function sys.get_internal_table()
    return aex_int
end
function sys.add_device(name, open_cb)
    aex_int.assertType(name, 'string')
    aex_int.assertType(open_cb,  'function')
    aex_int.assertType(ioctl_cb, 'function', true)

    if string.sub(name, 1, 5) ~= '/dev/' then
        name = '/dev/' .. name
    end

    aex_int.dev[name] = open_cb
    aex_int.dev_marks[name] = 'generic'

    aex_int.boot.tty.writeln(log.device() .. 'Added ' .. name)

    return true
end
function sys.mark_device(name, type)
    if not name or not type then error('sys.mark_device: Missing arguments') end
    if string.sub(name, 1, 5) ~= '/dev/' then
        name = '/dev/' .. name
    end
    type = string.lower(type)
    aex_int.dev_marks[name] = type

    return true
end
function sys.reset()
    aex_int.hal.core.reset()
end

local ansi_p
local function init_tty0()
    local tty = {}

    if boot_kind == 'net_rh_emu' then
        local x, y = 0, 0
        local xsize = rh.ScreenX
        local ysize = rh.ScreenY
        local gpu = rh.GPU

        local function putchar(byte)
            if byte == 10 then     y = y + 1
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
    end

    if not tty.clear then   function tty.clear() end end
    if not tty.writeln then function tty.writeln() end end
    if not tty.write then   function tty.write() end end

    return tty
end
local tty_i = init_tty0()
aex_int.boot.tty = tty_i

tty_i.clear()
tty_i.writeln('|##### |#### \\#  /#   |#####')
tty_i.writeln('|#   # |#     \\#/#        |#')
tty_i.writeln('|##### |####   \\#     |#####')
tty_i.writeln('|#   # |#     /#\\#        |#')
tty_i.writeln('|#   # |#### /#  \\#   |#####')
tty_i.writeln(log.pad(4) .. 'Booting AEX/3')

local function readFile(path)
    if sys.fs_open then
        local f = sys.fs_open(path, 'r')
        if not f then return nil end
        return f:read(), f:close()
    end
    return aex_int.boot.readFile(path)
end
aex_int.readFile = readFile

local function loadSafe(code)
    code, rr = loadstring(code, path)

    if not code then tty_i.writeln(log.fail() .. rr) halt()
    elseif type(code) == 'string' then tty_i.writeln(log.fail() ..tostring(code)) halt()
    else
        setfenv(code, getfenv())

        local s, r, ax, bx, cx, dx = pcall(code)
        if not s then tty_i.writeln(log.fail() .. tostring(r)) halt() end
        return r, ax, bx, cx, dx
    end
end
aex_int.loadSafe = loadSafe

local function loadModuleSafe(path)
    local code = readFile(path)
    tty_i.writeln(log.pad(1) .. path)

    return loadSafe(code)
end

ansi_p = loadSafe(readFile('/lib/ansi.lib')).getParser()
tty_i.write(seq('[', 38, 2, 255, 255, 255, 'm'))
tty_i.writeln(log.ok() .. '/dev/tty0 upgraded')

tty_i.writeln('Loading the HAL')
loadModuleSafe('/sys/hal.lib')
tty_i.writeln(log.ok() .. 'HAL loaded')

local envinit_e = readFile('/sys/envinit.e/' .. boot_kind .. '.lib')
if envinit_e then
    loadSafe(envinit_e)
    tty_i.writeln(log.ok()   .. 'Executed early init for ' .. boot_kind)
else tty_i.writeln(log.none() .. 'No early init found for ' .. boot_kind) end

tty_i.writeln('Enumerating hardware')
loadModuleSafe('/sys/drv/ram.drv')
loadModuleSafe('/sys/drv/hddh.drv')

local tty_input_buffer = ''
do 
    local x, y = 0, 0
    sys.add_device('tty0', function()
        return {
            read = function(self, len)
                if not len then
                    while #tty_input_buffer == 0 do waitOne() end

                    local a = tty_input_buffer
                    tty_input_buffer = ''
                    return a
                else
                    while #tty_input_buffer < len do waitOne() end

                    local a = string.sub(tty_input_buffer, 1, len)
                    tty_input_buffer = string.sub(tty_input_buffer, len + 1)
                    return a
                end
            end,
            write = function(self, data)
                tty_i.write(data)
            end,
            setSize = function(self, nx, ny)
                x, y = nx, ny
                return true
            end,
            getSize = function(self)
                return x, y
            end,
        } 
    end)
    sys.mark_device('tty0', 'tty')
end
tty_i.writeln(log.ok() .. 'Hardware enumeration complete')
tty_i.writeln('')

tty_i.writeln('Loading core modules')
loadModuleSafe('/sys/core/fs.km')

sys.fs_mount(aex_int.boot.drive_name, '/')
tty_i.writeln(log.ok() .. 'Mounted ' .. aex_int.boot.drive_name .. ' at /')

loadModuleSafe('/sys/core/res.km')
loadModuleSafe('/sys/core/proc.km')
loadModuleSafe('/sys/core/io.km')
loadModuleSafe('/sys/core/req.km')
loadModuleSafe('/sys/core/sec.km')
loadModuleSafe('/sys/core/input.km')
loadModuleSafe('/sys/core/func.km')
tty_i.writeln(log.ok() .. 'Core modules loaded')
tty_i.writeln('')

local envinit_p = readFile('/sys/envinit.p/' .. boot_kind .. '.lib')
if envinit_p then
    loadSafe(envinit_p)
    tty_i.writeln(log.ok()   .. 'Executed post init for ' .. boot_kind)
else tty_i.writeln(log.none() .. 'No post init found for ' .. boot_kind) end

sys.thread_create(function() 
    while true do
        waitOne()
        
        keys = sys.input_get_keys()
        if not keys then goto xcontinue end

        tty_input_buffer = tty_input_buffer .. string.char(unpack(keys))
        ::xcontinue::
    end
end)
tty_i.writeln(log.ok() .. '/dev/tty0 input routine started')

aex_int.sec.init()
tty_i.writeln(log.ok() .. 'Security subsystem initialized')

loadSafe(readFile('/sys/preinit.lib'))
tty_i.writeln(log.ok() .. 'preinit executed')

local tty0 = sys.fs_open('/dev/tty0')

local initp_ctrl, err

if not aex_int.need_verify then
    tty_i.writeln('Starting aexinit.lua')
    initp_ctrl, err = sys.process_create('/sys/aexinit.lua')

    if not initp_ctrl then tty_i.writeln(log.fail() .. 'aexinit: ' .. err) end
else
    tty_i.writeln('Starting aexvrfy.lua')
    initp_ctrl, err = sys.process_create('/sys/aexvrfy.lua')

    if not initp_ctrl then tty_i.writeln(log.fail() .. 'aexvrfy: ' .. err) end
end
initp_ctrl.stdin:bind(tty0)
initp_ctrl.stdout:bind(tty0)
initp_ctrl.stderr:bind(tty0)

initp_ctrl:start()

aex_int.started = true

tty_i.writeln('Starting task switching')
aex_int.proc.begin_task_loop()

tty_i.writeln(log.fail() .. 'Halted')
halt()