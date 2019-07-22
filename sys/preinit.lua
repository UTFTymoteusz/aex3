--@EXT lib
local aex_int = sys.get_internal_table()

local tty = aex_int.boot.tty

if sys.fs_exists('/cfg/fstab') then
    tty.writeln('Mounting storage devices defined in /cfg/fstab')

    local fd = sys.fs_open('/cfg/fstab')
    local str = fd:read('*a')
    fd:close()

    for k, v in pairs(string.split(str, '\n')) do
        v = string.trim(v)
        if   #v == 0   then goto xcont end
        if v[1] == '#' then goto xcont end

        local exp = string.split(v, ' ')
        if #exp ~= 2 then
            tty.writeln('Line ' .. k .. ': Invalid amount of arguments')
            goto xcont
        end

        local fd = sys.fs_open(exp[1], 'r')
        if        not fd        then tty.writeln('Line ' .. k .. ': ' .. v .. ' not found')                goto xcont end
        if fd.type ~= 'storage' then tty.writeln('Line ' .. k .. ': ' .. v .. ' is not an storage device') goto xcont end

        sys.fs_mount(exp[1], exp[2])
        tty.writeln('Mounted ' .. exp[1] .. ' at ' .. exp[2])

        ::xcont::
    end
else tty.writeln('/cfg/fstab not found') end

if sys.fs_exists('/cfg/hostname') then
    local f = sys.fs_open('/cfg/hostname', 'r')
    aex_int.hostname = f:read('*a')
    f:close()
end

if not sys.sec_user_exists('root') then
    aex_int.need_verify = true
end
if not aex_int.hostname then
    aex_int.need_verify = true
end

local cool_dirs = {'/cfg/', '/cfg/sys/', '/dev/', '/home/', '/mnt/', '/var/'}
for _, dir in pairs(cool_dirs) do
    if not sys.fs_exists(dir) then sys.fs_mkdir(dir) end
end

if not sys.fs_exists('/cfg/motd') then
    local f = sys.fs_open('/cfg/motd', 'w')
    f:write("Welcome to AEX/3\n#####################################\n\nIf you'd like to change the welcome message, edit /cfg/motd")
    f:flush()
    f:close()
end
if not sys.fs_exists('/cfg/sys/drv') then
    local f = sys.fs_open('/cfg/sys/drv', 'w')
    f:write("# /cfg/sys/drv: Additional drivers to load and enable on bootup\n\n")
    f:flush()
    f:close()
end
