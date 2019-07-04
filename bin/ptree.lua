local proc = require('proc')

local tp = {}

io.writeln(string.format('% -6s % -24s', 'PID', ' Name'))
local inf = nil
local list = proc.list()

table.sort(list, function(a, b) return a < b end)

for k, v in pairs(list) do
    inf = proc.info(v)
    tp[v] = {id = v, data = inf, children = {}}

    if inf.parent ~= 0 then
        if tp[inf.parent] then
            table.add(tp[inf.parent].children, {v})
        else end -- to do
    end
end
local depth = 0
local function mapproc(pp)
    io.writeln(string.format(' % -6s % -24s', pp.id, string.rep(' ', depth) .. pp.data.name))

    depth = depth + 1
    for k, v in pairs(pp.children) do
        mapproc(tp[v])
    end
    depth = depth - 1
end
mapproc(tp[1])