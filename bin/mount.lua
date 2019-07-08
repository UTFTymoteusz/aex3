local fs = require('fs')
local sh = require('sh')
local res = require('res')

local args = sh.getArgs()

if #args ~= 2 then
    stderr:writeln('mount: Invalid amount of arguments')
    return
end

local s, code = fs.mount(args[1], args[2])
if not s then
    stderr:writeln('mount: ' .. res.translate(code))
end