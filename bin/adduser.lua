local sh  = require('sh')
local sec = require('sec')

if sh.getUser() ~= 'root' then
    stderr:writeln('adduser: Must be root')
end

local args = sh.getArgs()

if not args[1] then
    stderr:write('adduser: Username required\r\n')
    return
end
local user = args[1]
if sec.userExists(user) then
    stderr:write('adduser: User already exists\r\n')
    return
end
local ip, cp
while true do
    io.writeln('Password for ' .. user .. ': ')
    ip = io.readln(false)

    io.writeln('Confirm: ')
    cp = io.readln(false)

    if ip ~= cp then
        io.writeln("Passwords didn't match, try again...")
    else break end
end
sec.addUser(user, ip)