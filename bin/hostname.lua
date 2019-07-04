local os = require('os')
local sh = require('sh')

local args = sh.getArgs()

if args[1] then
    os.setHostname(args[1])
else io.writeln(os.getHostname()) end