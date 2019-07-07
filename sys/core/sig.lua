--@EXT km
local aex_int = sys.get_internal_table()

local sig = {}
aex_int.sig = sig

function sys.sig_register_handler(name, callback)
    aex_int.assertType(name, 'string')
    aex_int.assertType(callback, 'function')

    local pid = sys.get_running_pid()

    aex_int.processes[pid].signal_handlers[name] = callback
end
function aex_int.run_signal(pid, name, ...)
    aex_int.assertType(pid, 'number')
    aex_int.assertType(name, 'string')

    local process = aex_int.processes[pid]

    if not process.signal_handlers[name] then return false end

    return process.signal_handlers[name](...)
end