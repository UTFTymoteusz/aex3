local fs = require('fs')
local sh = require('sh')
local res = require('res')

local file = sh.getArgs()[1]
if not file then
    stderr:writeln('mkdir: Missing argument')
else
    for k, v in pairs(sh.getArgs()) do
        fs.makedir(v)
    end
end