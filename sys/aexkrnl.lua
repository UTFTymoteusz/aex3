local aex_int = {
    boot = {
        kind     = boot.kind,
        readFile = boot.readFile,
        drive_id = boot.boot_drive_id,
        drive_name = '',
        tty      = nil,
    },
    dev        = {},
    dev_marks  = {},
    dev_smarks = {},

    drivers   = {},
    driver_id_counter = 0,

    mounts    = {},

    processes = {},
    threads_k = {},
    next_thread_k_id = 1,
}
local boot_kind = boot.kind
local tty_i = {
    writeln = function(str) end
}

local function halt()
    repeat coroutine.wait(1)
    until false
end
waitOne = coroutine.yield
local c_wait = coroutine.wait
function sleep(ms)
    c_wait(ms * 0.001)
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
function aex_int.runInKernel(func)
    aex_int.next_thread_k_id = aex_int.next_thread_k_id + 1

    local id = aex_int.next_thread_k_id
    local s, r, a, b, c, d

    aex_int.threads_k[id] = coroutine.create(function()
        s, r, a, b, c, d = pcall(func)
        if not s then r, a, b, c, d = nil, nil, nil, nil, nil end
    end)

    while aex_int.threads_k[id] do waitOne() end
    return r, a, b, c, d
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
function sys.add_device(name, method_table, type, subtype)
    aex_int.assertType(name, 'string')
    aex_int.assertType(method_table, 'table')
    aex_int.assertType(type, 'string', true)
    aex_int.assertType(subtype, 'string', true)

    if string.sub(name, 1, 5) ~= '/dev/' then name = '/dev/' .. name end

    aex_int.dev[name] = method_table
    type = type or 'generic'
    type = string.lower(type)
    aex_int.dev_marks[name] = type
    aex_int.dev_smarks[name] = subtype

    aex_int.printk(log.device() .. 'Added ' .. name)
    return true
end
function sys.remove_device(name)
    aex_int.assertType(name, 'string')

    if string.sub(name, 1, 5) ~= '/dev/' then name = '/dev/' .. name end

    aex_int.dev[name] = nil
    aex_int.dev_marks[name] = nil

    aex_int.printk(log.device() .. 'Removed ' .. name)
    return true
end
function sys.reset()
    aex_int.hal.core.reset()
end

local function readFile(path)
    if sys.fs_open then
        local f = sys.fs_open(path, 'r')
        if not f then return nil end
        return f:read('*a'), f:close()
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

    waitOne()
    return loadSafe(code)
end

local ansi_p
local function init_tty0()
    local tty = loadModuleSafe('/sys/ttyinit/' .. boot_kind .. '.lib')

    if not tty.setAnsi then function tty.setAnsi() end end
    if not tty.clear then   function tty.clear() end end
    if not tty.writeln then function tty.writeln() end end
    if not tty.write then   function tty.write() end end

    return tty
end
tty_i = init_tty0()
aex_int.boot.tty = tty_i
aex_int.printk = function(str)
    if aex_int.started then return end
    tty_i.writeln(str)
end,

tty_i.clear()
tty_i.writeln('|##### |#### \\#  /#   |#####')
tty_i.writeln('|#   # |#     \\#/#        |#')
tty_i.writeln('|##### |####   \\#     |#####')
tty_i.writeln('|#   # |#     /#\\#        |#')
tty_i.writeln('|#   # |#### /#  \\#   |#####')
tty_i.writeln(log.pad(4) .. 'Booting AEX/3')

local function loadDriver(path, _halt)

    tty_i.writeln(' Driver: ' .. path)

    local r, msg = sys.drvmgr_load(path)
    if not r then 
        tty_i.writeln(msg) 
        sleep(2000)

        if _halt then halt()
        else return end
    end
    tty_i.writeln(log.load() .. 'Loaded "' .. sys.drvmgr_info(r).full_name .. '" driver')
end

tty_i.setAnsi(loadSafe(readFile('/lib/ansi.lib')).getParser())
tty_i.write(seq('[', 38, 2, 255, 255, 255, 'm'))
tty_i.writeln(log.ok() .. '/dev/tty0 upgraded')

tty_i.writeln('Loading the HAL')
loadModuleSafe('/sys/hal.lib')
tty_i.writeln(log.ok() .. 'HAL loaded')

tty_i.writeln('Loading drvmgr')
loadModuleSafe('/sys/drvmgr.lib')
tty_i.writeln(log.ok() .. 'drvmgr loaded')

local envinit_e = readFile('/sys/envinit.e/' .. boot_kind .. '.lib')
if envinit_e then
    loadSafe(envinit_e)
    tty_i.writeln(log.ok()   .. 'Executed early init for ' .. boot_kind)
else tty_i.writeln(log.none() .. 'No early init found for ' .. boot_kind) end

tty_i.writeln('Enumerating hardware and loading drivers')
loadDriver('/sys/drv/ram.drv', true)
loadDriver('/sys/drv/hddh.drv', true)
loadDriver('/sys/drv/ttySh.drv', true)

local tty_input_buffer = ''
do
    local write = tty_i.write

    local x, y = 0, 0
    sys.add_device('tty0', {
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
            write(data)
        end,
        setSize = function(self, nx, ny)
            x, y = nx, ny
            return true
        end,
        getSize = function(self)
            return x, y
        end,
    }, 'tty')
end
tty_i.writeln(log.ok() .. 'Hardware enumeration complete')

local add_drivers = readFile('/cfg/sys/drv')
if add_drivers then
    tty_i.writeln('Loading additional drivers')

    for k, v in pairs(string.split(add_drivers, '\n')) do
        v = string.trim(v)
        if   #v == 0   then goto xcontinue end
        if v[1] == '#' then goto xcontinue end
    
        loadDriver(v)
        ::xcontinue::
    end
    tty_i.writeln(log.ok() .. 'Additional drivers loaded')
end
tty_i.writeln('')

tty_i.writeln('Loading core modules')
loadModuleSafe('/sys/core/syshook.sys')
loadModuleSafe('/sys/core/fs.sys')

sys.fs_mount(aex_int.boot.drive_name, '/')
tty_i.writeln(log.ok() .. 'Mounted ' .. aex_int.boot.drive_name .. ' at /')

loadModuleSafe('/sys/core/res.sys')
loadModuleSafe('/sys/core/proc.sys')
loadModuleSafe('/sys/core/io.sys')
loadModuleSafe('/sys/core/req.sys')
loadModuleSafe('/sys/core/sec.sys')
loadModuleSafe('/sys/core/input.sys')
loadModuleSafe('/sys/core/func.sys')
loadModuleSafe('/sys/core/sig.sys')
tty_i.writeln(log.ok() .. 'Core modules loaded')
tty_i.writeln('')

local envinit_p = readFile('/sys/envinit.p/' .. boot_kind .. '.lib')
if envinit_p then
    loadSafe(envinit_p)
    tty_i.writeln(log.ok()   .. 'Executed post init for ' .. boot_kind)
else tty_i.writeln(log.none() .. 'No post init found for ' .. boot_kind) end

tty_i.writeln('Loading extra drivers')
loadDriver('/sys/drv/pdevs.drv', true)

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

    if not initp_ctrl then tty_i.writeln(log.fail() .. 'aexinit: ' .. err) halt() end
else
    tty_i.writeln('Starting aexvrfy.lua')
    initp_ctrl, err = sys.process_create('/sys/aexvrfy.lua')

    if not initp_ctrl then tty_i.writeln(log.fail() .. 'aexvrfy: ' .. err) halt() end
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