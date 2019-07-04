local sh = require('sh')
local fs = require('fs')

local list = fs.list(sh.getDir())
table.sort(list, function(a, b) return a.name < b.name end)

local name
for k, v in pairs(list) do
    io.writeln(v.name)
end