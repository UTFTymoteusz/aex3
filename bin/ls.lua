local sh   = require('sh')
local fs   = require('fs')
local ansi = require('ansi')

local list = fs.list(sh.getDir())
if #list == 0 then return end

table.sort(list, function(a, b) return a.name < b.name end)

if not io.isATTY(io.stdout) then
    local name
    for k, v in pairs(list) do
        name = v.name

        if v.type == 'dir' then
            name = name .. '/'
        end
        io.writeln(v.name)
    end
    return
end

local width, sy = sh.getTTYSize()
width = width - 1

-- yes, I copied the code from opencomputers. I'll look into my own implementation later on

local num_columns, items_per_column = 0, 0
local function real(x, y)
    local index = y + ((x - 1) * items_per_column)
    return index <= #list and index or nil
end
local function max_name(column_index)

    local max = 0
    for r = 1, items_per_column do

        local ri = real(column_index, r)
        if not ri then break end

        local info = list[ri]
        max = math.max(max, #info.name)
    end
    return max
end
local function measure()
    local total = 0

    for column_index = 1, num_columns do
        total = total + max_name(column_index) + (column_index > 1 and 2 or 0)
    end
    return total
end
while items_per_column < #list do

    items_per_column = items_per_column + 1
    num_columns = math.ceil(#list / items_per_column)

    if measure() < width then
        break end
end
-- copy end

local lines, so_far = {}, {}
local fattest = 0
local current = 0
local name, ext

local function cycle()
    local name, ext
    for k, v in pairs(so_far) do

        name = v.name
        ext  = fs.getExtension(name)

        if v.type == 'dir' then     name = ansi.colorFgRGB(0, 0, 255)   .. name .. ansi.resetg()
        elseif v.type == 'dev' then name = ansi.colorFgRGB(255, 255, 0) .. name .. ansi.resetg()
        elseif v.type == 'mnt' then name = ansi.colorBgRGB(0, 200, 0) .. ansi.colorFgRGB(0, 0, 255) .. name .. ansi.resetg()
        else
            if ext == 'lua' then
                name = ansi.colorFgRGB(0, 255, 0) .. name .. ansi.resetg() -- make it driven by permissions later (maybe)
            end
        end
        lines[k] = (lines[k] or '') .. name .. string.rep(' ', (fattest - #v.name) + 2)
    end

    fattest = 0
    so_far = {}
end

for k, v in pairs(list) do

    name = v.name
    ext  = fs.getExtension(name)
    current = current + 1

    if v.type == 'dir' then
        name = name
    end
    if current > items_per_column then
        cycle()
        current = 1
    end
    v.name = name
    so_far[#so_far + 1] = v

    if #name > fattest then fattest = #name end
end
cycle()

for k, v in pairs(lines) do
    io.writeln(v)
end