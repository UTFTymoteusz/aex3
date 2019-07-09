local fs = require('fs')
local sh = require('sh')
local res = require('res')
local thread = require('thread')

local args = sh.getArgs()

if not args[1] then
    stderr:writeln('ster: No device/file specified')
    return
end

local fd, r = fs.open(args[1])
if not fd then
    stderr:writeln('ster: ' .. args[1] .. ': ' .. res.translate(r))
    return
end

io.stdin:bind(fd)

thread.create(function()
    while true do
        io.write(io.read())
    end
end)

while true do
    waitOne()
end