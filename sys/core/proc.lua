--@EXT km
local aex_int = sys.get_internal_table()
aex_int.proc = {}

local current_pid = 0
local new_pid     = 0

function sys.get_running_pid()
    return current_pid
end

local function coroutify(func, failcb, pid)
    return coroutine.create(function()
        local ret = {pcall(func)}
        if not ret[1] then
            if failcb then
                failcb(ret[2])
            end
            aex_int.syshook.invoke('process_end', pid, false, ret[2])
            return
        end
        aex_int.syshook.invoke('process_end', pid, true)
        table.remove(ret, 1)
        return ret
    end)
end

function sys.process_create(path, args, dir, sec_assoc)
    local c_pid = sys.get_running_pid()
    local pid = new_pid + 1

    local args = args or {}

    local env = aex_int.proc.get_safeguard_env()
    local fd, res = sys.fs_open(path, 'r')

    if not fd then return fd, res end

    local func, rr = loadstring(fd:read(), path)

    if not func then return nil, rr
    elseif type(func) == 'string' then return nil, tostring(func)
    else setfenv(func, env) end

    local stdin, stdout, stderr = io.getGenericStream(), io.getGenericStream(), io.getGenericStream()
    local p_s = string.split(path, '/')
        
    local cout = coroutify(func, function(err) stderr:write(tostring(err), '\r\n') end, pid)

    local user
    if c_pid == 0 then user = 'root'
    else user = aex_int.processes[c_pid].user end

    if sec_assoc then
        local success, new_user = sys.sec_assoc_verify_and_user(sec_assoc)
        if success then
            user = new_user
        else return nil, aex_int.result.access_denied_error end
    end
    local dir = dir
    if not dir then dir = table.concat(p_s, "/", 1, #p_s - 1) end
    if dir[#dir] ~= '/' then dir = dir .. '/' end

    new_pid = new_pid + 1
    local started = false
    return {
        stdin = stdin, stdout = stdout, stderr = stderr,
        pid = pid,
        start = function()
            if started then return end
            started = true
            
            aex_int.processes[pid] = {
                name   = p_s[#p_s],
                user   = user,
                args   = args,
                dir    = dir,
                parent = c_pid,
                threads = {cout},
                stdin  = stdin,
                stdout = stdout,
                stderr = stderr,
            }
        end,
        wait = function()
            while aex_int.processes[pid] do waitOne() end
            return true
        end,
        isAlive = function()
            return not not aex_int.processes[pid]
        end,
    }
end
function sys.process_replace(path, args, dir, sec_assoc)
    local c_pid = sys.get_running_pid()

    local args = args or {}

    local env = aex_int.proc.get_safeguard_env()
    local fd, res = sys.fs_open(path, 'r')

    if not fd then return fd, res end

    local func, rr = loadstring(fd:read(), path)

    if not func then return nil, rr
    elseif type(func) == 'string' then return nil, tostring(func)
    else setfenv(func, env) end

    local p_s = string.split(path, '/')
        
    local cout = coroutify(func, function(err) aex_int.processes[c_pid].stderr:write(tostring(err), '\r\n') end)

    local user
    if c_pid == 0 then  user = 'root'
    else user = aex_int.processes[c_pid].user end

    if sec_assoc then
        local success, new_user = sys.sec_assoc_verify_and_user(sec_assoc)
        if success then
            user = new_user
        else return error('sys.process_replace: Authentication failure', 2) end
    end
    local dir = dir
    if not dir then dir = table.concat(p_s, "/", 1, #p_s - 1) end
    if dir[#dir] ~= '/' then dir = dir .. '/' end

    local info = aex_int.processes[c_pid]
    info.name = p_s[#p_s]
    info.user = user
    info.args = args
    info.dir  = dir
    info.threads  = {cout}

    waitOne()
end
function sys.process_get_info(pid)
    if not pid then
        local c_pid = sys.get_running_pid()
        return table.copy(aex_int.processes[c_pid])
    else
        if not aex_int.processes[pid] then return nil end
        local dat = table.copy(aex_int.processes[pid])
        dat.threads = nil
        return dat
    end
end
function sys.process_list()
    return table.getKeys(aex_int.processes)
end

function sys.thread_create(func)
    local c_pid = sys.get_running_pid()

    if c_pid == 0 then
        aex_int.threads_k[#aex_int.threads_k + 1] = coroutify(func)
        return
    end
end

function aex_int.proc.begin_task_loop()
    local processes = aex_int.processes
    while true do
        current_pid = 0
        for k, v in pairs(aex_int.threads_k) do
    
            if coroutine.status(v) == 'dead' then 
                aex_int.threads_k[k] = nil
                goto xcontinue
            end
            coroutine.resume(v)
            ::xcontinue::
        end

        if #processes == 0 then return end

        for pid, process in pairs(processes) do
            current_pid = pid
            if #process.threads == 0 then 
                processes[pid] = nil
                goto xcontinue
            end

            for k, thread in pairs(process.threads) do
                if coroutine.status(thread) == 'dead' then 
                    process.threads[k] = nil
                    goto ycontinue
                end
                coroutine.resume(thread)
                ::ycontinue::
            end
            ::xcontinue::
        end
        waitOne()
    end
end
function aex_int.proc.get_safeguard_env()
    local env = {
        loadstring = function(...) 
            local code = loadstring(...)
            if type(code) == 'function' then
                setfenv(code, env)
            end
            return code
        end,
        print = print,
        stdin  = stdin,
        stdout = stdout,
        stderr = stderr,
        tostring = tostring,
        tonumber = tonumber,
        waitOne = waitOne,
        sleep   = sleep,
        isValid = isValid,
        require = require,
        getfenv = getfenv,
        setfenv = setfenv,
        rawget = rawget,
        rawset = rawset,
        assert = assert,
        ipairs = ipairs,
        fastlz = fastlz,
        string = string,
        xpcall = xpcall,
        pcall  = pcall,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        coroutine = coroutine,
        quotaUsed = quotaUsed,
        quotaAverage = quotaAverage,
        quotaTotalAverage = quotaTotalAverage,
        quotaTotalUsed = quotaTotalUsed,
        printTable = printTable,
        quotaMax = quotaMax,
        throw = throw,
        error = error,
        pairs = pairs,
        table = table,
        http = http,
        math = math,
        json = json,
        next = next,
        type = type,
        crc  = crc,
        bit  = bit,
        von  = von,
        sys  = sys,
        try  = try,
        io   = io ,
    }
    return table.copy(env)
end