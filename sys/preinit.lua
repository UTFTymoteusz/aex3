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
        if fd.type ~= 'hdd' then
            tty.writeln('Line ' .. k .. ': ' .. v .. ' is not an storage device')
            goto xcontinue
        end

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
if not sys.fs_exists('/dev/') then
    sys.fs_mkdir('/dev/')
end
if not sys.fs_exists('/home/') then
    sys.fs_mkdir('/home/')
end