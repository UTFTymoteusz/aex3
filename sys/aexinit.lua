local ansi = require('ansi')
local fs   = require('fs')
local proc = require('proc')
io.write(ansi.clear())

if not fs.exists('/cfg/init/tty') then
    fs.write('/cfg/init/tty', '# /cfg/init/tty: tty devices to start logon on.\n\n/dev/tty0\n/dev/invalidtty')
    io.writeln('Created default config tty file (/cfg/init/tty)')
end

local daemonh = proc.create('/sys/daemonh.lua')
daemonh:start()
io.writeln('daemonh started')

local srv = {}
local fds = {}

io.writeln('Using devices defined in /cfg/init/tty')
for k, v in pairs(fs.readln('/cfg/init/tty')) do
    v = string.trim(v)
    if   #v == 0   then goto xcont end
    if v[1] == '#' then goto xcont end

    if not fs.exists(v) then
        io.writeln('Line ' .. k .. ': ' .. v .. ' not found')
        goto xcont
    end 
    local fd = fs.open(v, 'rw')

    if fd.type ~= 'tty' then
        io.writeln('Line ' .. k .. ': ' .. v .. ' is not an tty')
    end
    ::xcont::
end
for k, v in pairs(fs.readln('/cfg/init/tty')) do
    v = string.trim(v)
    if   #v == 0   then goto xcont end
    if v[1] == '#' then goto xcont end

    if not fs.exists(v) then
        goto xcont
    end
    local fd = fs.open(v, 'rw')

    if fd.type ~= 'tty' then
        goto xcont
    end
    local np = proc.create('/bin/login.lua')
    np.stdin:bind(fd)
    np.stdout:bind(fd)
    np.stderr:bind(fd)

    sleep(500)
    np:start()

    srv[v] = np
    fds[v] = fd

    ::xcont::
end
while true do
    sleep(1000)

    for k, v in pairs(srv) do
        if not v:isAlive() then
            sleep(1000)
            local fd = fds[k]

            local np = proc.create('/bin/login.lua')
            np.stdin:bind(fd)
            np.stdout:bind(fd)
            np.stderr:bind(fd)

            np:start()

            srv[k] = np
        end
    end
end