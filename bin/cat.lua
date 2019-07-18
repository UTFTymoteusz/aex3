local fs = require('fs')
local sh = require('sh')
local res = require('res')

local file = sh.getArgs()[1]
if not file then
    while true do
        io.write(io.read())
    end
else
    local s, r = fs.open(file, 'r')
    if not s then
        stderr:writeln('cat: ' .. file .. ': ' .. res.translate(r))
        return
    end

    local a = ''
    while true do
        a = s:read()
        if #a == 0 then break end

        stdout:write(a)
        waitOne()
    end
end