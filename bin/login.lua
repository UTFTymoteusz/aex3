local ansi = require('ansi')
local os   = require('os')
local fs   = require('fs')
local proc = require('proc')
local sec  = require('sec')
io.write(ansi.clear())

local user, pass, assoc
while true do
    io.write(os.getHostname(), ' login: ')
    user = io.readln(true)
    io.writeln()
    io.write('Password: ')
    pass = io.readln()
    io.writeln()
    io.writeln()

    assoc = sec.getNewAssoc(user, pass)
    if sec.verifyAssoc(assoc) then break end

    io.writeln('Login incorrect')
end
if fs.exists('/cfg/motd') then
    io.writeln(fs.read('/cfg/motd'))
end
proc.replace('/bin/sh.lua', nil, nil, assoc)