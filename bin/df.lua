local fs = require('fs')

local column_len = {}
local columns = {}

local function set(x, y, str)
    if not column_len[x] then column_len[x], columns[x] = 0, {} end
    if #str + 2 > column_len[x] then column_len[x] = #str + 2 end

    columns[x][y] = str
end

set(1, 1, 'Filesystem')
set(2, 1, 'Mounted on')

local i = 1
local lines = {}

for k, v in pairs(fs.getMounts()) do
    i = i + 1
    set(1, i, k)
    set(2, i, v.path)
end
for k, v in pairs(columns) do
    
    for c, w in pairs(v) do
        if not lines[c] then lines[c] = '' end
        lines[c] = lines[c] .. string.format('% -' .. column_len[k] .. 's', w)
    end
end
for k, v in pairs(lines) do io.writeln(v) end