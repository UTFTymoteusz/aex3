local fs = require('fs')
local sh = require('sh')
local res = require('res')

local function sorter(a, b) return a.name < b.name end
local function printSize(path)
    local list = fs.list(path)
    local size = 0

    table.sort(list, sorter)

    for k, v in pairs(list) do
        if v.type == 'file' then
            size = size + fs.size(path .. v.name)
        elseif v.type == 'dir' then
            size = size + printSize(path .. v.name)
        end
    end
    io.writeln(string.format('% -8i  %s', size, path))

    return size
end

local args = sh.getArgs()

if #args == 0 then
    args = {'./'}
end

for k, v in pairs(args) do
    if v[#v] ~= '/' then v = v .. '/' end

    printSize(v)
end