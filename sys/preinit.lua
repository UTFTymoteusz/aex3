--@EXT lib
local aex_int = sys.get_internal_table()

local tty = aex_int.boot.tty

if sys.fs_exists('/cfg/fstab') then
    tty.writeln('Mounting storage devices defined in /cfg/fstab')

    local fd = sys.fs_open('/cfg/fstab')
    local str = fd:read()
    fd:close()

    for k, v in pairs(string.split(str, '\n')) do
        v = string.trim(v)
        if   #v == 0   then goto xcontinue end
        if v[1] == '#' then goto xcontinue end

        local exp = string.split(v, ' ')
        if #exp ~= 2 then
            tty.writeln('Line ' .. k .. ': Invalid amount of arguments')
            goto xcontinue
        end

        local fd = sys.fs_open(exp[1], 'r')
        if      not fd      then tty.writeln('Line ' .. k .. ': ' .. v .. ' not found')                goto xcontinue end
        if fd.type ~= 'hdd' then tty.writeln('Line ' .. k .. ': ' .. v .. ' is not an storage device') goto xcontinue end

        sys.fs_mount(exp[1], exp[2])
        tty.writeln('Mounted ' .. exp[1] .. ' at ' .. exp[2])

        ::xcontinue::
    end
else tty.writeln('/cfg/fstab not found') end

if sys.fs_exists('/cfg/hostname') then
    local f = sys.fs_open('/cfg/hostname', 'r')
    aex_int.hostname = f:read()
    f:close()
end

if not sys.sec_user_exists('root') then
    aex_int.need_verify = true
end
if not aex_int.hostname then
    aex_int.need_verify = true
end

local cool_dirs = {'/dev/', '/home/', '/mnt/', '/var/'}
for _, dir in pairs(cool_dirs) do
    if not sys.fs_exists(dir) then sys.fs_mkdir(dir) end
end

if not sys.fs_exists('/cfg/motd') then
    local f = sys.fs_open('/cfg/motd', 'w')
    f:write("Welcome to AEX/3\r\n#####################################\r\n\r\nIf you'd like to change the welcome message, edit /cfg/motd")
    f:close()
end
