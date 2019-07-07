local sh = require('sh')

local args = sh.getArgs()

if not args[1] then
    stderr:writeln('drvmgr: Missing operand')
    return
end
local function toID(val)
    if tonumber(val) then
        return tonumber(val)
    else
        local drivers = sys.drvmgr_list()
        local info
        for _, id in pairs(drivers) do
            info = sys.drvmgr_info(id)
        end
        return nil
    end
end

local op = args[1]

if op == 'ls' or op == 'list' then
    local drivers = sys.drvmgr_list()
    local info
    for _, id in pairs(drivers) do
        info = sys.drvmgr_info(id)

        io.writeln(id, '. ###')
        io.writeln('Full name:      ', info.full_name)
        io.writeln('Name:           ', info.name)
        io.writeln('Type:           ', info.type)
        io.writeln('Provider:       ', info.provider)
        io.writeln('Version:        ', info.version)
        io.writeln('Enabled:        ', info.enabled and 'true' or 'false')
        io.writeln('Allows disable: ', info.disallow_disable and 'false' or 'true')
        if #info.owned_devices > 0 then
            io.writeln('Owned devices: ')

            for k, v in pairs(info.owned_devices) do
                io.writeln('  ', v)
            end
        end
        io.writeln()
    end
elseif op == 'd' or op == 'disable' then
    if not args[2] then
        stderr:writeln('drvmgr: Missing argument')
        return
    end
    local s, r = sys.drvmgr_disable(toID(args[2]))
    if not s then stderr:writeln('drvmgr: ' .. r) end
elseif op == 'e' or op == 'enable' then
    if not args[2] then
        stderr:writeln('drvmgr: Missing argument')
        return
    end
    local s, r = sys.drvmgr_enable(toID(args[2]))
    if not s then stderr:writeln('drvmgr: ' .. r) end
elseif op == 'l' or op == 'load' then
    if not args[2] then
        stderr:writeln('drvmgr: Missing argument')
        return
    end
    local s, r = sys.drvmgr_load(args[2])
    if not s then stderr:writeln('drvmgr: ' .. r) end
elseif op == 'u' or op == 'ul' or op == 'unload' then
    if not args[2] then
        stderr:writeln('drvmgr: Missing argument')
        return
    end
    local s, r = sys.drvmgr_unload(toID(args[2]))
    if not s then stderr:writeln('drvmgr: ' .. r) end
end