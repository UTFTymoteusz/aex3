local fs = require('fs')
local sh = require('sh')
local res = require('res')

local args = sh.getArgs()

if #args ~= 1 then
    stderr:writeln('unmount: Invalid amount of arguments')
    return
end

local s, code = fs.unmount(args[1])
if not s then
    stderr:writeln('unmount: ' .. res.translate(code))
end