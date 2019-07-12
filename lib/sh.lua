--@EXT lib
local sh = {}
function sh.getProcessInfo(pid)
    local dat = sys.process_get_info(pid)
    return dat
end
function sh.getArgs()
    local dat = sh.getProcessInfo()
    return dat.args
end
function sh.getUser()
    local dat = sh.getProcessInfo()
    return dat.user
end
function sh.getDir()
    local dat = sh.getProcessInfo()
    return dat.dir
end
function sh.getTTY()
    return io.stdout.path
end
function sh.getTTYSize()
    local x, y = io.stdout:getSize()
    return x or 0, y or 0
end
function sh.parseArgs(args, skipEmpty)
    local tbl = {options = {}, args = {}}
    local i = 0
    local v, nv

    while (i < #args) do
        i = i + 1
        v = args[i]

        if (string.sub(v, 1, 2) == '--') then
            nv = args[i + 1]
            if nv then
                if (nv[1] == '-') then 
                    nv = ''
                else i = i + 1 end
            else nv = '' end

            tbl.options[v] = nv
        elseif (v[1] == '-') then
            for i = 2, #v do 
                tbl.options['-' .. v[i] ] = true 
            end
        elseif (#v ~= 0) then 
            table.add(tbl.args, {v}) 
        end
    end
    return tbl
end
return sh