local proc = require('proc')

io.writeln(string.format('% -6s % -12s % -24s', 'PID', 'User', 'Name'))
local inf = nil
local list = proc.list()

table.sort(list, function(a, b) return a < b end)

for k, v in pairs(list) do
    inf = proc.info(v)
    io.writeln(string.format('% -6i % -12s % -24s', v, inf.user, inf.name))
end
