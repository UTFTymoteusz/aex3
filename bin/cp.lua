local sh = require('sh')
local fs = require('fs')
local res = require('res')

local p = sh.parseArgs(sh.getArgs())
local args = p.args
local options = p.options

if #args < 2 then
    stderr:writeln('cp: Missing operand' .. (#args == 0 and '(s)' or ''))
    return
end

local dst = args[#args]
local type

if #args > 2 and fs.type(dst) == 'file' then
    stderr:writeln('cp: Attempt to copy multiple files into a file')
    return
end
if not fs.exists(dst) then

    if dst[#dst] == '/' or #args > 2 then
        fs.makedir(dst)
    end
end

local _
local dst_type = 'file'

if fs.exists(dst) then
    dst_type = fs.type(dst)
    dst = dst .. ((dst[#dst] == '/' or dst_type == 'dir') and '' or '/')
end

local function copy(src, dst)
    local s, c, who = fs.copy(src, dst)

    if not s then stderr:writeln('cp: ' .. (who and src or dst) .. ': ' .. res.translate(c)) end
end
local function copy_recursive(src, dst)

    if fs.type(src) == 'dir' then

        if src[#src] ~= '/' then
            src = src .. '/'
        end
        fs.makedir(dst)

        for _, v in pairs(fs.list(src)) do
            _ = (v.type == 'dir' and copy_recursive(src .. v.name .. '/', dst .. v.name .. '/') or copy_recursive(src .. v.name, dst .. v.name))
        end
    else copy(src, dst) end
end

for k, src in pairs(args) do

    if k == #args then break end

    if not fs.exists(src) then
        stderr:writeln('cp: ' .. src .. ': No such file or directory')
        goto xcont
    end
    type = fs.type(src)

    if type == 'dir' and not options['-r'] then
        stderr:writeln("cp: -r not specified; omitting directory '" .. src .. "'")
    else

        if type == 'file' then
            _ = (dst_type == 'dir' and copy(src, dst .. fs.getFilename(src)) or copy(src, dst))
        elseif type == 'dir' then

            if dst_type ~= 'dir' then
                stderr:writeln('cp: ' .. src .. ': Attempt to copy a directory into a file')
                goto xcont
            end
            _ = (#args > 2 and copy_recursive(src, dst .. fs.getFilename(src)) or copy_recursive(src, dst))
        else
            stderr:writeln('cp: ' .. src .. ': Invalid file type') end
    end
    ::xcont::
end