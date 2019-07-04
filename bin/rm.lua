local fs = require('fs')
local sh = require('sh')

local args = sh.getArgs()
if #args == 0 then
    stderr:writeln('rm: No filename(s) specified')
    return
end

for k, v in pairs(args) do
    fs.delete(v)
end