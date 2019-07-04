local fs = require('fs')
local sh = require('sh')
local res = require('res')

local file = sh.getArgs()[1]
if not file then
    while true do
        io.write(io.read())
    end
else
    local s, r = fs.read(file)
    stderr:writeln(s and s or 'cat: ' .. file .. ': ' .. res.translate(r))
end